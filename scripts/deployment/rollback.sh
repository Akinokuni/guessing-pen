#!/bin/bash

#==============================================================================
# 脚本名称: rollback.sh
# 脚本描述: 自动回滚到上一个稳定版本
# 作者: Kiro AI Assistant
# 创建日期: 2025-10-11
# 版本: 1.0.0
#==============================================================================

# 设置严格模式
set -euo pipefail

# 脚本配置
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly LOG_FILE="${PROJECT_ROOT}/logs/rollback-$(date +%Y%m%d-%H%M%S).log"

# 颜色定义
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# 配置变量
ROLLBACK_TARGET=""
DRY_RUN=false
FORCE_ROLLBACK=false

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

# 检查命令是否存在
check_command() {
    local cmd="$1"
    if ! command -v "${cmd}" &> /dev/null; then
        log_error "命令 '${cmd}' 未找到，请先安装"
    fi
}

# 确认操作
confirm_action() {
    local message="$1"
    if [[ "${FORCE_ROLLBACK}" == "true" ]]; then
        log_info "强制模式：跳过确认"
        return 0
    fi
    
    echo -e "${YELLOW}${message}${NC}"
    read -p "是否继续? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "回滚操作已取消"
        exit 0
    fi
}

# 获取当前运行的容器版本
get_current_version() {
    local current_version
    current_version=$(docker ps --format "table {{.Image}}" | grep -E "(frontend|api)" | head -1 | cut -d':' -f2 || echo "unknown")
    echo "${current_version}"
}

# 获取可用的版本列表
get_available_versions() {
    log_info "获取可用的镜像版本..."
    
    # 从本地Docker镜像获取版本
    local versions
    versions=$(docker images --format "table {{.Tag}}" | grep -v "TAG\|latest\|<none>" | sort -V -r | head -10)
    
    if [[ -z "${versions}" ]]; then
        log_warning "未找到可用的历史版本"
        return 1
    fi
    
    echo "${versions}"
}

# 选择回滚目标版本
select_rollback_target() {
    if [[ -n "${ROLLBACK_TARGET}" ]]; then
        log_info "使用指定的回滚目标: ${ROLLBACK_TARGET}"
        return 0
    fi
    
    local current_version
    current_version=$(get_current_version)
    log_info "当前版本: ${current_version}"
    
    local versions
    versions=$(get_available_versions)
    
    echo -e "${BLUE}可用的版本:${NC}"
    echo "${versions}" | nl -w2 -s') '
    
    echo
    read -p "请选择要回滚到的版本 (输入序号或版本号): " selection
    
    if [[ "${selection}" =~ ^[0-9]+$ ]]; then
        # 用户输入了序号
        ROLLBACK_TARGET=$(echo "${versions}" | sed -n "${selection}p")
    else
        # 用户输入了版本号
        ROLLBACK_TARGET="${selection}"
    fi
    
    if [[ -z "${ROLLBACK_TARGET}" ]]; then
        log_error "无效的选择"
    fi
    
    log_info "选择的回滚目标: ${ROLLBACK_TARGET}"
}

#==============================================================================
# 回滚功能函数
#==============================================================================

# 验证回滚目标版本
validate_rollback_target() {
    log_info "验证回滚目标版本: ${ROLLBACK_TARGET}"
    
    # 检查镜像是否存在
    if ! docker images --format "table {{.Tag}}" | grep -q "^${ROLLBACK_TARGET}$"; then
        log_error "目标版本 '${ROLLBACK_TARGET}' 的镜像不存在"
    fi
    
    log_success "回滚目标版本验证通过"
}

# 备份当前状态
backup_current_state() {
    log_info "备份当前部署状态..."
    
    local backup_dir="${PROJECT_ROOT}/backups/rollback-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "${backup_dir}"
    
    # 备份当前的docker-compose配置
    if [[ -f "${PROJECT_ROOT}/docker-compose.yml" ]]; then
        cp "${PROJECT_ROOT}/docker-compose.yml" "${backup_dir}/"
    fi
    
    # 备份当前运行的容器信息
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" > "${backup_dir}/running-containers.txt"
    
    # 备份环境变量
    if [[ -f "${PROJECT_ROOT}/.env.production" ]]; then
        cp "${PROJECT_ROOT}/.env.production" "${backup_dir}/"
    fi
    
    log_success "当前状态已备份到: ${backup_dir}"
    echo "${backup_dir}" > "${PROJECT_ROOT}/.last-backup"
}

# 停止当前服务
stop_current_services() {
    log_info "停止当前运行的服务..."
    
    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[DRY RUN] 将执行: docker-compose down"
        return 0
    fi
    
    cd "${PROJECT_ROOT}"
    
    # 优雅停止服务
    if docker-compose ps -q | grep -q .; then
        docker-compose down --timeout 30
        log_success "服务已停止"
    else
        log_info "没有运行中的服务"
    fi
}

