#!/bin/bash

#==============================================================================
# 脚本名称: service-stop.sh
# 脚本描述: 服务停止脚本
# 作者: Guessing Pen Team
# 创建日期: 2025-10-11
# 版本: 1.0.0
#==============================================================================

set -euo pipefail

# 脚本配置
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly LOG_FILE="${PROJECT_ROOT}/logs/service-stop-$(date +%Y%m%d-%H%M%S).log"

# 颜色定义
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# 停止配置
readonly COMPOSE_FILE="${PROJECT_ROOT}/docker-compose.prod.yml"
readonly GRACEFUL_TIMEOUT=30
readonly FORCE_TIMEOUT=10
readonly CLEANUP_TIMEOUT=60

#==============================================================================
# 日志函数
#==============================================================================

log_info() {
    local message="$1"
    echo -e "${BLUE}[INFO]${NC} $(date '+%H:%M:%S') - ${message}" | tee -a "${LOG_FILE}"
}

log_success() {
    local message="$1"
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%H:%M:%S') - ${message}" | tee -a "${LOG_FILE}"
}

log_warning() {
    local message="$1"
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%H:%M:%S') - ${message}" | tee -a "${LOG_FILE}"
}

log_error() {
    local message="$1"
    echo -e "${RED}[ERROR]${NC} $(date '+%H:%M:%S') - ${message}" | tee -a "${LOG_FILE}"
}

#==============================================================================
# 工具函数
#==============================================================================

# 检查Docker Compose文件
check_compose_file() {
    if [[ ! -f "${COMPOSE_FILE}" ]]; then
        log_warning "Docker Compose文件不存在: ${COMPOSE_FILE}"
        return 1
    fi
    
    if ! docker-compose -f "${COMPOSE_FILE}" config > /dev/null 2>&1; then
        log_error "Docker Compose文件语法错误"
        return 1
    fi
    
    return 0
}

# 检查服务是否运行
check_services_running() {
    if ! check_compose_file; then
        return 1
    fi
    
    local running_containers
    running_containers=$(docker-compose -f "${COMPOSE_FILE}" ps -q 2>/dev/null | wc -l)
    
    if [[ $running_containers -eq 0 ]]; then
        log_info "没有运行中的服务"
        return 1
    fi
    
    log_info "发现 ${running_containers} 个运行中的容器"
    return 0
}

# 等待容器停止
wait_for_container_stop() {
    local container_name="$1"
    local timeout="${2:-$GRACEFUL_TIMEOUT}"
    local elapsed=0
    
    log_info "等待容器 ${container_name} 停止..."
    
    while [[ $elapsed -lt $timeout ]]; do
        if ! docker ps --format "{{.Names}}" | grep -q "^${container_name}$"; then
            log_success "容器 ${container_name} 已停止"
            return 0
        fi
        
        sleep 2
        elapsed=$((elapsed + 2))
        
        if [[ $((elapsed % 10)) -eq 0 ]]; then
            log_info "等待容器停止... (${elapsed}/${timeout}秒)"
        fi
    done
    
    log_warning "容器 ${container_name} 停止超时"
    return 1
}

# 强制停止容器
force_stop_container() {
    local container_name="$1"
    
    log_warning "强制停止容器: ${container_name}"
    
    if docker kill "${container_name}" 2>/dev/null; then
        log_success "容器 ${container_name} 强制停止成功"
    else
        log_error "容器 ${container_name} 强制停止失败"
        return 1
    fi
}

# 检查端口释放
check_port_released() {
    local port="$1"
    local service_name="$2"
    
    if netstat -tuln 2>/dev/null | grep -q ":${port} "; then
        log_warning "端口 ${port} 仍被占用 (${service_name})"
        return 1
    else
        log_success "端口 ${port} 已释放 (${service_name})"
        return 0
    fi
}

#==============================================================================
# 停止服务函数
#==============================================================================

