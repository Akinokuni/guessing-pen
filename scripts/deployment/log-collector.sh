#!/bin/bash

#==============================================================================
# 脚本名称: log-collector.sh
# 脚本描述: 容器日志收集和管理系统
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

# 日志收集配置
readonly LOG_COLLECTION_DIR="${PROJECT_ROOT}/logs/containers"
readonly LOG_CONFIG_FILE="${PROJECT_ROOT}/logs/log-collection-config.json"
readonly MAX_LOG_SIZE="100M"
readonly MAX_LOG_FILES=10
readonly LOG_ROTATION_INTERVAL="daily"

# 容器名称配置
readonly FRONTEND_CONTAINER_NAME="${FRONTEND_CONTAINER_NAME:-guessing-pen-frontend}"
readonly API_CONTAINER_NAME="${API_CONTAINER_NAME:-guessing-pen-api}"
readonly DB_CONTAINER_NAME="${DB_CONTAINER_NAME:-guessing-pen-db}"

# 创建日志收集目录
create_log_directories() {
    local directories=(
        "${LOG_COLLECTION_DIR}"
        "${LOG_COLLECTION_DIR}/frontend"
        "${LOG_COLLECTION_DIR}/api"
        "${LOG_COLLECTION_DIR}/database"
        "${LOG_COLLECTION_DIR}/system"
        "${LOG_COLLECTION_DIR}/archived"
    )
    
    for dir in "${directories[@]}"; do
        if [[ ! -d "${dir}" ]]; then
            mkdir -p "${dir}"
            log_info "创建日志目录: ${dir}"
        fi
    done
}

# 创建日志收集配置
create_log_collection_config() {
    if [[ ! -f "${LOG_CONFIG_FILE}" ]]; then
        cat > "${LOG_CONFIG_FILE}" << EOF
{
  "enabled": true,
  "collection": {
    "interval": 60,
    "maxLogSize": "${MAX_LOG_SIZE}",
    "maxLogFiles": ${MAX_LOG_FILES},
    "rotationInterval": "${LOG_ROTATION_INTERVAL}",
    "compressionEnabled": true
  },
  "containers": {
    "frontend": {
      "name": "${FRONTEND_CONTAINER_NAME}",
      "enabled": true,
      "logLevel": "info",
      "includeTimestamp": true,
      "filters": {
        "exclude": ["debug", "trace"],
        "include": ["error", "warn", "info"]
      }
    },
    "api": {
      "name": "${API_CONTAINER_NAME}",
      "enabled": true,
      "logLevel": "info",
      "includeTimestamp": true,
      "filters": {
        "exclude": ["debug"],
        "include": ["error", "warn", "info"]
      }
    },
    "database": {
      "name": "${DB_CONTAINER_NAME}",
      "enabled": false,
      "logLevel": "warn",
      "includeTimestamp": true,
      "filters": {
        "exclude": ["debug", "info"],
        "include": ["error", "warn"]
      }
    }
  },
  "retention": {
    "days": 30,
    "archiveAfterDays": 7,
    "deleteAfterDays": 90
  },
  "alerts": {
    "errorThreshold": 10,
    "warningThreshold": 50,
    "checkInterval": 300
  }
}
EOF
        log_info "创建日志收集配置文件: ${LOG_CONFIG_FILE}"
    fi
}

# 获取容器日志
collect_container_logs() {
    local container_name="$1"
    local service_name="$2"
    local log_file="$3"
    local since="${4:-1h}"
    
    log_debug "收集容器日志: ${container_name} -> ${log_file}"
    
    # 检查容器是否存在和运行
    if ! docker ps --format "table {{.Names}}" | grep -q "^${container_name}$"; then
        log_warning "容器 ${container_name} 未运行，跳过日志收集"
        return 1
    fi
    
    # 创建日志文件目录
    local log_dir
    log_dir=$(dirname "${log_file}")
    if [[ ! -d "${log_dir}" ]]; then
        mkdir -p "${log_dir}"
    fi
    
    # 收集日志
    local temp_log_file
    temp_log_file=$(mktemp)
    
    if docker logs --since="${since}" --timestamps "${container_name}" > "${temp_log_file}" 2>&1; then
        # 添加收集时间戳
        {
            echo "=== 日志收集时间: $(date -u +"%Y-%m-%dT%H:%M:%SZ") ==="
            echo "=== 容器: ${container_name} ==="
            echo "=== 服务: ${service_name} ==="
            echo ""
            cat "${temp_log_file}"
            echo ""
            echo "=== 日志收集结束 ==="
        } >> "${log_file}"
        
        log_success "收集容器 ${container_name} 日志完成"
        rm -f "${temp_log_file}"
        return 0
    else
        log_error "收集容器 ${container_name} 日志失败"
        rm -f "${temp_log_file}"
        return 1
    fi
}

