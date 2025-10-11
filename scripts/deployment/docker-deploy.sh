#!/bin/bash

#==============================================================================
# 脚本名称: docker-deploy.sh
# 脚本描述: Docker容器化部署脚本，支持生产环境快速部署
# 作者: Guessing Pen Team
# 创建日期: 2025-10-11
# 版本: 2.0.0
#==============================================================================

set -euo pipefail

# 脚本配置
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly LOG_FILE="${PROJECT_ROOT}/logs/docker-deploy-$(date +%Y%m%d-%H%M%S).log"

# 颜色定义
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# 默认配置
readonly DEFAULT_COMPOSE_FILE="docker-compose.prod.yml"
readonly DEFAULT_ENV_FILE=".env.docker"

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
    exit 1
}

#==============================================================================
# 工具函数
#==============================================================================

check_command() {
    local cmd="$1"
    if ! command -v "${cmd}" &> /dev/null; then
        log_error "命令 '${cmd}' 未找到，请先安装"
    fi
}

check_file() {
    local file="$1"
    if [[ ! -f "${file}" ]]; then
        log_error "文件 '${file}' 不存在"
    fi
}

confirm_action() {
    local message="$1"
    echo -e "${YELLOW}${message}${NC}"
    read -p "是否继续? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "操作已取消"
        exit 0
    fi
}

#==============================================================================
# 部署函数
#==============================================================================

# 环境检查
check_environment() {
    log_info "检查部署环境..."
    
    # 检查必需的命令
    check_command "docker"
    check_command "docker-compose"
    check_command "curl"
    
    # 检查Docker服务
    if ! docker info &> /dev/null; then
        log_error "Docker服务未运行，请启动Docker"
    fi
    
    # 检查必需的文件
    check_file "${PROJECT_ROOT}/${COMPOSE_FILE}"
    check_file "${PROJECT_ROOT}/Dockerfile"
    check_file "${PROJECT_ROOT}/Dockerfile.api"
    
    log_success "环境检查完成"
}

