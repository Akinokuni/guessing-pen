#!/bin/bash

#==============================================================================
# 脚本名称: server-deploy.sh
# 脚本描述: 云服务器自动化部署脚本
# 作者: Guessing Pen Team
# 创建日期: 2025-10-11
# 版本: 1.0.0
#==============================================================================

set -euo pipefail

# 脚本配置
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly LOG_DIR="${PROJECT_ROOT}/logs"
readonly LOG_FILE="${LOG_DIR}/deploy-$(date +%Y%m%d-%H%M%S).log"

# 颜色定义
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# 部署配置
readonly ACR_REGISTRY="${ACR_REGISTRY:-registry.cn-hangzhou.aliyuncs.com}"
readonly ACR_NAMESPACE="${ACR_NAMESPACE:-guessing-pen}"
readonly IMAGE_TAG="${IMAGE_TAG:-latest}"
readonly COMPOSE_FILE="${PROJECT_ROOT}/docker-compose.prod.yml"
readonly BACKUP_DIR="${PROJECT_ROOT}/backups"
readonly MAX_ROLLBACK_VERSIONS=5

# 超时配置
readonly DEPLOY_TIMEOUT=600  # 10分钟
readonly HEALTH_CHECK_TIMEOUT=300  # 5分钟
readonly CONTAINER_START_TIMEOUT=60  # 1分钟

#==============================================================================
# 日志和输出函数
#==============================================================================

log_info() {
    local message="$1"
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - ${message}" | tee -a "${LOG_FILE}"
}

log_success() {
    local message="$1"
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - ${message}" | tee -a "${LOG_FILE}"
}

log_warning() {
    local message="$1"
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - ${message}" | tee -a "${LOG_FILE}"
}

log_error() {
    local message="$1"
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - ${message}" | tee -a "${LOG_FILE}"
}

#==============================================================================
# 工具函数
#==============================================================================

# 检查命令是否存在
check_command() {
    local cmd="$1"
    if ! command -v "${cmd}" &> /dev/null; then
        log_error "命令 '${cmd}' 未找到，请先安装"
        exit 1
    fi
}

# 检查文件是否存在
check_file() {
    local file="$1"
    if [[ ! -f "${file}" ]]; then
        log_error "文件 '${file}' 不存在"
        exit 1
    fi
}

# 检查环境变量
check_env_var() {
    local var_name="$1"
    local var_value="${!var_name:-}"
    
    if [[ -z "${var_value}" ]]; then
        log_error "环境变量 '${var_name}' 未设置"
        exit 1
    fi
}

# 等待容器启动
wait_for_container() {
    local container_name="$1"
    local timeout="${2:-$CONTAINER_START_TIMEOUT}"
    local elapsed=0
    
    log_info "等待容器 ${container_name} 启动..."
    
    while [[ $elapsed -lt $timeout ]]; do
        if docker ps --format "{{.Names}}" | grep -q "^${container_name}$"; then
            if docker ps --format "table {{.Names}}\t{{.Status}}" | grep "${container_name}" | grep -q "Up"; then
                log_success "容器 ${container_name} 启动成功"
                return 0
            fi
        fi
        
        sleep 5
        elapsed=$((elapsed + 5))
        
        if [[ $((elapsed % 15)) -eq 0 ]]; then
            log_info "等待容器启动中... (${elapsed}/${timeout}秒)"
        fi
    done
    
    log_error "容器 ${container_name} 启动超时"
    return 1
}