# 收集所有容器日志
collect_all_container_logs() {
    local since="${1:-1h}"
    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)
    
    log_info "开始收集所有容器日志 (since: ${since})"
    
    # 检查配置文件
    if [[ ! -f "${LOG_CONFIG_FILE}" ]]; then
        log_warning "日志收集配置文件不存在，使用默认配置"
        create_log_collection_config
    fi
    
    local collected_count=0
    
    # 收集前端容器日志
    if [[ "$(jq -r '.containers.frontend.enabled // false' "${LOG_CONFIG_FILE}")" == "true" ]]; then
        local frontend_container
        frontend_container=$(jq -r '.containers.frontend.name' "${LOG_CONFIG_FILE}")
        local frontend_log_file="${LOG_COLLECTION_DIR}/frontend/frontend-${timestamp}.log"
        
        if collect_container_logs "${frontend_container}" "frontend" "${frontend_log_file}" "${since}"; then
            ((collected_count++))
        fi
    fi
    
    # 收集API容器日志
    if [[ "$(jq -r '.containers.api.enabled // false' "${LOG_CONFIG_FILE}")" == "true" ]]; then
        local api_container
        api_container=$(jq -r '.containers.api.name' "${LOG_CONFIG_FILE}")
        local api_log_file="${LOG_COLLECTION_DIR}/api/api-${timestamp}.log"
        
        if collect_container_logs "${api_container}" "api" "${api_log_file}" "${since}"; then
            ((collected_count++))
        fi
    fi
    
    # 收集数据库容器日志
    if [[ "$(jq -r '.containers.database.enabled // false' "${LOG_CONFIG_FILE}")" == "true" ]]; then
        local db_container
        db_container=$(jq -r '.containers.database.name' "${LOG_CONFIG_FILE}")
        local db_log_file="${LOG_COLLECTION_DIR}/database/database-${timestamp}.log"
        
        if collect_container_logs "${db_container}" "database" "${db_log_file}" "${since}"; then
            ((collected_count++))
        fi
    fi
    
    log_success "日志收集完成，共收集 ${collected_count} 个容器的日志"
}

# 分析容器日志
analyze_container_logs() {
    local service_name="$1"
    local time_range="${2:-1h}"
    
    log_info "分析 ${service_name} 服务日志 (时间范围: ${time_range})"
    
    local log_dir="${LOG_COLLECTION_DIR}/${service_name}"
    
    if [[ ! -d "${log_dir}" ]]; then
        log_warning "日志目录不存在: ${log_dir}"
        return 1
    fi
    
    # 查找最新的日志文件
    local latest_log_file
    latest_log_file=$(find "${log_dir}" -name "*.log" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)
    
    if [[ -z "${latest_log_file}" ]]; then
        log_warning "没有找到 ${service_name} 的日志文件"
        return 1
    fi
    
    log_info "分析日志文件: ${latest_log_file}"
    
    # 统计日志级别
    local error_count warn_count info_count
    error_count=$(grep -c -i "error\|ERROR" "${latest_log_file}" 2>/dev/null || echo "0")
    warn_count=$(grep -c -i "warn\|WARNING" "${latest_log_file}" 2>/dev/null || echo "0")
    info_count=$(grep -c -i "info\|INFO" "${latest_log_file}" 2>/dev/null || echo "0")
    
    log_info "日志统计:"
    log_info "- 错误日志: ${error_count} 条"
    log_info "- 警告日志: ${warn_count} 条"
    log_info "- 信息日志: ${info_count} 条"
    
    # 显示最近的错误
    if [[ "${error_count}" -gt 0 ]]; then
        log_warning "最近的错误日志:"
        grep -i "error\|ERROR" "${latest_log_file}" | tail -5 | while read -r line; do
            log_warning "  ${line}"
        done
    fi
    
    # 检查是否需要告警
    local error_threshold warn_threshold
    error_threshold=$(jq -r '.alerts.errorThreshold // 10' "${LOG_CONFIG_FILE}")
    warn_threshold=$(jq -r '.alerts.warningThreshold // 50' "${LOG_CONFIG_FILE}")
    
    if [[ "${error_count}" -gt "${error_threshold}" ]]; then
        log_error "错误日志数量超过阈值 (${error_count} > ${error_threshold})"
        # 这里可以触发告警
        return 2
    elif [[ "${warn_count}" -gt "${warn_threshold}" ]]; then
        log_warning "警告日志数量超过阈值 (${warn_count} > ${warn_threshold})"
        return 1
    fi
    
    return 0
}

