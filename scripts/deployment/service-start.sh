#!/bin/bash

#==============================================================================
# 脚本名称: service-start.sh
# 脚本描述: 服务启动脚本
# 作者: Guessing Pen Team
# 创建日期: 2025-10-11
# 版本: 1.0.0
#==============================================================================

set -euo pipefail

# 脚本配置
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly LOG_FILE="${PROJECT_ROOT}/logs/service-start-$(date +%Y%m%d-%H%M%S).log"

# 颜色定义
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# 服务配置
readonly COMPOSE_FILE="${PROJECT_ROOT}/docker-compose.prod.yml"
readonly STARTUP_TIMEOUT=120
readonly HEALTH_CHECK_RETRIES=5
readonly HEALTH_CHECK_INTERVAL=10

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
        log_error "Docker Compose文件不存在: ${COMPOSE_FILE}"
        exit 1
    fi
    
    # 验证compose文件语法
    if ! docker-compose -f "${COMPOSE_FILE}" config > /dev/null 2>&1; then
        log_error "Docker Compose文件语法错误"
        exit 1
    fi
    
    log_success "Docker Compose文件检查通过"
}

# 检查环境变量
check_environment() {
    log_info "检查环境变量..."
    
    local required_vars=(
        "DB_HOST"
        "DB_USER" 
        "DB_PASSWORD"
        "DB_NAME"
        "NODE_ENV"
    )
    
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            missing_vars+=("$var")
        fi
    done
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log_error "缺少必需的环境变量: ${missing_vars[*]}"
        exit 1
    fi
    
    log_success "环境变量检查完成"
}

# 检查Docker服务
check_docker_service() {
    log_info "检查Docker服务状态..."
    
    if ! docker info > /dev/null 2>&1; then
        log_error "Docker服务未运行"
        exit 1
    fi
    
    # 检查Docker Compose版本
    local compose_version
    compose_version=$(docker-compose --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    log_info "Docker Compose版本: ${compose_version}"
    
    log_success "Docker服务检查完成"
}

# 等待容器健康
wait_for_container_health() {
    local container_name="$1"
    local timeout="${2:-$STARTUP_TIMEOUT}"
    local elapsed=0
    
    log_info "等待容器 ${container_name} 变为健康状态..."
    
    while [[ $elapsed -lt $timeout ]]; do
        local status
        status=$(docker inspect --format='{{.State.Health.Status}}' "${container_name}" 2>/dev/null || echo "no-health-check")
        
        case "$status" in
            "healthy")
                log_success "容器 ${container_name} 健康检查通过"
                return 0
                ;;
            "unhealthy")
                log_error "容器 ${container_name} 健康检查失败"
                return 1
                ;;
            "starting"|"no-health-check")
                # 如果没有健康检查，检查容器是否运行
                if [[ "$status" == "no-health-check" ]]; then
                    if docker ps --format "{{.Names}}" | grep -q "^${container_name}$"; then
                        log_success "容器 ${container_name} 运行正常（无健康检查）"
                        return 0
                    fi
                fi
                ;;
        esac
        
        sleep 5
        elapsed=$((elapsed + 5))
        
        if [[ $((elapsed % 30)) -eq 0 ]]; then
            log_info "等待容器健康检查... (${elapsed}/${timeout}秒)"
        fi
    done
    
    log_error "容器 ${container_name} 健康检查超时"
    return 1
}

# 检查端口可用性
check_port_availability() {
    local port="$1"
    local service_name="$2"
    
    if netstat -tuln 2>/dev/null | grep -q ":${port} "; then
        log_warning "端口 ${port} 已被占用 (${service_name})"
        
        # 显示占用端口的进程
        local pid
        pid=$(lsof -ti:${port} 2>/dev/null || echo "")
        if [[ -n "$pid" ]]; then
            log_info "占用进程: $(ps -p $pid -o comm= 2>/dev/null || echo 'unknown')"
        fi
        
        return 1
    fi
    
    return 0
}

