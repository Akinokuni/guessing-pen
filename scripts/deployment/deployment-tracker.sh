#!/bin/bash

#==============================================================================
# 脚本名称: deployment-tracker.sh
# 脚本描述: 部署状态跟踪和历史记录
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

# 部署状态文件
readonly DEPLOYMENT_STATE_DIR="${PROJECT_ROOT}/logs/deployments"
readonly DEPLOYMENT_HISTORY_FILE="${DEPLOYMENT_STATE_DIR}/history.json"
readonly CURRENT_DEPLOYMENT_FILE="${DEPLOYMENT_STATE_DIR}/current.json"

# 创建部署状态目录
create_deployment_directory() {
    if [[ ! -d "${DEPLOYMENT_STATE_DIR}" ]]; then
        mkdir -p "${DEPLOYMENT_STATE_DIR}"
        log_info "创建部署状态目录: ${DEPLOYMENT_STATE_DIR}"
    fi
}

# 生成部署ID
generate_deployment_id() {
    echo "deploy-$(date +%Y%m%d-%H%M%S)-$(openssl rand -hex 4 2>/dev/null || echo "$(shuf -i 1000-9999 -n 1)")"
}

# 获取Git信息
get_git_info() {
    local git_branch git_commit git_author git_message
    
    git_branch=$(git branch --show-current 2>/dev/null || echo "unknown")
    git_commit=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
    git_author=$(git log -1 --format='%an <%ae>' 2>/dev/null || echo "unknown")
    git_message=$(git log -1 --format='%s' 2>/dev/null || echo "unknown")
    
    cat << EOF
{
  "branch": "${git_branch}",
  "commit": "${git_commit}",
  "shortCommit": "${git_commit:0:8}",
  "author": "${git_author}",
  "message": "${git_message}"
}
EOF
}

# 开始部署跟踪
start_deployment_tracking() {
    local version="$1"
    local environment="$2"
    local deployment_type="${3:-auto}"
    
    create_deployment_directory
    
    local deployment_id
    deployment_id=$(generate_deployment_id)
    
    local start_time
    start_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    local git_info
    git_info=$(get_git_info)
    
    # 创建当前部署状态
    cat > "${CURRENT_DEPLOYMENT_FILE}" << EOF
{
  "deploymentId": "${deployment_id}",
  "version": "${version}",
  "environment": "${environment}",
  "type": "${deployment_type}",
  "status": "in_progress",
  "startTime": "${start_time}",
  "endTime": null,
  "duration": null,
  "steps": [],
  "git": ${git_info},
  "logFile": "$(get_log_file)",
  "errors": [],
  "warnings": []
}
EOF
    
    log_info "开始部署跟踪: ${deployment_id}"
    log_info "版本: ${version}, 环境: ${environment}"
    
    echo "${deployment_id}"
}

# 更新部署步骤
update_deployment_step() {
    local step_name="$1"
    local step_status="$2"
    local step_message="${3:-}"
    local step_duration="${4:-}"
    
    if [[ ! -f "${CURRENT_DEPLOYMENT_FILE}" ]]; then
        log_error "当前部署状态文件不存在"
        return 1
    fi
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # 创建步骤对象
    local step_object
    step_object=$(cat << EOF
{
  "name": "${step_name}",
  "status": "${step_status}",
  "message": "${step_message}",
  "timestamp": "${timestamp}",
  "duration": ${step_duration:-null}
}
EOF
)
    
    # 使用临时文件更新JSON
    local temp_file
    temp_file=$(mktemp)
    
    if command -v jq &> /dev/null; then
        jq --argjson step "${step_object}" '.steps += [$step]' "${CURRENT_DEPLOYMENT_FILE}" > "${temp_file}"
        mv "${temp_file}" "${CURRENT_DEPLOYMENT_FILE}"
    else
        # 如果没有jq，使用简单的文本替换
        sed -i 's/"steps": \[\]/"steps": ['"${step_object}"']/' "${CURRENT_DEPLOYMENT_FILE}"
        sed -i 's/"steps": \[\(.*\)\]/"steps": [\1,'"${step_object}"']/' "${CURRENT_DEPLOYMENT_FILE}"
    fi
    
    log_debug "更新部署步骤: ${step_name} - ${step_status}"
}

