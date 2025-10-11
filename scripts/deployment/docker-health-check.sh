#!/bin/bash

#==============================================================================
# 脚本名称: docker-health-check.sh
# 脚本描述: Docker容器健康检查脚本
# 作者: Guessing Pen Team
# 创建日期: 2025-10-11
# 版本: 1.0.0
#==============================================================================

set -euo pipefail

# 颜色定义
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# 配置
readonly TIMEOUT=10
readonly MAX_RETRIES=3
readonly RETRY_INTERVAL=5

#==============================================================================
# 日志函数
#==============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%H:%M:%S') - $1"
}

#==============================================================================
# 健康检查函数
#==============================================================================

# HTTP健康检查
check_http_endpoint() {
    local url="$1"
    local service_name="$2"
    local retries=0
    
    while [[ $retries -lt $MAX_RETRIES ]]; do
        if curl -f -s --max-time "$TIMEOUT" "$url" > /dev/null 2>&1; then
            log_success "${service_name} 健康检查通过: $url"
            return 0
        else
            retries=$((retries + 1))
            if [[ $retries -lt $MAX_RETRIES ]]; then
                log_warning "${service_name} 健康检查失败，重试 $retries/$MAX_RETRIES"
                sleep "$RETRY_INTERVAL"
            fi
        fi
    done
    
    log_error "${service_name} 健康检查失败: $url"
    return 1
}

# 检查容器状态
check_container_status() {
    local container_name="$1"
    
    if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "$container_name.*Up"; then
        log_success "容器 $container_name 运行正常"
        return 0
    else
        log_error "容器 $container_name 未运行或状态异常"
        return 1
    fi
}

# 检查容器日志中的错误
check_container_logs() {
    local container_name="$1"
    local error_patterns=("ERROR" "FATAL" "Exception" "failed" "error")
    
    log_info "检查容器 $container_name 的日志..."
    
    # 获取最近的日志
    local logs
    logs=$(docker logs --tail 50 "$container_name" 2>&1 || echo "")
    
    # 检查错误模式
    for pattern in "${error_patterns[@]}"; do
        if echo "$logs" | grep -i "$pattern" > /dev/null; then
            log_warning "在容器 $container_name 日志中发现 $pattern"
            echo "$logs" | grep -i "$pattern" | tail -3
        fi
    done
}

# 检查数据库连接
check_database_connection() {
    local container_name="$1"
    
    log_info "检查数据库连接..."
    
    # 通过API容器检查数据库连接
    if docker exec "$container_name" curl -f -s http://localhost:3005/api/health > /dev/null 2>&1; then
        log_success "数据库连接正常"
        return 0
    else
        log_error "数据库连接失败"
        return 1
    fi
}