# 创建备份
create_backup() {
    local backup_name="backup-$(date +%Y%m%d-%H%M%S)"
    local backup_path="${BACKUP_DIR}/${backup_name}"
    
    log_info "创建部署备份..."
    
    mkdir -p "${backup_path}"
    
    # 备份当前运行的镜像信息
    if docker-compose -f "${COMPOSE_FILE}" ps -q > /dev/null 2>&1; then
        docker-compose -f "${COMPOSE_FILE}" config > "${backup_path}/docker-compose.yml"
        docker images --format "table {{.Repository}}:{{.Tag}}\t{{.ID}}\t{{.CreatedAt}}" | grep guessing-pen > "${backup_path}/images.txt" || true
        
        # 备份环境变量
        env | grep -E "(DB_|ACR_|NODE_ENV)" > "${backup_path}/env.txt" || true
        
        log_success "备份创建完成: ${backup_path}"
        echo "${backup_name}" > "${BACKUP_DIR}/latest"
    else
        log_warning "没有运行中的服务，跳过备份"
    fi
    
    # 清理旧备份
    cleanup_old_backups
}

# 清理旧备份
cleanup_old_backups() {
    local backup_count
    backup_count=$(find "${BACKUP_DIR}" -maxdepth 1 -type d -name "backup-*" | wc -l)
    
    if [[ $backup_count -gt $MAX_ROLLBACK_VERSIONS ]]; then
        log_info "清理旧备份..."
        find "${BACKUP_DIR}" -maxdepth 1 -type d -name "backup-*" -printf '%T@ %p\n' | \
            sort -n | head -n -${MAX_ROLLBACK_VERSIONS} | cut -d' ' -f2- | \
            xargs rm -rf
        log_success "旧备份清理完成"
    fi
}

#==============================================================================
# 部署前检查
#==============================================================================

check_prerequisites() {
    log_info "检查部署前置条件..."
    
    # 检查必需的命令
    check_command "docker"
    check_command "docker-compose"
    check_command "curl"
    
    # 检查必需的文件
    check_file "${COMPOSE_FILE}"
    
    # 检查必需的环境变量
    check_env_var "ACR_USERNAME"
    check_env_var "ACR_PASSWORD"
    check_env_var "DB_HOST"
    check_env_var "DB_USER"
    check_env_var "DB_PASSWORD"
    check_env_var "DB_NAME"
    
    # 检查Docker服务状态
    if ! docker info > /dev/null 2>&1; then
        log_error "Docker服务未运行"
        exit 1
    fi
    
    # 检查磁盘空间
    local available_space
    available_space=$(df "${PROJECT_ROOT}" | awk 'NR==2 {print $4}')
    if [[ $available_space -lt 1048576 ]]; then  # 1GB
        log_warning "可用磁盘空间不足1GB，可能影响部署"
    fi
    
    log_success "前置条件检查完成"
}

check_network_connectivity() {
    log_info "检查网络连接..."
    
    # 检查ACR连接
    if ! curl -f -s --max-time 10 "https://${ACR_REGISTRY}" > /dev/null; then
        log_error "无法连接到阿里云ACR: ${ACR_REGISTRY}"
        exit 1
    fi
    
    # 检查数据库连接
    if ! timeout 10 bash -c "</dev/tcp/${DB_HOST}/${DB_PORT:-5432}" 2>/dev/null; then
        log_error "无法连接到数据库: ${DB_HOST}:${DB_PORT:-5432}"
        exit 1
    fi
    
    log_success "网络连接检查完成"
}

#==============================================================================
# 镜像管理
#==============================================================================

login_acr() {
    log_info "登录阿里云容器镜像服务..."
    
    if echo "${ACR_PASSWORD}" | docker login "${ACR_REGISTRY}" -u "${ACR_USERNAME}" --password-stdin; then
        log_success "ACR登录成功"
    else
        log_error "ACR登录失败"
        exit 1
    fi
}

pull_images() {
    log_info "拉取Docker镜像..."
    
    local images=(
        "${ACR_REGISTRY}/${ACR_NAMESPACE}/guessing-pen-frontend:${IMAGE_TAG}"
        "${ACR_REGISTRY}/${ACR_NAMESPACE}/guessing-pen-api:${IMAGE_TAG}"
    )
    
    for image in "${images[@]}"; do
        log_info "拉取镜像: ${image}"
        
        if docker pull "${image}"; then
            log_success "镜像拉取成功: ${image}"
        else
            log_error "镜像拉取失败: ${image}"
            exit 1
        fi
    done
    
    log_success "所有镜像拉取完成"
}