# 检查服务端点
check_service_endpoint() {
    local url="$1"
    local service_name="$2"
    local retries="${3:-$HEALTH_CHECK_RETRIES}"
    
    log_info "检查 ${service_name} 服务端点: ${url}"
    
    for ((i=1; i<=retries; i++)); do
        if curl -f -s --max-time 10 "${url}" > /dev/null 2>&1; then
            log_success "${service_name} 服务端点响应正常"
            return 0
        fi
        
        if [[ $i -lt $retries ]]; then
            log_info "端点检查失败，重试 ${i}/${retries}..."
            sleep "$HEALTH_CHECK_INTERVAL"
        fi
    done
    
    log_error "${service_name} 服务端点检查失败"
    return 1
}

#==============================================================================
# 服务管理函数
#==============================================================================

# 预启动检查
pre_start_checks() {
    log_info "执行预启动检查..."
    
    check_compose_file
    check_environment
    check_docker_service
    
    # 检查关键端口
    local ports=("80:前端服务" "3005:API服务")
    local port_conflicts=false
    
    for port_info in "${ports[@]}"; do
        local port="${port_info%%:*}"
        local service="${port_info##*:}"
        
        if ! check_port_availability "$port" "$service"; then
            port_conflicts=true
        fi
    done
    
    if [[ "$port_conflicts" == "true" ]]; then
        log_warning "检测到端口冲突，可能需要停止现有服务"
    fi
    
    log_success "预启动检查完成"
}

# 启动服务
start_services() {
    log_info "启动Docker服务..."
    
    # 创建必要的目录
    mkdir -p "${PROJECT_ROOT}/logs"
    
    # 设置环境变量
    export IMAGE_TAG="${IMAGE_TAG:-latest}"
    export ACR_REGISTRY="${ACR_REGISTRY:-registry.cn-hangzhou.aliyuncs.com}"
    export ACR_NAMESPACE="${ACR_NAMESPACE:-guessing-pen}"
    
    # 启动服务
    log_info "执行 docker-compose up..."
    if docker-compose -f "${COMPOSE_FILE}" up -d; then
        log_success "Docker Compose启动命令执行成功"
    else
        log_error "Docker Compose启动失败"
        return 1
    fi
    
    # 显示启动的容器
    log_info "启动的容器:"
    docker-compose -f "${COMPOSE_FILE}" ps
    
    return 0
}

# 等待服务就绪
wait_for_services() {
    log_info "等待服务就绪..."
    
    # 获取启动的容器列表
    local containers
    containers=$(docker-compose -f "${COMPOSE_FILE}" ps --services)
    
    # 等待每个容器健康
    while IFS= read -r service; do
        if [[ -n "$service" ]]; then
            local container_name
            container_name=$(docker-compose -f "${COMPOSE_FILE}" ps -q "$service" | xargs docker inspect --format='{{.Name}}' | sed 's/^\//')
            
            if [[ -n "$container_name" ]]; then
                wait_for_container_health "$container_name" || return 1
            fi
        fi
    done <<< "$containers"
    
    log_success "所有服务容器就绪"
}

# 验证服务功能
verify_services() {
    log_info "验证服务功能..."
    
    # 检查前端服务
    if check_service_endpoint "http://localhost" "前端应用"; then
        log_success "前端服务验证通过"
    else
        log_error "前端服务验证失败"
        return 1
    fi
    
    # 检查API服务
    if check_service_endpoint "http://localhost:3005/api/health" "API服务"; then
        log_success "API服务验证通过"
    else
        log_error "API服务验证失败"
        return 1
    fi
    
    # 检查数据库连接（通过API）
    if check_service_endpoint "http://localhost:3005/api/stats" "数据库连接"; then
        log_success "数据库连接验证通过"
    else
        log_warning "数据库连接验证失败，但服务可能仍然可用"
    fi
    
    log_success "服务功能验证完成"
}

