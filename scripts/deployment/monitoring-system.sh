#!/bin/bash

#==============================================================================
# 脚本名称: monitoring-system.sh
# 脚本描述: 集成监控和日志系统主控制脚本
# 作者: Kiro AI Assistant
# 创建日期: 2025-10-11
# 版本: 1.0.0
#==============================================================================

# 设置严格模式
set -euo pipefail

# 获取脚本目录
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# 导入相关脚本
source "${SCRIPT_DIR}/logger.sh"
source "${SCRIPT_DIR}/deployment-tracker.sh"
source "${SCRIPT_DIR}/health-monitor.sh"
source "${SCRIPT_DIR}/notification-system.sh"
source "${SCRIPT_DIR}/log-collector.sh"

# 监控系统配置
readonly MONITORING_CONFIG_FILE="${PROJECT_ROOT}/logs/monitoring-config.json"
readonly MONITORING_PID_FILE="${PROJECT_ROOT}/logs/monitoring.pid"
readonly MONITORING_STATUS_FILE="${PROJECT_ROOT}/logs/monitoring-status.json"

# 创建监控系统配置
create_monitoring_config() {
    if [[ ! -f "${MONITORING_CONFIG_FILE}" ]]; then
        cat > "${MONITORING_CONFIG_FILE}" << EOF
{
  "enabled": true,
  "intervals": {
    "healthCheck": 60,
    "logCollection": 300,
    "deploymentTracking": 30,
    "systemMetrics": 120
  },
  "thresholds": {
    "healthCheckFailures": 3,
    "responseTimeWarning": 2000,
    "responseTimeError": 5000,
    "memoryUsageWarning": 80,
    "memoryUsageError": 90,
    "diskUsageWarning": 80,
    "diskUsageError": 90
  },
  "alerts": {
    "enabled": true,
    "cooldownPeriod": 300,
    "escalationLevels": ["warning", "error", "critical"]
  },
  "retention": {
    "metricsRetentionDays": 30,
    "logsRetentionDays": 30,
    "alertsRetentionDays": 90
  }
}
EOF
        log_info "创建监控系统配置文件: ${MONITORING_CONFIG_FILE}"
    fi
}

# 更新监控状态
update_monitoring_status() {
    local status="$1"
    local message="$2"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    cat > "${MONITORING_STATUS_FILE}" << EOF
{
  "status": "${status}",
  "message": "${message}",
  "timestamp": "${timestamp}",
  "pid": ${$},
  "uptime": $(cat /proc/uptime | cut -d' ' -f1 2>/dev/null || echo "0"),
  "lastHealthCheck": null,
  "lastLogCollection": null,
  "alertsCount": 0,
  "services": {
    "healthMonitor": "unknown",
    "logCollector": "unknown",
    "notificationSystem": "unknown",
    "deploymentTracker": "unknown"
  }
}
EOF
}