# 添加部署错误
add_deployment_error() {
    local error_message="$1"
    local error_step="${2:-unknown}"
    
    if [[ ! -f "${CURRENT_DEPLOYMENT_FILE}" ]]; then
        log_error "当前部署状态文件不存在"
        return 1
    fi
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    local error_object
    error_object=$(cat << EOF
{
  "message": "${error_message}",
  "step": "${error_step}",
  "timestamp": "${timestamp}"
}
EOF
)
    
    # 使用临时文件更新JSON
    local temp_file
    temp_file=$(mktemp)
    
    if command -v jq &> /dev/null; then
        jq --argjson error "${error_object}" '.errors += [$error]' "${CURRENT_DEPLOYMENT_FILE}" > "${temp_file}"
        mv "${temp_file}" "${CURRENT_DEPLOYMENT_FILE}"
    fi
    
    log_debug "添加部署错误: ${error_message}"
}

# 添加部署警告
add_deployment_warning() {
    local warning_message="$1"
    local warning_step="${2:-unknown}"
    
    if [[ ! -f "${CURRENT_DEPLOYMENT_FILE}" ]]; then
        log_error "当前部署状态文件不存在"
        return 1
    fi
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    local warning_object
    warning_object=$(cat << EOF
{
  "message": "${warning_message}",
  "step": "${warning_step}",
  "timestamp": "${timestamp}"
}
EOF
)
    
    # 使用临时文件更新JSON
    local temp_file
    temp_file=$(mktemp)
    
    if command -v jq &> /dev/null; then
        jq --argjson warning "${warning_object}" '.warnings += [$warning]' "${CURRENT_DEPLOYMENT_FILE}" > "${temp_file}"
        mv "${temp_file}" "${CURRENT_DEPLOYMENT_FILE}"
    fi
    
    log_debug "添加部署警告: ${warning_message}"
}

# 完成部署跟踪
finish_deployment_tracking() {
    local final_status="$1"
    local total_duration="$2"
    
    if [[ ! -f "${CURRENT_DEPLOYMENT_FILE}" ]]; then
        log_error "当前部署状态文件不存在"
        return 1
    fi
    
    local end_time
    end_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # 更新部署状态
    local temp_file
    temp_file=$(mktemp)
    
    if command -v jq &> /dev/null; then
        jq --arg status "${final_status}" \
           --arg endTime "${end_time}" \
           --arg duration "${total_duration}" \
           '.status = $status | .endTime = $endTime | .duration = ($duration | tonumber)' \
           "${CURRENT_DEPLOYMENT_FILE}" > "${temp_file}"
        mv "${temp_file}" "${CURRENT_DEPLOYMENT_FILE}"
    else
        # 简单的文本替换
        sed -i "s/\"status\": \"in_progress\"/\"status\": \"${final_status}\"/" "${CURRENT_DEPLOYMENT_FILE}"
        sed -i "s/\"endTime\": null/\"endTime\": \"${end_time}\"/" "${CURRENT_DEPLOYMENT_FILE}"
        sed -i "s/\"duration\": null/\"duration\": ${total_duration}/" "${CURRENT_DEPLOYMENT_FILE}"
    fi
    
    # 添加到历史记录
    add_to_deployment_history
    
    log_info "完成部署跟踪: ${final_status}"
}

# 添加到部署历史
add_to_deployment_history() {
    if [[ ! -f "${CURRENT_DEPLOYMENT_FILE}" ]]; then
        log_error "当前部署状态文件不存在"
        return 1
    fi
    
    # 初始化历史文件
    if [[ ! -f "${DEPLOYMENT_HISTORY_FILE}" ]]; then
        echo '{"deployments": []}' > "${DEPLOYMENT_HISTORY_FILE}"
    fi
    
    # 添加当前部署到历史
    local temp_file
    temp_file=$(mktemp)
    
    if command -v jq &> /dev/null; then
        jq --slurpfile current "${CURRENT_DEPLOYMENT_FILE}" \
           '.deployments += $current' \
           "${DEPLOYMENT_HISTORY_FILE}" > "${temp_file}"
        mv "${temp_file}" "${DEPLOYMENT_HISTORY_FILE}"
    fi
    
    # 保留最近50次部署记录
    if command -v jq &> /dev/null; then
        temp_file=$(mktemp)
        jq '.deployments = (.deployments | sort_by(.startTime) | .[-50:])' \
           "${DEPLOYMENT_HISTORY_FILE}" > "${temp_file}"
        mv "${temp_file}" "${DEPLOYMENT_HISTORY_FILE}"
    fi
    
    log_debug "添加到部署历史记录"
}