# 显示服务状态
show_service_status() {
    echo
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🚀 服务启动完成"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # 显示容器状态
    echo "📊 容器状态:"
    docker-compose -f "${COMPOSE_FILE}" ps
    
    echo
    echo "🌐 服务访问地址:"
    echo "  前端应用:    http://localhost"
    echo "  API服务:     http://localhost:3005"
    echo "  健康检查:    http://localhost:3005/api/health"
    echo "  统计接口:    http://localhost:3005/api/stats"
    
    echo
    echo "📝 日志查看:"
    echo "  所有服务:    docker-compose -f ${COMPOSE_FILE} logs -f"
    echo "  前端服务:    docker-compose -f ${COMPOSE_FILE} logs -f frontend"
    echo "  API服务:     docker-compose -f ${COMPOSE_FILE} logs -f api"
    
    echo
    echo "🔧 管理命令:"
    echo "  停止服务:    ${SCRIPT_DIR}/service-stop.sh"
    echo "  重启服务:    ${SCRIPT_DIR}/service-start.sh --restart"
    echo "  查看状态:    docker-compose -f ${COMPOSE_FILE} ps"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

#==============================================================================
# 错误处理
#==============================================================================

cleanup_on_failure() {
    log_error "服务启动失败，执行清理..."
    
    # 显示失败的容器日志
    log_info "显示容器日志以便调试:"
    docker-compose -f "${COMPOSE_FILE}" logs --tail 20
    
    # 可选：停止失败的服务
    if [[ "${AUTO_CLEANUP:-false}" == "true" ]]; then
        log_info "自动清理失败的服务..."
        docker-compose -f "${COMPOSE_FILE}" down
    fi
}

error_handler() {
    local line_number="$1"
    log_error "脚本在第 ${line_number} 行发生错误"
    cleanup_on_failure
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
    echo "🚀 旮旯画师 - 服务启动"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📅 启动时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "🏷️  镜像标签: ${IMAGE_TAG:-latest}"
    echo "📁 Compose文件: ${COMPOSE_FILE}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
    
    # 创建日志目录
    mkdir -p "$(dirname "${LOG_FILE}")"
    
    # 执行启动流程
    pre_start_checks
    
    if [[ "${RESTART_MODE:-false}" == "true" ]]; then
        log_info "重启模式：先停止现有服务"
        "${SCRIPT_DIR}/service-stop.sh" --quiet || true
        sleep 5
    fi
    
    start_services
    wait_for_services
    verify_services
    
    # 计算启动时间
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log_success "服务启动完成！耗时: ${duration}秒"
    
    # 显示服务状态
    show_service_status
}

# 帮助信息
show_help() {
    cat << EOF
用法: $0 [选项]

选项:
    -h, --help          显示此帮助信息
    -r, --restart       重启模式（先停止现有服务）
    -v, --verbose       详细输出模式
    -q, --quiet         静默模式
    --skip-verify       跳过服务验证
    --auto-cleanup      启动失败时自动清理

环境变量:
    IMAGE_TAG          Docker镜像标签 (默认: latest)
    ACR_REGISTRY       ACR注册表地址
    ACR_NAMESPACE      ACR命名空间
    DB_HOST           数据库主机
    DB_USER           数据库用户名
    DB_PASSWORD       数据库密码
    DB_NAME           数据库名称
    NODE_ENV          运行环境 (production/development)

示例:
    $0                  # 启动服务
    $0 --restart        # 重启服务
    $0 --verbose        # 详细输出
    $0 --skip-verify    # 跳过验证

EOF
}

# 参数解析
RESTART_MODE=false
SKIP_VERIFY=false
QUIET_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -r|--restart)
            RESTART_MODE=true
            shift
            ;;
        -v|--verbose)
            set -x
            shift
            ;;
        -q|--quiet)
            QUIET_MODE=true
            exec > /dev/null 2>&1
            shift
            ;;
        --skip-verify)
            SKIP_VERIFY=true
            shift
            ;;
        --auto-cleanup)
            AUTO_CLEANUP=true
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

# 跳过验证模式
if [[ "$SKIP_VERIFY" == "true" ]]; then
    verify_services() {
        log_info "跳过服务验证"
    }
fi

# 执行主函数
main "$@"