# 显示当前服务状态
show_current_status() {
    log_info "当前服务状态:"
    
    if check_compose_file && docker-compose -f "${COMPOSE_FILE}" ps 2>/dev/null; then
        docker-compose -f "${COMPOSE_FILE}" ps
    else
        log_info "没有通过Docker Compose管理的服务"
    fi
    
    # 显示相关的Docker容器
    local related_containers
    related_containers=$(docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(guessing-pen|frontend|api)" || echo "")
    
    if [[ -n "$related_containers" ]]; then
        echo
        log_info "相关的Docker容器:"
        echo "$related_containers"
    fi
}

# 优雅停止服务
graceful_stop() {
    log_info "开始优雅停止服务..."
    
    if ! check_services_running; then
        log_info "没有需要停止的服务"
        return 0
    fi
    
    # 获取运行中的容器列表
    local containers
    containers=$(docker-compose -f "${COMPOSE_FILE}" ps --format "{{.Names}}" 2>/dev/null || echo "")
    
    if [[ -z "$containers" ]]; then
        log_info "没有运行中的容器"
        return 0
    fi
    
    # 发送停止信号
    log_info "发送停止信号到服务..."
    if docker-compose -f "${COMPOSE_FILE}" stop --timeout "$GRACEFUL_TIMEOUT"; then
        log_success "服务优雅停止成功"
    else
        log_warning "服务优雅停止超时"
        return 1
    fi
    
    # 验证容器已停止
    while IFS= read -r container; do
        if [[ -n "$container" ]]; then
            wait_for_container_stop "$container" 10 || return 1
        fi
    done <<< "$containers"
    
    log_success "所有容器已优雅停止"
}

# 强制停止服务
force_stop() {
    log_warning "开始强制停止服务..."
    
    # 强制停止Docker Compose服务
    if check_compose_file; then
        log_info "强制停止Docker Compose服务..."
        docker-compose -f "${COMPOSE_FILE}" kill 2>/dev/null || true
        
        # 等待一段时间
        sleep 3
    fi
    
    # 强制停止相关容器
    local related_containers
    related_containers=$(docker ps --format "{{.Names}}" | grep -E "(guessing-pen|frontend|api)" || echo "")
    
    if [[ -n "$related_containers" ]]; then
        log_info "强制停止相关容器..."
        while IFS= read -r container; do
            if [[ -n "$container" ]]; then
                force_stop_container "$container" || true
            fi
        done <<< "$related_containers"
    fi
    
    log_success "强制停止完成"
}

# 清理资源
cleanup_resources() {
    log_info "清理Docker资源..."
    
    # 移除停止的容器
    if check_compose_file; then
        log_info "移除停止的容器..."
        docker-compose -f "${COMPOSE_FILE}" rm -f 2>/dev/null || true
    fi
    
    # 清理孤立容器
    local orphaned_containers
    orphaned_containers=$(docker ps -a --format "{{.Names}}" | grep -E "(guessing-pen|frontend|api)" | grep -v "$(docker ps --format "{{.Names}}")" || echo "")
    
    if [[ -n "$orphaned_containers" ]]; then
        log_info "清理孤立容器..."
        while IFS= read -r container; do
            if [[ -n "$container" ]]; then
                docker rm -f "$container" 2>/dev/null || true
                log_info "已移除容器: $container"
            fi
        done <<< "$orphaned_containers"
    fi
    
    # 可选：清理未使用的镜像
    if [[ "${CLEANUP_IMAGES:-false}" == "true" ]]; then
        log_info "清理未使用的镜像..."
        docker image prune -f || true
    fi
    
    # 可选：清理未使用的网络
    if [[ "${CLEANUP_NETWORKS:-false}" == "true" ]]; then
        log_info "清理未使用的网络..."
        docker network prune -f || true
    fi
    
    log_success "资源清理完成"
}

# 验证停止结果
verify_stop() {
    log_info "验证服务停止状态..."
    
    # 检查容器状态
    local running_containers
    running_containers=$(docker ps --format "{{.Names}}" | grep -E "(guessing-pen|frontend|api)" || echo "")
    
    if [[ -n "$running_containers" ]]; then
        log_error "以下容器仍在运行:"
        echo "$running_containers"
        return 1
    fi
    
    # 检查端口释放
    local ports=("80:前端服务" "3005:API服务")
    local port_issues=false
    
    for port_info in "${ports[@]}"; do
        local port="${port_info%%:*}"
        local service="${port_info##*:}"
        
        if ! check_port_released "$port" "$service"; then
            port_issues=true
        fi
    done
    
    if [[ "$port_issues" == "true" ]]; then
        log_warning "部分端口仍被占用，可能需要手动处理"
    fi
    
    log_success "服务停止验证完成"
}

# 显示停止后状态
show_stop_status() {
    echo
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🛑 服务停止完成"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # 显示当前Docker状态
    echo "📊 当前Docker状态:"
    local all_containers
    all_containers=$(docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(guessing-pen|frontend|api|NAMES)" || echo "没有相关容器")
    echo "$all_containers"
    
    echo
    echo "🔧 管理命令:"
    echo "  启动服务:    ${SCRIPT_DIR}/service-start.sh"
    echo "  查看日志:    docker-compose -f ${COMPOSE_FILE} logs"
    echo "  完全清理:    $0 --cleanup-all"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

#==============================================================================
# 错误处理
#==============================================================================

error_handler() {
    local line_number="$1"
    log_error "脚本在第 ${line_number} 行发生错误"
    
    # 显示当前状态以便调试
    log_info "当前Docker状态:"
    docker ps -a | grep -E "(guessing-pen|frontend|api)" || echo "没有相关容器"
    
    exit 1
}

# 设置错误处理
trap 'error_handler ${LINENO}' ERR

#==============================================================================
# 主函数
#==============================================================================

main() {
    local start_time
    start_time=$(date +%s)
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🛑 旮旯画师 - 服务停止"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📅 停止时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "📁 Compose文件: ${COMPOSE_FILE}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
    
    # 创建日志目录
    mkdir -p "$(dirname "${LOG_FILE}")"
    
    # 显示当前状态
    show_current_status
    echo
    
    # 执行停止流程
    local stop_success=false
    
    # 尝试优雅停止
    if [[ "${FORCE_MODE:-false}" != "true" ]]; then
        if graceful_stop; then
            stop_success=true
        else
            log_warning "优雅停止失败，将尝试强制停止"
        fi
    fi
    
    # 如果优雅停止失败或强制模式，执行强制停止
    if [[ "$stop_success" != "true" ]]; then
        force_stop
    fi
    
    # 清理资源
    if [[ "${SKIP_CLEANUP:-false}" != "true" ]]; then
        cleanup_resources
    fi
    
    # 验证停止结果
    if [[ "${SKIP_VERIFY:-false}" != "true" ]]; then
        verify_stop
    fi
    
    # 计算停止时间
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log_success "服务停止完成！耗时: ${duration}秒"
    
    # 显示停止后状态
    show_stop_status
}

# 帮助信息
show_help() {
    cat << EOF
用法: $0 [选项]

选项:
    -h, --help          显示此帮助信息
    -f, --force         强制停止模式（跳过优雅停止）
    -v, --verbose       详细输出模式
    -q, --quiet         静默模式
    --skip-cleanup      跳过资源清理
    --skip-verify       跳过停止验证
    --cleanup-all       清理所有相关资源（镜像、网络等）

描述:
    停止旮旯画师应用的所有服务，包括：
    - 前端服务 (端口 80)
    - API服务 (端口 3005)
    - 相关的Docker容器和网络

停止流程:
    1. 显示当前服务状态
    2. 优雅停止服务 (30秒超时)
    3. 强制停止 (如果优雅停止失败)
    4. 清理Docker资源
    5. 验证停止结果

示例:
    $0                  # 优雅停止服务
    $0 --force          # 强制停止服务
    $0 --cleanup-all    # 停止并清理所有资源
    $0 --quiet          # 静默模式

EOF
}

# 参数解析
FORCE_MODE=false
SKIP_CLEANUP=false
SKIP_VERIFY=false
CLEANUP_IMAGES=false
CLEANUP_NETWORKS=false
QUIET_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -f|--force)
            FORCE_MODE=true
            shift
            ;;
        -v|--verbose)
            set -x
            shift
            ;;
        -q|--quiet)
            QUIET_MODE=true
            shift
            ;;
        --skip-cleanup)
            SKIP_CLEANUP=true
            shift
            ;;
        --skip-verify)
            SKIP_VERIFY=true
            shift
            ;;
        --cleanup-all)
            CLEANUP_IMAGES=true
            CLEANUP_NETWORKS=true
            shift
            ;;
        *)
            log_error "未知参数: $1"
            show_help
            exit 1
            ;;
    esac
done

# 静默模式下重定向输出
if [[ "$QUIET_MODE" == "true" ]]; then
    exec > "${LOG_FILE}" 2>&1
fi

# 执行主函数
main "$@"