# 获取部署状态
get_deployment_status() {
    if [[ -f "${CURRENT_DEPLOYMENT_FILE}" ]]; then
        cat "${CURRENT_DEPLOYMENT_FILE}"
    else
        echo '{"status": "none", "message": "没有正在进行的部署"}'
    fi
}

# 获取部署历史
get_deployment_history() {
    local limit="${1:-10}"
    
    if [[ -f "${DEPLOYMENT_HISTORY_FILE}" ]]; then
        if command -v jq &> /dev/null; then
            jq --arg limit "${limit}" '.deployments | sort_by(.startTime) | reverse | .[:($limit | tonumber)]' "${DEPLOYMENT_HISTORY_FILE}"
        else
            cat "${DEPLOYMENT_HISTORY_FILE}"
        fi
    else
        echo '{"deployments": []}'
    fi
}

# 清理部署状态
cleanup_deployment_state() {
    if [[ -f "${CURRENT_DEPLOYMENT_FILE}" ]]; then
        rm -f "${CURRENT_DEPLOYMENT_FILE}"
        log_info "清理当前部署状态"
    fi
}

# 显示部署统计
show_deployment_stats() {
    if [[ ! -f "${DEPLOYMENT_HISTORY_FILE}" ]]; then
        log_info "没有部署历史记录"
        return
    fi
    
    if command -v jq &> /dev/null; then
        local total_deployments success_deployments failed_deployments avg_duration
        
        total_deployments=$(jq '.deployments | length' "${DEPLOYMENT_HISTORY_FILE}")
        success_deployments=$(jq '.deployments | map(select(.status == "success")) | length' "${DEPLOYMENT_HISTORY_FILE}")
        failed_deployments=$(jq '.deployments | map(select(.status == "failed")) | length' "${DEPLOYMENT_HISTORY_FILE}")
        avg_duration=$(jq '.deployments | map(select(.duration != null)) | map(.duration) | add / length' "${DEPLOYMENT_HISTORY_FILE}" 2>/dev/null || echo "0")
        
        log_info "部署统计信息:"
        log_info "- 总部署次数: ${total_deployments}"
        log_info "- 成功部署: ${success_deployments}"
        log_info "- 失败部署: ${failed_deployments}"
        log_info "- 成功率: $(echo "scale=2; ${success_deployments} * 100 / ${total_deployments}" | bc 2>/dev/null || echo "N/A")%"
        log_info "- 平均耗时: $(printf "%.1f" "${avg_duration}")秒"
    fi
}

# 如果直接运行此脚本，显示帮助信息
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-help}" in
        "status")
            get_deployment_status | jq . 2>/dev/null || cat
            ;;
        "history")
            get_deployment_history "${2:-10}" | jq . 2>/dev/null || cat
            ;;
        "stats")
            show_deployment_stats
            ;;
        "cleanup")
            cleanup_deployment_state
            ;;
        *)
            cat << EOF
部署状态跟踪工具

使用方法:
    $0 [命令]

命令:
    status              - 显示当前部署状态
    history [数量]      - 显示部署历史 (默认10条)
    stats               - 显示部署统计信息
    cleanup             - 清理当前部署状态
    help                - 显示此帮助信息

函数:
    start_deployment_tracking "v1.0.0" "production" "auto"
    update_deployment_step "build" "success" "构建完成" 30
    add_deployment_error "构建失败" "build"
    add_deployment_warning "警告信息" "deploy"
    finish_deployment_tracking "success" 120

EOF
            ;;
    esac
fi