#==============================================================================
# 服务管理
#==============================================================================

stop_services() {
    log_info "停止现有服务..."
    
    if docker-compose -f "${COMPOSE_FILE}" ps -q > /dev/null 2>&1; then
        # 优雅停止服务
        if docker-compose -f "${COMPOSE_FILE}" stop --timeout 30; then
            log_success "服务停止成功"
        else
            log_warning "服务停止超时，强制停止"
            docker-compose -f "${COMPOSE_FILE}" kill
        fi
        
        # 移除容器
        docker-compose -f "${COMPOSE_FILE}" rm -f
    else
        log_info "没有运行中的服务"
    fi
}

start_services() {
    log_info "启动新服务..."
    
    # 设置环境变量
    export IMAGE_TAG
    export ACR_REGISTRY
    export ACR_NAMESPACE
    
    # 启动服务
    if docker-compose -f "${COMPOSE_FILE}" up -d; then
        log_success "服务启动命令执行成功"
    else
        log_error "服务启动失败"
        return 1
    fi
    
    # 等待容器启动
    local containers=("guessing-pen-frontend" "guessing-pen-api")
    for container in "${containers[@]}"; do
        wait_for_container "${container}" || return 1
    done
    
    log_success "所有服务启动完成"
}

#==============================================================================
# 健康检查
#==============================================================================

run_health_checks() {
    log_info "执行健康检查..."
    
    local health_script="${SCRIPT_DIR}/docker-health-check.sh"
    
    if [[ -f "${health_script}" ]]; then
        if timeout "${HEALTH_CHECK_TIMEOUT}" "${health_script}"; then
            log_success "健康检查通过"
            return 0
        else
            log_error "健康检查失败"
            return 1
        fi
    else
        log_warning "健康检查脚本不存在，跳过检查"
        return 0
    fi
}

#==============================================================================
# 回滚机制
#==============================================================================

rollback_deployment() {
    log_error "部署失败，开始回滚..."
    
    local rollback_script="${SCRIPT_DIR}/rollback.sh"
    
    if [[ -f "${rollback_script}" ]]; then
        if "${rollback_script}"; then
            log_success "回滚完成"
        else
            log_error "回滚失败"
        fi
    else
        log_error "回滚脚本不存在"
    fi
}

#==============================================================================
# 部署通知
#==============================================================================

send_notification() {
    local status="$1"
    local message="$2"
    
    # 这里可以集成钉钉、企业微信等通知服务
    log_info "发送部署通知: ${status} - ${message}"
    
    # 示例：写入通知日志
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ${status}: ${message}" >> "${LOG_DIR}/notifications.log"
}

#==============================================================================
# 主要部署流程
#==============================================================================

deploy() {
    local start_time
    start_time=$(date +%s)
    
    log_info "开始部署流程..."
    
    # 创建日志目录
    mkdir -p "${LOG_DIR}" "${BACKUP_DIR}"
    
    # 部署前检查
    check_prerequisites
    check_network_connectivity
    
    # 创建备份
    create_backup
    
    # 登录ACR并拉取镜像
    login_acr
    pull_images
    
    # 停止现有服务
    stop_services
    
    # 启动新服务
    if ! start_services; then
        rollback_deployment
        send_notification "FAILED" "服务启动失败，已回滚"
        exit 1
    fi
    
    # 健康检查
    if ! run_health_checks; then
        rollback_deployment
        send_notification "FAILED" "健康检查失败，已回滚"
        exit 1
    fi
    
    # 计算部署时间
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log_success "部署完成！耗时: ${duration}秒"
    send_notification "SUCCESS" "部署成功，耗时${duration}秒"
    
    # 显示服务状态
    show_service_status
}