# 环境变量检查
check_env_vars() {
    log_info "检查环境变量配置..."
    
    # 优先使用指定的环境文件
    local env_file="${ENV_FILE:-${DEFAULT_ENV_FILE}}"
    
    if [[ -f "${PROJECT_ROOT}/${env_file}" ]]; then
        log_info "使用环境文件: ${env_file}"
        export $(grep -v '^#' "${PROJECT_ROOT}/${env_file}" | xargs)
    elif [[ -f "${PROJECT_ROOT}/.env" ]]; then
        log_info "使用环境文件: .env"
        export $(grep -v '^#' "${PROJECT_ROOT}/.env" | xargs)
    else
        log_warning "未找到环境文件，使用默认配置"
    fi
    
    # 检查必要的环境变量
    local required_vars=("DB_HOST" "DB_USER" "DB_PASSWORD" "DB_NAME")
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            missing_vars+=("$var")
        fi
    done
    
    if [[ ${#missing_vars[@]} -ne 0 ]]; then
        log_error "缺少必要的环境变量: ${missing_vars[*]}"
    fi
    
    # 设置构建变量
    export BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
    export VERSION="${VERSION:-$(date +%Y%m%d-%H%M%S)}"
    
    log_success "环境变量检查通过"
    log_info "构建版本: ${VERSION}"
}

# 停止旧服务
stop_old_services() {
    log_info "停止旧服务..."
    
    cd "${PROJECT_ROOT}"
    
    # 停止并删除旧容器
    docker-compose -f "${COMPOSE_FILE}" down --remove-orphans 2>/dev/null || true
    
    # 清理未使用的网络
    docker network prune -f &>/dev/null || true
    
    log_success "旧服务已停止"
}

# 构建镜像
build_images() {
    log_info "构建Docker镜像..."
    
    cd "${PROJECT_ROOT}"
    
    # 构建镜像（无缓存）
    docker-compose -f "${COMPOSE_FILE}" build --no-cache --parallel
    
    log_success "镜像构建完成"
}

# 启动服务
start_services() {
    log_info "启动Docker服务..."
    
    cd "${PROJECT_ROOT}"
    
    # 启动服务
    docker-compose -f "${COMPOSE_FILE}" up -d
    
    log_success "服务启动成功"
}

# 等待服务就绪
wait_for_services() {
    log_info "等待服务启动..."
    
    local max_wait=60
    local wait_time=0
    local interval=5
    
    while [[ $wait_time -lt $max_wait ]]; do
        if check_service_health; then
            log_success "所有服务已就绪"
            return 0
        fi
        
        sleep $interval
        wait_time=$((wait_time + interval))
        log_info "等待中... (${wait_time}/${max_wait}秒)"
    done
    
    log_warning "服务启动超时，但继续执行健康检查"
}

# 检查服务健康状态
check_service_health() {
    local all_healthy=true
    
    # 检查前端服务
    if curl -f -s --max-time 5 "http://localhost:${FRONTEND_PORT:-80}/health" > /dev/null 2>&1; then
        log_success "前端服务: 健康"
    else
        all_healthy=false
    fi
    
    # 检查API服务
    if curl -f -s --max-time 5 "http://localhost:${API_PORT:-3005}/api/health" > /dev/null 2>&1; then
        log_success "API服务: 健康"
    else
        all_healthy=false
    fi
    
    # 检查PostgREST服务（如果启用）
    if [[ "${ENABLE_POSTGREST:-false}" == "true" ]]; then
        if curl -f -s --max-time 5 "http://localhost:${POSTGREST_PORT:-3001}/" > /dev/null 2>&1; then
            log_success "PostgREST服务: 健康"
        else
            all_healthy=false
        fi
    fi
    
    return $([ "$all_healthy" = true ])
}

# 显示部署信息
show_deployment_info() {
    log_success "Docker部署完成！"
    echo
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎉 部署信息"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
    echo "🌐 访问地址:"
    echo "  - 前端应用: http://localhost:${FRONTEND_PORT:-80}"
    echo "  - API服务:  http://localhost:${API_PORT:-3005}"
    if [[ "${ENABLE_POSTGREST:-false}" == "true" ]]; then
        echo "  - PostgREST: http://localhost:${POSTGREST_PORT:-3001}"
    fi
    echo
    echo "🔍 健康检查:"
    echo "  - 前端: http://localhost:${FRONTEND_PORT:-80}/health"
    echo "  - API:  http://localhost:${API_PORT:-3005}/api/health"
    echo
    echo "📊 容器状态:"
    docker-compose -f "${COMPOSE_FILE}" ps
    echo
    echo "📝 常用命令:"
    echo "  查看日志: docker-compose -f ${COMPOSE_FILE} logs -f"
    echo "  停止服务: docker-compose -f ${COMPOSE_FILE} down"
    echo "  重启服务: docker-compose -f ${COMPOSE_FILE} restart"
    echo "  健康检查: bash scripts/deployment/docker-health-check.sh"
    echo
    echo "📋 日志文件: ${LOG_FILE}"
}

#==============================================================================
# 错误处理
#==============================================================================

cleanup() {
    log_info "执行清理操作..."
    # 在这里添加清理逻辑
}

error_handler() {
    local line_number="$1"
    log_error "脚本在第 ${line_number} 行发生错误"
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
    log_info "开始Docker容器化部署..."
    
    # 创建日志目录
    mkdir -p "$(dirname "${LOG_FILE}")"
    
    # 执行部署步骤
    check_environment
    check_env_vars
    
    # 确认部署
    if [[ "${SKIP_CONFIRMATION:-false}" != "true" ]]; then
        confirm_action "即将部署Docker容器，版本: ${VERSION}"
    fi
    
    stop_old_services
    build_images
    start_services
    wait_for_services
    show_deployment_info
    
    log_success "Docker部署脚本执行完成！"
}

# 帮助信息
show_help() {
    cat << EOF
用法: $0 [选项]

选项:
    -h, --help                  显示此帮助信息
    -f, --file FILE            指定Docker Compose文件 (默认: ${DEFAULT_COMPOSE_FILE})
    -e, --env-file FILE        指定环境变量文件 (默认: ${DEFAULT_ENV_FILE})
    -v, --version VERSION      指定部署版本标签
    -y, --yes                  跳过确认提示
    --enable-postgrest         启用PostgREST服务
    --verbose                  详细输出模式

环境变量:
    COMPOSE_FILE              Docker Compose文件路径
    ENV_FILE                  环境变量文件路径
    VERSION                   部署版本标签
    SKIP_CONFIRMATION         跳过确认提示 (true/false)
    ENABLE_POSTGREST          启用PostgREST服务 (true/false)

示例:
    $0                                    # 基本部署
    $0 --version v1.0.0 --yes            # 指定版本并跳过确认
    $0 --file docker-compose.yml         # 使用开发环境配置
    $0 --enable-postgrest                # 启用PostgREST服务

EOF
}

# 参数解析
COMPOSE_FILE="${DEFAULT_COMPOSE_FILE}"
ENV_FILE="${DEFAULT_ENV_FILE}"

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -f|--file)
            COMPOSE_FILE="$2"
            shift 2
            ;;
        -e|--env-file)
            ENV_FILE="$2"
            shift 2
            ;;
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        -y|--yes)
            SKIP_CONFIRMATION=true
            shift
            ;;
        --enable-postgrest)
            ENABLE_POSTGREST=true
            shift
            ;;
        --verbose)
            set -x
            shift
            ;;
        *)
            log_error "未知参数: $1"
            ;;
    esac
done

# 执行主函数
main "$@"
