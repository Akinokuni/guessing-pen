#!/bin/bash

#==============================================================================
# 脚本名称: health-monitor.sh
# 脚本描述: 服务健康检查和监控
# 作者: Kiro AI Assistant
# 创建日期: 2025-10-11
# 版本: 1.0.0
#==============================================================================

# 设置严格模式
set -euo pipefail

# 获取脚本目录
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# 导入日志工具
source "${SCRIPT_DIR}/logger.sh"

# 健康检查配置
readonly HEALTH_CHECK_TIMEOUT=30
readonly HEALTH_CHECK_RETRIES=3
readonly HEALTH_CHECK_INTERVAL=5

# 服务配置
readonly FRONTEND_PORT="${FRONTEND_PORT:-80}"
readonly API_PORT="${API_PORT:-3005}"
readonly FRONTEND_HOST="${FRONTEND_HOST:-localhost}"
readonly API_HOST="${API_HOST:-localhost}"

# 健康检查结果文件
readonly HEALTH_STATUS_FILE="${PROJECT_ROOT}/logs/health-status.json"

# 创建健康状态文件
create_health_status_file() {
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    cat > "${HEALTH_STATUS_FILE}" << EOF
{
  "timestamp": "${timestamp}",
  "overall": "unknown",
  "services": {
    "frontend": {
      "status": "unknown",
      "url": "http://${FRONTEND_HOST}:${FRONTEND_PORT}",
      "responseTime": null,
      "lastCheck": null,
      "error": null
    },
    "api": {
      "status": "unknown",
      "url": "http://${API_HOST}:${API_PORT}",
      "responseTime": null,
      "lastCheck": null,
      "error": null
    },
    "database": {
      "status": "unknown",
      "responseTime": null,
      "lastCheck": null,
      "error": null
    }
  }
}
EOF
}

# 检查HTTP服务
check_http_service() {
    local service_name="$1"
    local url="$2"
    local expected_status="${3:-200}"
    
    log_debug "检查HTTP服务: ${service_name} - ${url}"
    
    local start_time end_time response_time http_status
    start_time=$(date +%s.%N)
    
    if http_status=$(curl -s -o /dev/null -w "%{http_code}" \
                          --connect-timeout "${HEALTH_CHECK_TIMEOUT}" \
                          --max-time "${HEALTH_CHECK_TIMEOUT}" \
                          "${url}" 2>/dev/null); then
        end_time=$(date +%s.%N)
        response_time=$(echo "${end_time} - ${start_time}" | bc -l 2>/dev/null || echo "0")
        response_time=$(printf "%.3f" "${response_time}")
        
        if [[ "${http_status}" == "${expected_status}" ]]; then
            log_success "${service_name}服务健康 (${response_time}s, HTTP ${http_status})"
            update_service_status "${service_name}" "healthy" "${response_time}" ""
            return 0
        else
            log_warning "${service_name}服务响应异常 (HTTP ${http_status})"
            update_service_status "${service_name}" "unhealthy" "${response_time}" "HTTP状态码: ${http_status}"
            return 1
        fi
    else
        log_error "${service_name}服务无法访问"
        update_service_status "${service_name}" "unreachable" "null" "连接超时或拒绝连接"
        return 1
    fi
}

# 检查API健康端点
check_api_health() {
    local api_url="http://${API_HOST}:${API_PORT}/health"
    
    log_debug "检查API健康端点: ${api_url}"
    
    local start_time end_time response_time response_body
    start_time=$(date +%s.%N)
    
    if response_body=$(curl -s --connect-timeout "${HEALTH_CHECK_TIMEOUT}" \
                            --max-time "${HEALTH_CHECK_TIMEOUT}" \
                            "${api_url}" 2>/dev/null); then
        end_time=$(date +%s.%N)
        response_time=$(echo "${end_time} - ${start_time}" | bc -l 2>/dev/null || echo "0")
        response_time=$(printf "%.3f" "${response_time}")
        
        # 检查响应内容
        if echo "${response_body}" | grep -q '"status":"ok"' 2>/dev/null; then
            log_success "API健康检查通过 (${response_time}s)"
            update_service_status "api" "healthy" "${response_time}" ""
            return 0
        else
            log_warning "API健康检查响应异常: ${response_body}"
            update_service_status "api" "unhealthy" "${response_time}" "健康检查响应异常"
            return 1
        fi
    else
        log_error "API健康检查失败"
        update_service_status "api" "unreachable" "null" "无法连接到健康检查端点"
        return 1
    fi
}