show_service_status() {
    echo
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🚀 部署完成 - 服务状态"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # 显示容器状态
    docker-compose -f "${COMPOSE_FILE}" ps
    
    echo
    echo "📊 服务访问地址:"
    echo "  前端应用: http://localhost"
    echo "  API服务:  http://localhost:3005"
    echo "  健康检查: http://localhost/health"
    
    echo
    echo "📝 日志文件: ${LOG_FILE}"
    echo "💾 备份目录: ${BACKUP_DIR}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

#==============================================================================
# 错误处理
#==============================================================================

cleanup() {
    log_info "执行清理操作..."
    
    # 清理临时文件
    rm -f /tmp/deploy-*.tmp
    
    # 登出ACR
    docker logout "${ACR_REGISTRY}" 2>/dev/null || true
}

error_handler() {
    local line_number="$1"
    log_error "脚本在第 ${line_number} 行发生错误"
    
    send_notification "ERROR" "部署脚本执行错误，行号: ${line_number}"
    
    cleanup
    exit 1
}

# 设置错误处理
trap 'error_handler ${LINENO}' ERR
trap cleanup EXIT

#==============================================================================
# 主函数
#==============================================================================

main() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🚀 旮旯画师 - 云服务器自动化部署"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📅 部署时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "🏷️  镜像标签: ${IMAGE_TAG}"
    echo "🌐 ACR仓库: ${ACR_REGISTRY}/${ACR_NAMESPACE}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
    
    # 执行部署
    deploy
}

# 帮助信息
show_help() {
    cat << EOF
用法: $0 [选项]

选项:
    -h, --help          显示此帮助信息
    -t, --tag TAG       指定镜像标签 (默认: latest)
    -v, --verbose       详细输出模式
    --dry-run          试运行模式（不执行实际操作）
    --skip-backup      跳过备份创建
    --skip-health      跳过健康检查

环境变量:
    ACR_USERNAME       阿里云ACR用户名
    ACR_PASSWORD       阿里云ACR密码
    ACR_REGISTRY       ACR注册表地址
    ACR_NAMESPACE      ACR命名空间
    DB_HOST           数据库主机
    DB_USER           数据库用户名
    DB_PASSWORD       数据库密码
    DB_NAME           数据库名称

示例:
    $0                          # 使用默认配置部署
    $0 --tag v1.2.0            # 部署指定版本
    $0 --verbose               # 详细输出模式
    $0 --dry-run               # 试运行模式

EOF
}

# 参数解析
SKIP_BACKUP=false
SKIP_HEALTH=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -t|--tag)
            if [[ -n "${2:-}" ]]; then
                IMAGE_TAG="$2"
                shift 2
            else
                log_error "--tag 选项需要一个值"
                exit 1
            fi
            ;;
        -v|--verbose)
            set -x
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            log_info "试运行模式启用"
            shift
            ;;
        --skip-backup)
            SKIP_BACKUP=true
            shift
            ;;
        --skip-health)
            SKIP_HEALTH=true
            shift
            ;;
        *)
            log_error "未知参数: $1"
            show_help
            exit 1
            ;;
    esac
done

# 试运行模式
if [[ "$DRY_RUN" == "true" ]]; then
    log_info "试运行模式 - 仅显示将要执行的操作"
    echo "将要执行的操作:"
    echo "1. 检查前置条件"
    echo "2. 检查网络连接"
    echo "3. 创建备份 (跳过: $SKIP_BACKUP)"
    echo "4. 登录ACR"
    echo "5. 拉取镜像: ${IMAGE_TAG}"
    echo "6. 停止现有服务"
    echo "7. 启动新服务"
    echo "8. 执行健康检查 (跳过: $SKIP_HEALTH)"
    exit 0
fi

# 执行主函数
main "$@"