# 执行健康检查循环
health_check_loop() {
    local interval="${1:-60}"
    local failure_threshold="${2:-3}"
    local consecutive_failures=0
    
    log_info "启动健康检查循环 (间隔: ${interval}秒)"
    
    while true; do
        local check_start_time
        check_start_time=$(date +%s)
        
        if perform_health_check; then
            consecutive_failures=0
            log_debug "健康检查通过"
            
            # 更新状态文件
            if command -v jq &> /dev/null && [[ -f "${MONITORING_STATUS_FILE}" ]]; then
                local temp_file
                temp_file=$(mktemp)
                jq --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
                   '.lastHealthCheck = $timestamp | .services.healthMonitor = "healthy"' \
                   "${MONITORING_STATUS_FILE}" > "${temp_file}"
                mv "${temp_file}" "${MONITORING_STATUS_FILE}"
            fi
        else
            ((consecutive_failures++))
            log_warning "健康检查失败 (连续失败: ${consecutive_failures}/${failure_threshold})"
            
            # 更新状态文件
            if command -v jq &> /dev/null && [[ -f "${MONITORING_STATUS_FILE}" ]]; then
                local temp_file
                temp_file=$(mktemp)
                jq --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
                   '.lastHealthCheck = $timestamp | .services.healthMonitor = "unhealthy"' \
                   "${MONITORING_STATUS_FILE}" > "${temp_file}"
                mv "${temp_file}" "${MONITORING_STATUS_FILE}"
            fi
            
            # 检查是否需要发送告警
            if [[ "${consecutive_failures}" -ge "${failure_threshold}" ]]; then
                log_error "健康检查连续失败达到阈值，发送告警"
                notify_health_check_failure "production" "api,frontend" "连续${consecutive_failures}次健康检查失败"
                
                # 重置计数器，避免重复告警
                consecutive_failures=0
            fi
        fi
        
        # 计算下次检查时间
        local check_duration
        check_duration=$(($(date +%s) - check_start_time))
        local sleep_time
        sleep_time=$((interval - check_duration))
        
        if [[ "${sleep_time}" -gt 0 ]]; then
            sleep "${sleep_time}"
        fi
    done
}

# 执行日志收集循环
log_collection_loop() {
    local interval="${1:-300}"
    
    log_info "启动日志收集循环 (间隔: ${interval}秒)"
    
    while true; do
        local collection_start_time
        collection_start_time=$(date +%s)
        
        log_debug "开始日志收集"
        
        if collect_all_container_logs "5m"; then
            log_debug "日志收集完成"
            
            # 更新状态文件
            if command -v jq &> /dev/null && [[ -f "${MONITORING_STATUS_FILE}" ]]; then
                local temp_file
                temp_file=$(mktemp)
                jq --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
                   '.lastLogCollection = $timestamp | .services.logCollector = "active"' \
                   "${MONITORING_STATUS_FILE}" > "${temp_file}"
                mv "${temp_file}" "${MONITORING_STATUS_FILE}"
            fi
        else
            log_warning "日志收集失败"
            
            # 更新状态文件
            if command -v jq &> /dev/null && [[ -f "${MONITORING_STATUS_FILE}" ]]; then
                local temp_file
                temp_file=$(mktemp)
                jq --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
                   '.lastLogCollection = $timestamp | .services.logCollector = "error"' \
                   "${MONITORING_STATUS_FILE}" > "${temp_file}"
                mv "${temp_file}" "${MONITORING_STATUS_FILE}"
            fi
        fi
        
        # 执行日志轮转
        rotate_logs "api"
        rotate_logs "frontend"
        
        # 计算下次收集时间
        local collection_duration
        collection_duration=$(($(date +%s) - collection_start_time))
        local sleep_time
        sleep_time=$((interval - collection_duration))
        
        if [[ "${sleep_time}" -gt 0 ]]; then
            sleep "${sleep_time}"
        fi
    done
}

# 执行系统指标收集
system_metrics_loop() {
    local interval="${1:-120}"
    
    log_info "启动系统指标收集循环 (间隔: ${interval}秒)"
    
    while true; do
        collect_system_metrics
        sleep "${interval}"
    done
}

# 收集系统指标
collect_system_metrics() {
    local metrics_file="${PROJECT_ROOT}/logs/system-metrics.json"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # 收集CPU使用率
    local cpu_usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 2>/dev/null || echo "0")
    
    # 收集内存使用率
    local memory_info
    memory_info=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}' 2>/dev/null || echo "0")
    
    # 收集磁盘使用率
    local disk_usage
    disk_usage=$(df / | tail -1 | awk '{print $5}' | cut -d'%' -f1 2>/dev/null || echo "0")
    
    # 收集负载平均值
    local load_average
    load_average=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | cut -d',' -f1 2>/dev/null || echo "0")
    
    # 收集容器状态
    local container_stats
    container_stats=$(collect_container_stats)
    
    # 生成指标文件
    cat > "${metrics_file}" << EOF
{
  "timestamp": "${timestamp}",
  "system": {
    "cpu": {
      "usage": ${cpu_usage}
    },
    "memory": {
      "usage": ${memory_info}
    },
    "disk": {
      "usage": ${disk_usage}
    },
    "load": {
      "average": ${load_average}
    }
  },
  "containers": ${container_stats}
}
EOF
    
    # 检查阈值并发送告警
    check_metrics_thresholds "${cpu_usage}" "${memory_info}" "${disk_usage}"
}