# 轮转日志文件
rotate_logs() {
    local service_name="$1"
    
    log_info "轮转 ${service_name} 服务日志"
    
    local log_dir="${LOG_COLLECTION_DIR}/${service_name}"
    
    if [[ ! -d "${log_dir}" ]]; then
        log_warning "日志目录不存在: ${log_dir}"
        return 1
    fi
    
    # 获取配置
    local max_log_files retention_days
    max_log_files=$(jq -r '.collection.maxLogFiles // 10' "${LOG_CONFIG_FILE}")
    retention_days=$(jq -r '.retention.days // 30' "${LOG_CONFIG_FILE}")
    
    # 删除过期的日志文件
    find "${log_dir}" -name "*.log" -type f -mtime +${retention_days} -delete
    log_info "删除 ${retention_days} 天前的日志文件"
    
    # 保留最新的N个日志文件
    local log_files_count
    log_files_count=$(find "${log_dir}" -name "*.log" -type f | wc -l)
    
    if [[ "${log_files_count}" -gt "${max_log_files}" ]]; then
        local files_to_delete
        files_to_delete=$((log_files_count - max_log_files))
        
        find "${log_dir}" -name "*.log" -type f -printf '%T@ %p\n' | \
            sort -n | \
            head -${files_to_delete} | \
            cut -d' ' -f2- | \
            xargs -r rm -f
        
        log_info "删除多余的日志文件: ${files_to_delete} 个"
    fi
}

# 压缩旧日志
compress_old_logs() {
    local archive_after_days="${1:-7}"
    
    log_info "压缩 ${archive_after_days} 天前的日志文件"
    
    # 查找需要压缩的日志文件
    find "${LOG_COLLECTION_DIR}" -name "*.log" -type f -mtime +${archive_after_days} | while read -r log_file; do
        if [[ -f "${log_file}" ]]; then
            log_debug "压缩日志文件: ${log_file}"
            
            if gzip "${log_file}"; then
                log_success "压缩完成: ${log_file}.gz"
            else
                log_error "压缩失败: ${log_file}"
            fi
        fi
    done
}

# 导出日志
export_logs() {
    local service_name="$1"
    local start_date="$2"
    local end_date="$3"
    local output_file="$4"
    
    log_info "导出 ${service_name} 服务日志 (${start_date} 到 ${end_date})"
    
    local log_dir="${LOG_COLLECTION_DIR}/${service_name}"
    
    if [[ ! -d "${log_dir}" ]]; then
        log_error "日志目录不存在: ${log_dir}"
        return 1
    fi
    
    # 创建输出目录
    local output_dir
    output_dir=$(dirname "${output_file}")
    if [[ ! -d "${output_dir}" ]]; then
        mkdir -p "${output_dir}"
    fi
    
    # 查找指定日期范围内的日志文件
    {
        echo "=== 日志导出报告 ==="
        echo "服务: ${service_name}"
        echo "开始日期: ${start_date}"
        echo "结束日期: ${end_date}"
        echo "导出时间: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
        echo "=== 日志内容 ==="
        echo ""
        
        find "${log_dir}" -name "*.log*" -type f -newermt "${start_date}" ! -newermt "${end_date}" | \
            sort | \
            while read -r log_file; do
                echo "--- 文件: ${log_file} ---"
                if [[ "${log_file}" == *.gz ]]; then
                    zcat "${log_file}"
                else
                    cat "${log_file}"
                fi
                echo ""
            done
    } > "${output_file}"
    
    log_success "日志导出完成: ${output_file}"
}

# 实时监控容器日志
monitor_container_logs() {
    local container_name="$1"
    local filter_pattern="${2:-}"
    
    log_info "开始实时监控容器日志: ${container_name}"
    
    if [[ -n "${filter_pattern}" ]]; then
        log_info "过滤模式: ${filter_pattern}"
    fi
    
    # 检查容器是否运行
    if ! docker ps --format "table {{.Names}}" | grep -q "^${container_name}$"; then
        log_error "容器 ${container_name} 未运行"
        return 1
    fi
    
    # 实时跟踪日志
    if [[ -n "${filter_pattern}" ]]; then
        docker logs -f --timestamps "${container_name}" 2>&1 | grep --line-buffered "${filter_pattern}"
    else
        docker logs -f --timestamps "${container_name}" 2>&1
    fi
}