# 检查数据库连接
check_database_connection() {
    log_debug "检查数据库连接"
    
    local start_time end_time response_time
    start_time=$(date +%s.%N)
    
    # 通过API检查数据库连接
    local db_check_url="http://${API_HOST}:${API_PORT}/api/health/db"
    
    if response_body=$(curl -s --connect-timeout "${HEALTH_CHECK_TIMEOUT}" \
                            --max-time "${HEALTH_CHECK_TIMEOUT}" \
                            "${db_check_url}" 2>/dev/null); then
        end_time=$(date +%s.%N)
        response_time=$(echo "${end_time} - ${start_time}" | bc -l 2>/dev/null || echo "0")
        response_time=$(printf "%.3f" "${response_time}")
        
        if echo "${response_body}" | grep -q '"connected":true' 2>/dev/null; then
            log_success "数据库连接正常 (${response_time}s)"
            update_service_status "database" "healthy" "${response_time}" ""
            return 0
        else
            log_error "数据库连接失败: ${response_body}"
            update_service_status "database" "unhealthy" "${response_time}" "数据库连接失败"
            return 1
        fi
    else
        log_error "无法检查数据库连接"
        update_service_status "database" "unreachable" "null" "无法访问数据库检查端点"
        return 1
    fi
}

# 更新服务状态
update_service_status() {
    local service="$1"
    local status="$2"
    local response_time="$3"
    local error_message="$4"
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # 确保健康状态文件存在
    if [[ ! -f "${HEALTH_STATUS_FILE}" ]]; then
        create_health_status_file
    fi
    
    # 使用临时文件更新JSON
    local temp_file
    temp_file=$(mktemp)
    
    if command -v jq &> /dev/null; then
        jq --arg service "${service}" \
           --arg status "${status}" \
           --arg responseTime "${response_time}" \
           --arg lastCheck "${timestamp}" \
           --arg error "${error_message}" \
           '.services[$service].status = $status |
            .services[$service].responseTime = (if $responseTime == "null" then null else ($responseTime | tonumber) end) |
            .services[$service].lastCheck = $lastCheck |
            .services[$service].error = (if $error == "" then null else $error end)' \
           "${HEALTH_STATUS_FILE}" > "${temp_file}"
        mv "${temp_file}" "${HEALTH_STATUS_FILE}"
    fi
}

# 更新整体状态
update_overall_status() {
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    if [[ ! -f "${HEALTH_STATUS_FILE}" ]]; then
        return 1
    fi
    
    local overall_status
    if command -v jq &> /dev/null; then
        # 检查所有服务是否健康
        local healthy_count unhealthy_count
        healthy_count=$(jq '.services | to_entries | map(select(.value.status == "healthy")) | length' "${HEALTH_STATUS_FILE}")
        unhealthy_count=$(jq '.services | to_entries | map(select(.value.status != "healthy")) | length' "${HEALTH_STATUS_FILE}")
        
        if [[ "${unhealthy_count}" -eq 0 ]]; then
            overall_status="healthy"
        elif [[ "${healthy_count}" -gt 0 ]]; then
            overall_status="degraded"
        else
            overall_status="unhealthy"
        fi
        
        # 更新整体状态和时间戳
        local temp_file
        temp_file=$(mktemp)
        jq --arg overall "${overall_status}" \
           --arg timestamp "${timestamp}" \
           '.overall = $overall | .timestamp = $timestamp' \
           "${HEALTH_STATUS_FILE}" > "${temp_file}"
        mv "${temp_file}" "${HEALTH_STATUS_FILE}"
    fi
    
    log_info "整体健康状态: ${overall_status}"
}

# 执行完整健康检查
perform_health_check() {
    log_info "开始执行健康检查..."
    
    create_health_status_file
    
    local frontend_healthy=false
    local api_healthy=false
    local db_healthy=false
    
    # 检查前端服务
    if check_http_service "frontend" "http://${FRONTEND_HOST}:${FRONTEND_PORT}" "200"; then
        frontend_healthy=true
    fi
    
    # 检查API服务
    if check_api_health; then
        api_healthy=true
    fi
    
    # 检查数据库连接
    if check_database_connection; then
        db_healthy=true
    fi
    
    # 更新整体状态
    update_overall_status
    
    # 返回检查结果
    if [[ "${frontend_healthy}" == true && "${api_healthy}" == true && "${db_healthy}" == true ]]; then
        log_success "所有服务健康检查通过"
        return 0
    else
        log_warning "部分服务健康检查失败"
        return 1
    fi
}