# 检查资源使用情况
check_resource_usage() {
    local container_name="$1"
    
    log_info "检查容器 $container_name 资源使用情况..."
    
    # 获取容器统计信息
    local stats
    stats=$(docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" "$container_name" 2>/dev/null || echo "")
    
    if [[ -n "$stats" ]]; then
        echo "$stats"
        
        # 检查内存使用率
        local mem_percent
        mem_percent=$(echo "$stats" | tail -1 | awk '{print $4}' | sed 's/%//')
        
        if [[ -n "$mem_percent" ]] && (( $(echo "$mem_percent > 80" | bc -l) )); then
            log_warning "容器 $container_name 内存使用率较高: ${mem_percent}%"
        fi
    else
        log_warning "无法获取容器 $container_name 的资源统计信息"
    fi
}

#==============================================================================
# 主要检查函数
#==============================================================================

# 检查前端服务
check_frontend() {
    log_info "检查前端服务..."
    
    local container_name="guessing-pen-frontend"
    local health_url="http://localhost/health"
    local app_url="http://localhost"
    
    # 检查容器状态
    check_container_status "$container_name" || return 1
    
    # 检查健康端点
    check_http_endpoint "$health_url" "前端健康检查" || return 1
    
    # 检查应用首页
    check_http_endpoint "$app_url" "前端应用" || return 1
    
    # 检查资源使用
    check_resource_usage "$container_name"
    
    # 检查日志
    check_container_logs "$container_name"
    
    log_success "前端服务检查完成"
}

# 检查API服务
check_api() {
    log_info "检查API服务..."
    
    local container_name="guessing-pen-api"
    local health_url="http://localhost:3005/api/health"
    
    # 检查容器状态
    check_container_status "$container_name" || return 1
    
    # 检查健康端点
    check_http_endpoint "$health_url" "API健康检查" || return 1
    
    # 检查数据库连接
    check_database_connection "$container_name" || return 1
    
    # 检查资源使用
    check_resource_usage "$container_name"
    
    # 检查日志
    check_container_logs "$container_name"
    
    log_success "API服务检查完成"
}

# 检查PostgREST服务（如果启用）
check_postgrest() {
    local container_name="guessing-pen-postgrest"
    
    # 检查容器是否存在并运行
    if docker ps --format "{{.Names}}" | grep -q "$container_name"; then
        log_info "检查PostgREST服务..."
        
        local health_url="http://localhost:3001"
        
        # 检查容器状态
        check_container_status "$container_name" || return 1
        
        # 检查服务端点
        check_http_endpoint "$health_url" "PostgREST服务" || return 1
        
        # 检查资源使用
        check_resource_usage "$container_name"
        
        # 检查日志
        check_container_logs "$container_name"
        
        log_success "PostgREST服务检查完成"
    else
        log_info "PostgREST服务未启用，跳过检查"
    fi
}

# 检查网络连接
check_network() {
    log_info "检查Docker网络..."
    
    local network_name="guessing-pen-network"
    
    if docker network ls | grep -q "$network_name"; then
        log_success "Docker网络 $network_name 存在"
        
        # 检查网络中的容器
        local containers
        containers=$(docker network inspect "$network_name" --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null || echo "")
        
        if [[ -n "$containers" ]]; then
            log_info "网络中的容器: $containers"
        else
            log_warning "网络中没有容器"
        fi
    else
        log_error "Docker网络 $network_name 不存在"
        return 1
    fi
}

# 检查数据卷
check_volumes() {
    log_info "检查Docker数据卷..."
    
    local volumes=("guessing-pen-nginx-cache" "guessing-pen-logs")
    
    for volume in "${volumes[@]}"; do
        if docker volume ls | grep -q "$volume"; then
            log_success "数据卷 $volume 存在"
        else
            log_warning "数据卷 $volume 不存在"
        fi
    done
}

#==============================================================================
# 主函数
#==============================================================================

main() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔍 Docker容器健康检查开始"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
    
    local failed_checks=0
    
    # 执行各项检查
    check_network || ((failed_checks++))
    echo
    
    check_volumes || ((failed_checks++))
    echo
    
    check_frontend || ((failed_checks++))
    echo
    
    check_api || ((failed_checks++))
    echo
    
    check_postgrest || ((failed_checks++))
    echo
    
    # 显示总结
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if [[ $failed_checks -eq 0 ]]; then
        log_success "所有健康检查通过！"
        echo "🎉 系统运行正常"
    else
        log_error "有 $failed_checks 项检查失败"
        echo "⚠️  请检查上述错误并修复"
    fi
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    return $failed_checks
}

# 帮助信息
show_help() {
    cat << EOF
用法: $0 [选项]

选项:
    -h, --help      显示此帮助信息
    -v, --verbose   详细输出模式
    -q, --quiet     静默模式（仅显示错误）

描述:
    检查Docker容器的健康状态，包括：
    - 容器运行状态
    - HTTP端点响应
    - 数据库连接
    - 资源使用情况
    - 容器日志错误
    - 网络和数据卷状态

示例:
    $0              # 执行完整健康检查
    $0 --verbose    # 详细输出模式
    $0 --quiet      # 静默模式

EOF
}

# 参数解析
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--verbose)
            set -x
            shift
            ;;
        -q|--quiet)
            exec > /dev/null 2>&1
            shift
            ;;
        *)
            log_error "未知参数: $1"
            ;;
    esac
done

# 执行主函数
main "$@"