# 获取日志统计信息
get_log_statistics() {
    log_info "获取日志统计信息"
    
    local stats_file="${LOG_COLLECTION_DIR}/log-statistics.json"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # 统计各服务的日志文件数量和大小
    local frontend_stats api_stats database_stats
    
    frontend_stats=$(get_service_log_stats "frontend")
    api_stats=$(get_service_log_stats "api")
    database_stats=$(get_service_log_stats "database")
    
    # 生成统计报告
    cat > "${stats_file}" << EOF
{
  "timestamp": "${timestamp}",
  "services": {
    "frontend": ${frontend_stats},
    "api": ${api_stats},
    "database": ${database_stats}
  },
  "total": {
    "files": $(find "${LOG_COLLECTION_DIR}" -name "*.log*" -type f | wc -l),
    "size": "$(du -sh "${LOG_COLLECTION_DIR}" | cut -f1)",
    "oldestLog": "$(find "${LOG_COLLECTION_DIR}" -name "*.log*" -type f -printf '%T@ %p\n' | sort -n | head -1 | cut -d' ' -f2- | xargs -r stat -c %y 2>/dev/null || echo 'N/A')",
    "newestLog": "$(find "${LOG_COLLECTION_DIR}" -name "*.log*" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2- | xargs -r stat -c %y 2>/dev/null || echo 'N/A')"
  }
}
EOF
    
    log_success "日志统计信息已保存到: ${stats_file}"
    
    # 显示统计信息
    if command -v jq &> /dev/null; then
        jq . "${stats_file}"
    else
        cat "${stats_file}"
    fi
}

# 获取单个服务的日志统计
get_service_log_stats() {
    local service_name="$1"
    local log_dir="${LOG_COLLECTION_DIR}/${service_name}"
    
    if [[ ! -d "${log_dir}" ]]; then
        echo '{"files": 0, "size": "0", "enabled": false}'
        return
    fi
    
    local file_count size_bytes
    file_count=$(find "${log_dir}" -name "*.log*" -type f | wc -l)
    size_bytes=$(du -sb "${log_dir}" 2>/dev/null | cut -f1 || echo "0")
    
    cat << EOF
{
  "files": ${file_count},
  "size": "$(numfmt --to=iec ${size_bytes})",
  "sizeBytes": ${size_bytes},
  "enabled": true
}
EOF
}

# 初始化日志收集系统
init_log_collection_system() {
    log_info "初始化日志收集系统..."
    
    create_log_directories
    create_log_collection_config
    
    log_success "日志收集系统初始化完成"
}

# 如果直接运行此脚本，执行相应命令
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-help}" in
        "init")
            init_log_collection_system
            ;;
        "collect")
            collect_all_container_logs "${2:-1h}"
            ;;
        "analyze")
            analyze_container_logs "${2:-api}" "${3:-1h}"
            ;;
        "rotate")
            rotate_logs "${2:-api}"
            ;;
        "compress")
            compress_old_logs "${2:-7}"
            ;;
        "export")
            export_logs "${2:-api}" "${3:-yesterday}" "${4:-today}" "${5:-./exported-logs.txt}"
            ;;
        "monitor")
            monitor_container_logs "${2:-guessing-pen-api}" "${3:-}"
            ;;
        "stats")
            get_log_statistics
            ;;
        *)
            cat << EOF
容器日志收集和管理系统

使用方法:
    $0 [命令] [参数]

命令:
    init                                    - 初始化日志收集系统
    collect [时间范围]                      - 收集所有容器日志 (默认: 1h)
    analyze <服务> [时间范围]               - 分析服务日志 (默认: 1h)
    rotate <服务>                          - 轮转服务日志
    compress [天数]                        - 压缩旧日志 (默认: 7天)
    export <服务> <开始日期> <结束日期> [输出文件] - 导出日志
    monitor <容器名> [过滤模式]             - 实时监控容器日志
    stats                                  - 显示日志统计信息
    help                                   - 显示此帮助信息

配置文件:
    ${LOG_CONFIG_FILE}

日志目录:
    ${LOG_COLLECTION_DIR}

示例:
    $0 init                                 # 初始化系统
    $0 collect 2h                          # 收集最近2小时的日志
    $0 analyze api 1d                      # 分析API服务最近1天的日志
    $0 monitor guessing-pen-api ERROR       # 监控API容器的错误日志
    $0 export api 2025-10-01 2025-10-11    # 导出指定日期范围的日志

EOF
            ;;
    esac
fi