# 持续健康监控
continuous_health_monitoring() {
    local interval="${1:-60}"
    local max_failures="${2:-3}"
    
    log_info "开始持续健康监控 (间隔: ${interval}秒, 最大失败次数: ${max_failures})"
    
    local failure_count=0
    
    while true; do
        if perform_health_check; then
            failure_count=0
        else
            ((failure_count++))
            log_warning "健康检查失败 (${failure_count}/${max_failures})"
            
            if [[ "${failure_count}" -ge "${max_failures}" ]]; then
                log_error "连续健康检查失败达到阈值，发送告警"
                send_health_alert "连续${failure_count}次健康检查失败"
            fi
        fi
        
        sleep "${interval}"
    done
}

# 发送健康告警
send_health_alert() {
    local alert_message="$1"
    
    log_error "健康告警: ${alert_message}"
    
    # 这里可以集成各种告警方式
    # 例如：邮件、Slack、钉钉、企业微信等
    
    # 记录告警到文件
    local alert_file="${PROJECT_ROOT}/logs/health-alerts.log"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    echo "[${timestamp}] ALERT: ${alert_message}" >> "${alert_file}"
    
    # 如果配置了webhook，发送通知
    if [[ -n "${HEALTH_ALERT_WEBHOOK:-}" ]]; then
        curl -s -X POST "${HEALTH_ALERT_WEBHOOK}" \
             -H "Content-Type: application/json" \
             -d "{\"text\":\"健康检查告警: ${alert_message}\",\"timestamp\":\"${timestamp}\"}" \
             2>/dev/null || log_warning "发送webhook告警失败"
    fi
}

# 获取健康状态
get_health_status() {
    if [[ -f "${HEALTH_STATUS_FILE}" ]]; then
        cat "${HEALTH_STATUS_FILE}"
    else
        echo '{"overall": "unknown", "message": "健康状态文件不存在"}'
    fi
}

# 等待服务就绪
wait_for_services() {
    local timeout="${1:-300}"
    local check_interval="${2:-10}"
    
    log_info "等待服务就绪 (超时: ${timeout}秒)"
    
    local elapsed=0
    
    while [[ "${elapsed}" -lt "${timeout}" ]]; do
        if perform_health_check; then
            log_success "所有服务已就绪"
            return 0
        fi
        
        log_info "等待服务就绪... (${elapsed}/${timeout}秒)"
        sleep "${check_interval}"
        elapsed=$((elapsed + check_interval))
    done
    
    log_error "等待服务就绪超时"
    return 1
}

# 如果直接运行此脚本，执行相应命令
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-check}" in
        "check")
            perform_health_check
            ;;
        "status")
            get_health_status | jq . 2>/dev/null || cat
            ;;
        "monitor")
            continuous_health_monitoring "${2:-60}" "${3:-3}"
            ;;
        "wait")
            wait_for_services "${2:-300}" "${3:-10}"
            ;;
        *)
            cat << EOF
服务健康检查和监控工具

使用方法:
    $0 [命令] [参数]

命令:
    check               - 执行一次健康检查
    status              - 显示当前健康状态
    monitor [间隔] [失败阈值] - 持续监控 (默认60秒间隔，3次失败阈值)
    wait [超时] [间隔]   - 等待服务就绪 (默认300秒超时，10秒间隔)
    help                - 显示此帮助信息

环境变量:
    FRONTEND_HOST       - 前端服务主机 (默认: localhost)
    FRONTEND_PORT       - 前端服务端口 (默认: 80)
    API_HOST            - API服务主机 (默认: localhost)
    API_PORT            - API服务端口 (默认: 3005)
    HEALTH_ALERT_WEBHOOK - 告警webhook URL

示例:
    $0 check                    # 执行健康检查
    $0 monitor 30 5             # 每30秒检查，5次失败后告警
    $0 wait 600 15              # 等待服务就绪，最多10分钟

EOF
            ;;
    esac
fi