# 更新镜像标签
update_image_tags() {
    log_info "更新镜像标签到版本: ${ROLLBACK_TARGET}"
    
    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[DRY RUN] 将更新镜像标签到: ${ROLLBACK_TARGET}"
        return 0
    fi
    
    # 更新环境变量中的镜像版本
    local env_file="${PROJECT_ROOT}/.env.production"
    if [[ -f "${env_file}" ]]; then
        sed -i.bak "s/IMAGE_TAG=.*/IMAGE_TAG=${ROLLBACK_TARGET}/" "${env_file}"
        log_success "已更新环境变量中的镜像版本"
    fi
}

# 启动回滚版本
start_rollback_services() {
    log_info "启动回滚版本的服务..."
    
    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[DRY RUN] 将执行: docker-compose up -d"
        return 0
    fi
    
    cd "${PROJECT_ROOT}"
    
    # 设置镜像版本环境变量
    export IMAGE_TAG="${ROLLBACK_TARGET}"
    
    # 启动服务
    docker-compose up -d
    
    log_success "回滚版本服务已启动"
}

# 验证回滚结果
verify_rollback() {
    log_info "验证回滚结果..."
    
    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[DRY RUN] 将执行健康检查"
        return 0
    fi
    
    # 等待服务启动
    log_info "等待服务启动..."
    sleep 10
    
    # 执行健康检查
    if [[ -f "${SCRIPT_DIR}/health-monitor.sh" ]]; then
        if bash "${SCRIPT_DIR}/health-monitor.sh" --timeout 60; then
            log_success "回滚验证成功"
            return 0
        else
            log_error "回滚验证失败"
            return 1
        fi
    else
        log_warning "健康检查脚本不存在，跳过验证"
    fi
}

# 发送回滚通知
send_rollback_notification() {
    local status="$1"
    local current_version="$2"
    
    log_info "发送回滚通知..."
    
    local message
    if [[ "${status}" == "success" ]]; then
        message="🔄 回滚成功: ${current_version} → ${ROLLBACK_TARGET}"
    else
        message="❌ 回滚失败: ${current_version} → ${ROLLBACK_TARGET}"
    fi
    
    # 调用通知系统
    if [[ -f "${SCRIPT_DIR}/notification-system.sh" ]]; then
        bash "${SCRIPT_DIR}/notification-system.sh" \
            --type "rollback" \
            --status "${status}" \
            --message "${message}" \
            --version "${ROLLBACK_TARGET}"
    fi
}

#==============================================================================
# 错误处理和清理
#==============================================================================

cleanup() {
    log_info "执行清理操作..."
    # 清理临时文件等
}

error_handler() {
    local line_number="$1"
    log_error "回滚脚本在第 ${line_number} 行发生错误"
    
    # 尝试恢复到备份状态
    if [[ -f "${PROJECT_ROOT}/.last-backup" ]]; then
        local backup_dir
        backup_dir=$(cat "${PROJECT_ROOT}/.last-backup")
        log_info "尝试从备份恢复: ${backup_dir}"
        
        if [[ -f "${backup_dir}/docker-compose.yml" ]]; then
            cp "${backup_dir}/docker-compose.yml" "${PROJECT_ROOT}/"
            log_info "已恢复docker-compose配置"
        fi
    fi
    
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
    log_info "开始执行自动回滚..."
    
    # 创建日志目录
    mkdir -p "$(dirname "${LOG_FILE}")"
    
    # 检查环境
    check_command "docker"
    check_command "docker-compose"
    
    # 获取当前版本
    local current_version
    current_version=$(get_current_version)
    
    # 选择回滚目标
    select_rollback_target
    
    # 验证回滚目标
    validate_rollback_target
    
    # 确认回滚操作
    confirm_action "即将回滚到版本 ${ROLLBACK_TARGET}，当前版本 ${current_version} 将被替换。"
    
    # 执行回滚步骤
    backup_current_state
    stop_current_services
    update_image_tags
    start_rollback_services
    
    # 验证回滚结果
    if verify_rollback; then
        log_success "回滚操作完成！"
        send_rollback_notification "success" "${current_version}"
        log_info "日志文件: ${LOG_FILE}"
    else
        log_error "回滚验证失败"
        send_rollback_notification "failed" "${current_version}"
    fi
}

# 显示帮助信息
show_help() {
    cat << EOF
用法: $0 [选项]

选项:
    -h, --help              显示此帮助信息
    -t, --target VERSION    指定回滚目标版本
    -d, --dry-run          试运行模式（不执行实际操作）
    -f, --force            强制回滚（跳过确认）
    -l, --list             列出可用版本

示例:
    $0                          # 交互式选择回滚版本
    $0 --target v1.2.0          # 回滚到指定版本
    $0 --dry-run                # 试运行模式
    $0 --list                   # 列出可用版本

EOF
}

# 列出可用版本
list_versions() {
    log_info "可用的版本列表:"
    get_available_versions
    exit 0
}

# 参数解析
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -t|--target)
            ROLLBACK_TARGET="$2"
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -f|--force)
            FORCE_ROLLBACK=true
            shift
            ;;
        -l|--list)
            list_versions
            ;;
        *)
            log_error "未知参数: $1"
            ;;
    esac
done

# 执行主函数
main "$@"