# 收集容器统计信息
collect_container_stats() {
    local stats='{"running": 0, "stopped": 0, "containers": []}'
    
    if command -v docker &> /dev/null; then
        # 统计运行中的容器
        local running_count
        running_count=$(docker ps -q | wc -l)
        
        # 统计所有容器
        local total_count
        total_count=$(docker ps -aq | wc -l)
        local stopped_count
        stopped_count=$((total_count - running_count))
        
        # 获取容器详细信息
        local container_list='[]'
        if [[ "${running_count}" -gt 0 ]]; then
            container_list=$(docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | tail -n +2 | \
                jq -R -s 'split("\n") | map(select(length > 0)) | map(split("\t")) | 
                map({"name": .[0], "status": .[1], "ports": .[2]})' 2>/dev/null || echo '[]')
        fi
        
        stats=$(cat << EOF
{
  "running": ${running_count},
  "stopped": ${stopped_count},
  "containers": ${container_list}
}
EOF
)
    fi
    
    echo "${stats}"
}

# 检查指标阈值
check_metrics_thresholds() {
    local cpu_usage="$1"
    local memory_usage="$2"
    local disk_usage="$3"
    
    # 获取阈值配置
    local memory_warning memory_error disk_warning disk_error
    memory_warning=$(jq -r '.thresholds.memoryUsageWarning // 80' "${MONITORING_CONFIG_FILE}")
    memory_error=$(jq -r '.thresholds.memoryUsageError // 90' "${MONITORING_CONFIG_FILE}")
    disk_warning=$(jq -r '.thresholds.diskUsageWarning // 80' "${MONITORING_CONFIG_FILE}")
    disk_error=$(jq -r '.thresholds.diskUsageError // 90' "${MONITORING_CONFIG_FILE}")
    
    # 检查内存使用率
    if (( $(echo "${memory_usage} > ${memory_error}" | bc -l) )); then
        log_error "内存使用率过高: ${memory_usage}% (阈值: ${memory_error}%)"
        # 发送告警
    elif (( $(echo "${memory_usage} > ${memory_warning}" | bc -l) )); then
        log_warning "内存使用率警告: ${memory_usage}% (阈值: ${memory_warning}%)"
    fi
    
    # 检查磁盘使用率
    if (( $(echo "${disk_usage} > ${disk_error}" | bc -l) )); then
        log_error "磁盘使用率过高: ${disk_usage}% (阈值: ${disk_error}%)"
        # 发送告警
    elif (( $(echo "${disk_usage} > ${disk_warning}" | bc -l) )); then
        log_warning "磁盘使用率警告: ${disk_usage}% (阈值: ${disk_warning}%)"
    fi
}

# 启动监控系统
start_monitoring_system() {
    log_info "启动监控系统..."
    
    # 检查是否已经在运行
    if [[ -f "${MONITORING_PID_FILE}" ]]; then
        local old_pid
        old_pid=$(cat "${MONITORING_PID_FILE}")
        if kill -0 "${old_pid}" 2>/dev/null; then
            log_warning "监控系统已在运行 (PID: ${old_pid})"
            return 1
        else
            log_info "清理旧的PID文件"
            rm -f "${MONITORING_PID_FILE}"
        fi
    fi
    
    # 创建配置文件
    create_monitoring_config
    
    # 初始化各个子系统
    init_notification_system
    init_log_collection_system
    
    # 记录PID
    echo $$ > "${MONITORING_PID_FILE}"
    
    # 更新状态
    update_monitoring_status "starting" "监控系统正在启动"
    
    # 获取配置参数
    local health_interval log_interval metrics_interval
    health_interval=$(jq -r '.intervals.healthCheck // 60' "${MONITORING_CONFIG_FILE}")
    log_interval=$(jq -r '.intervals.logCollection // 300' "${MONITORING_CONFIG_FILE}")
    metrics_interval=$(jq -r '.intervals.systemMetrics // 120' "${MONITORING_CONFIG_FILE}")
    
    # 启动后台进程
    health_check_loop "${health_interval}" &
    local health_pid=$!
    
    log_collection_loop "${log_interval}" &
    local log_pid=$!
    
    system_metrics_loop "${metrics_interval}" &
    local metrics_pid=$!
    
    # 更新状态
    update_monitoring_status "running" "监控系统正在运行"
    
    log_success "监控系统启动完成"
    log_info "- 健康检查进程 PID: ${health_pid}"
    log_info "- 日志收集进程 PID: ${log_pid}"
    log_info "- 指标收集进程 PID: ${metrics_pid}"
    
    # 等待子进程
    wait
}

# 停止监控系统
stop_monitoring_system() {
    log_info "停止监控系统..."
    
    if [[ -f "${MONITORING_PID_FILE}" ]]; then
        local pid
        pid=$(cat "${MONITORING_PID_FILE}")
        
        if kill -0 "${pid}" 2>/dev/null; then
            log_info "终止监控进程 (PID: ${pid})"
            kill -TERM "${pid}" 2>/dev/null || true
            
            # 等待进程结束
            local timeout=10
            while [[ "${timeout}" -gt 0 ]] && kill -0 "${pid}" 2>/dev/null; do
                sleep 1
                ((timeout--))
            done
            
            # 强制终止
            if kill -0 "${pid}" 2>/dev/null; then
                log_warning "强制终止监控进程"
                kill -KILL "${pid}" 2>/dev/null || true
            fi
        fi
        
        rm -f "${MONITORING_PID_FILE}"
    fi
    
    # 更新状态
    update_monitoring_status "stopped" "监控系统已停止"
    
    log_success "监控系统已停止"
}

# 获取监控状态
get_monitoring_status() {
    if [[ -f "${MONITORING_STATUS_FILE}" ]]; then
        cat "${MONITORING_STATUS_FILE}"
    else
        echo '{"status": "unknown", "message": "监控状态文件不存在"}'
    fi
}

# 重启监控系统
restart_monitoring_system() {
    log_info "重启监控系统..."
    stop_monitoring_system
    sleep 2
    start_monitoring_system
}

# 如果直接运行此脚本，执行相应命令
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-help}" in
        "start")
            start_monitoring_system
            ;;
        "stop")
            stop_monitoring_system
            ;;
        "restart")
            restart_monitoring_system
            ;;
        "status")
            get_monitoring_status | jq . 2>/dev/null || cat
            ;;
        "init")
            create_monitoring_config
            init_notification_system
            init_log_collection_system
            log_success "监控系统初始化完成"
            ;;
        *)
            cat << EOF
集成监控和日志系统

使用方法:
    $0 [命令]

命令:
    start       - 启动监控系统
    stop        - 停止监控系统
    restart     - 重启监控系统
    status      - 显示监控状态
    init        - 初始化监控系统
    help        - 显示此帮助信息

配置文件:
    ${MONITORING_CONFIG_FILE}

状态文件:
    ${MONITORING_STATUS_FILE}

PID文件:
    ${MONITORING_PID_FILE}

功能模块:
    - 健康检查监控
    - 容器日志收集
    - 系统指标收集
    - 部署状态跟踪
    - 告警通知系统

示例:
    $0 init         # 初始化系统
    $0 start        # 启动监控
    $0 status       # 查看状态

EOF
            ;;
    esac
fi