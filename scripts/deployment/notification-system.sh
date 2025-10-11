#!/bin/bash

#==============================================================================
# 脚本名称: notification-system.sh
# 脚本描述: 部署状态通知系统
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

# 通知配置
readonly NOTIFICATION_CONFIG_FILE="${PROJECT_ROOT}/.github/deployment/notification-config.json"
readonly NOTIFICATION_TEMPLATE_DIR="${SCRIPT_DIR}/notification-templates"

# 创建通知配置文件
create_notification_config() {
    local config_dir
    config_dir=$(dirname "${NOTIFICATION_CONFIG_FILE}")
    
    if [[ ! -d "${config_dir}" ]]; then
        mkdir -p "${config_dir}"
    fi
    
    if [[ ! -f "${NOTIFICATION_CONFIG_FILE}" ]]; then
        cat > "${NOTIFICATION_CONFIG_FILE}" << 'EOF'
{
  "enabled": true,
  "channels": {
    "webhook": {
      "enabled": false,
      "url": "",
      "timeout": 30,
      "retries": 3
    },
    "email": {
      "enabled": false,
      "smtp": {
        "host": "",
        "port": 587,
        "secure": false,
        "auth": {
          "user": "",
          "pass": ""
        }
      },
      "from": "",
      "to": []
    },
    "slack": {
      "enabled": false,
      "webhook_url": "",
      "channel": "#deployments",
      "username": "DeployBot"
    },
    "dingtalk": {
      "enabled": false,
      "webhook_url": "",
      "secret": ""
    }
  },
  "events": {
    "deployment_start": true,
    "deployment_success": true,
    "deployment_failure": true,
    "health_check_failure": true,
    "rollback_triggered": true
  },
  "filters": {
    "environments": ["production", "staging"],
    "min_severity": "info"
  }
}
EOF
        log_info "创建通知配置文件: ${NOTIFICATION_CONFIG_FILE}"
    fi
}

# 创建通知模板目录
create_notification_templates() {
    if [[ ! -d "${NOTIFICATION_TEMPLATE_DIR}" ]]; then
        mkdir -p "${NOTIFICATION_TEMPLATE_DIR}"
    fi
    
    # 部署开始模板
    cat > "${NOTIFICATION_TEMPLATE_DIR}/deployment_start.json" << 'EOF'
{
  "title": "🚀 部署开始",
  "message": "开始部署 {{version}} 到 {{environment}} 环境",
  "color": "#0066cc",
  "fields": [
    {
      "name": "版本",
      "value": "{{version}}",
      "inline": true
    },
    {
      "name": "环境",
      "value": "{{environment}}",
      "inline": true
    },
    {
      "name": "分支",
      "value": "{{git_branch}}",
      "inline": true
    },
    {
      "name": "提交",
      "value": "{{git_commit}}",
      "inline": true
    },
    {
      "name": "作者",
      "value": "{{git_author}}",
      "inline": true
    },
    {
      "name": "开始时间",
      "value": "{{start_time}}",
      "inline": true
    }
  ]
}
EOF

    # 部署成功模板
    cat > "${NOTIFICATION_TEMPLATE_DIR}/deployment_success.json" << 'EOF'
{
  "title": "✅ 部署成功",
  "message": "{{version}} 已成功部署到 {{environment}} 环境",
  "color": "#00cc66",
  "fields": [
    {
      "name": "版本",
      "value": "{{version}}",
      "inline": true
    },
    {
      "name": "环境",
      "value": "{{environment}}",
      "inline": true
    },
    {
      "name": "耗时",
      "value": "{{duration}}秒",
      "inline": true
    },
    {
      "name": "完成时间",
      "value": "{{end_time}}",
      "inline": true
    },
    {
      "name": "访问地址",
      "value": "{{app_url}}",
      "inline": false
    }
  ]
}
EOF

    # 部署失败模板
    cat > "${NOTIFICATION_TEMPLATE_DIR}/deployment_failure.json" << 'EOF'
{
  "title": "❌ 部署失败",
  "message": "{{version}} 部署到 {{environment}} 环境失败",
  "color": "#cc0000",
  "fields": [
    {
      "name": "版本",
      "value": "{{version}}",
      "inline": true
    },
    {
      "name": "环境",
      "value": "{{environment}}",
      "inline": true
    },
    {
      "name": "失败步骤",
      "value": "{{failed_step}}",
      "inline": true
    },
    {
      "name": "错误信息",
      "value": "{{error_message}}",
      "inline": false
    },
    {
      "name": "日志文件",
      "value": "{{log_file}}",
      "inline": false
    }
  ]
}
EOF

    # 健康检查失败模板
    cat > "${NOTIFICATION_TEMPLATE_DIR}/health_check_failure.json" << 'EOF'
{
  "title": "⚠️ 健康检查失败",
  "message": "{{environment}} 环境健康检查失败",
  "color": "#ff9900",
  "fields": [
    {
      "name": "环境",
      "value": "{{environment}}",
      "inline": true
    },
    {
      "name": "失败服务",
      "value": "{{failed_services}}",
      "inline": true
    },
    {
      "name": "检查时间",
      "value": "{{check_time}}",
      "inline": true
    },
    {
      "name": "错误详情",
      "value": "{{error_details}}",
      "inline": false
    }
  ]
}
EOF

    log_info "创建通知模板文件"
}

# 渲染模板
render_template() {
    local template_file="$1"
    local variables_json="$2"
    
    if [[ ! -f "${template_file}" ]]; then
        log_error "模板文件不存在: ${template_file}"
        return 1
    fi
    
    local rendered_content
    rendered_content=$(cat "${template_file}")
    
    # 使用jq处理变量替换
    if command -v jq &> /dev/null; then
        # 提取所有变量
        local variables
        variables=$(echo "${variables_json}" | jq -r 'to_entries[] | "\(.key)=\(.value)"')
        
        # 替换模板中的变量
        while IFS='=' read -r key value; do
            rendered_content=$(echo "${rendered_content}" | sed "s/{{${key}}}/${value}/g")
        done <<< "${variables}"
    else
        log_warning "jq未安装，跳过模板渲染"
    fi
    
    echo "${rendered_content}"
}

# 发送Webhook通知
send_webhook_notification() {
    local webhook_url="$1"
    local payload="$2"
    local timeout="${3:-30}"
    local retries="${4:-3}"
    
    log_debug "发送Webhook通知到: ${webhook_url}"
    
    local attempt=1
    while [[ "${attempt}" -le "${retries}" ]]; do
        if curl -s -X POST \
                --connect-timeout "${timeout}" \
                --max-time "${timeout}" \
                -H "Content-Type: application/json" \
                -d "${payload}" \
                "${webhook_url}" > /dev/null 2>&1; then
            log_success "Webhook通知发送成功 (尝试 ${attempt}/${retries})"
            return 0
        else
            log_warning "Webhook通知发送失败 (尝试 ${attempt}/${retries})"
            ((attempt++))
            if [[ "${attempt}" -le "${retries}" ]]; then
                sleep 2
            fi
        fi
    done
    
    log_error "Webhook通知发送失败，已达到最大重试次数"
    return 1
}

# 发送Slack通知
send_slack_notification() {
    local webhook_url="$1"
    local template_content="$2"
    local channel="${3:-#deployments}"
    local username="${4:-DeployBot}"
    
    # 解析模板内容
    local title message color
    title=$(echo "${template_content}" | jq -r '.title // "通知"')
    message=$(echo "${template_content}" | jq -r '.message // ""')
    color=$(echo "${template_content}" | jq -r '.color // "#0066cc"')
    
    # 构建Slack payload
    local slack_payload
    slack_payload=$(cat << EOF
{
  "channel": "${channel}",
  "username": "${username}",
  "attachments": [
    {
      "title": "${title}",
      "text": "${message}",
      "color": "${color}",
      "fields": $(echo "${template_content}" | jq '.fields // []'),
      "footer": "部署系统",
      "ts": $(date +%s)
    }
  ]
}
EOF
)
    
    send_webhook_notification "${webhook_url}" "${slack_payload}"
}

# 发送钉钉通知
send_dingtalk_notification() {
    local webhook_url="$1"
    local template_content="$2"
    local secret="${3:-}"
    
    # 解析模板内容
    local title message
    title=$(echo "${template_content}" | jq -r '.title // "部署通知"')
    message=$(echo "${template_content}" | jq -r '.message // ""')
    
    # 构建钉钉消息
    local dingtalk_text="${title}\n\n${message}"
    
    # 添加字段信息
    if echo "${template_content}" | jq -e '.fields' > /dev/null 2>&1; then
        local fields
        fields=$(echo "${template_content}" | jq -r '.fields[] | "**\(.name)**: \(.value)"')
        dingtalk_text="${dingtalk_text}\n\n${fields}"
    fi
    
    # 构建钉钉payload
    local dingtalk_payload
    dingtalk_payload=$(cat << EOF
{
  "msgtype": "markdown",
  "markdown": {
    "title": "${title}",
    "text": "${dingtalk_text}"
  }
}
EOF
)
    
    # 如果有签名密钥，计算签名
    local final_url="${webhook_url}"
    if [[ -n "${secret}" ]]; then
        local timestamp
        timestamp=$(date +%s%3N)
        local string_to_sign="${timestamp}\n${secret}"
        local signature
        signature=$(echo -n "${string_to_sign}" | openssl dgst -sha256 -hmac "${secret}" -binary | base64)
        final_url="${webhook_url}&timestamp=${timestamp}&sign=${signature}"
    fi
    
    send_webhook_notification "${final_url}" "${dingtalk_payload}"
}

# 发送通知
send_notification() {
    local event_type="$1"
    local variables_json="$2"
    
    log_info "发送通知: ${event_type}"
    
    # 检查通知配置
    if [[ ! -f "${NOTIFICATION_CONFIG_FILE}" ]]; then
        log_warning "通知配置文件不存在，跳过通知"
        return 0
    fi
    
    # 检查通知是否启用
    local notification_enabled
    notification_enabled=$(jq -r '.enabled // false' "${NOTIFICATION_CONFIG_FILE}")
    
    if [[ "${notification_enabled}" != "true" ]]; then
        log_info "通知功能已禁用，跳过通知"
        return 0
    fi
    
    # 检查事件是否启用
    local event_enabled
    event_enabled=$(jq -r ".events.${event_type} // false" "${NOTIFICATION_CONFIG_FILE}")
    
    if [[ "${event_enabled}" != "true" ]]; then
        log_info "事件 ${event_type} 通知已禁用，跳过通知"
        return 0
    fi
    
    # 渲染模板
    local template_file="${NOTIFICATION_TEMPLATE_DIR}/${event_type}.json"
    local rendered_template
    
    if [[ -f "${template_file}" ]]; then
        rendered_template=$(render_template "${template_file}" "${variables_json}")
    else
        log_warning "模板文件不存在: ${template_file}"
        # 使用默认模板
        rendered_template=$(cat << EOF
{
  "title": "部署通知",
  "message": "事件: ${event_type}",
  "color": "#0066cc"
}
EOF
)
    fi
    
    # 发送到各个通道
    local channels_sent=0
    
    # Webhook通知
    local webhook_enabled webhook_url
    webhook_enabled=$(jq -r '.channels.webhook.enabled // false' "${NOTIFICATION_CONFIG_FILE}")
    webhook_url=$(jq -r '.channels.webhook.url // ""' "${NOTIFICATION_CONFIG_FILE}")
    
    if [[ "${webhook_enabled}" == "true" && -n "${webhook_url}" ]]; then
        if send_webhook_notification "${webhook_url}" "${rendered_template}"; then
            ((channels_sent++))
        fi
    fi
    
    # Slack通知
    local slack_enabled slack_webhook_url slack_channel slack_username
    slack_enabled=$(jq -r '.channels.slack.enabled // false' "${NOTIFICATION_CONFIG_FILE}")
    slack_webhook_url=$(jq -r '.channels.slack.webhook_url // ""' "${NOTIFICATION_CONFIG_FILE}")
    slack_channel=$(jq -r '.channels.slack.channel // "#deployments"' "${NOTIFICATION_CONFIG_FILE}")
    slack_username=$(jq -r '.channels.slack.username // "DeployBot"' "${NOTIFICATION_CONFIG_FILE}")
    
    if [[ "${slack_enabled}" == "true" && -n "${slack_webhook_url}" ]]; then
        if send_slack_notification "${slack_webhook_url}" "${rendered_template}" "${slack_channel}" "${slack_username}"; then
            ((channels_sent++))
        fi
    fi
    
    # 钉钉通知
    local dingtalk_enabled dingtalk_webhook_url dingtalk_secret
    dingtalk_enabled=$(jq -r '.channels.dingtalk.enabled // false' "${NOTIFICATION_CONFIG_FILE}")
    dingtalk_webhook_url=$(jq -r '.channels.dingtalk.webhook_url // ""' "${NOTIFICATION_CONFIG_FILE}")
    dingtalk_secret=$(jq -r '.channels.dingtalk.secret // ""' "${NOTIFICATION_CONFIG_FILE}")
    
    if [[ "${dingtalk_enabled}" == "true" && -n "${dingtalk_webhook_url}" ]]; then
        if send_dingtalk_notification "${dingtalk_webhook_url}" "${rendered_template}" "${dingtalk_secret}"; then
            ((channels_sent++))
        fi
    fi
    
    if [[ "${channels_sent}" -gt 0 ]]; then
        log_success "通知已发送到 ${channels_sent} 个通道"
    else
        log_warning "没有可用的通知通道"
    fi
}

# 部署开始通知
notify_deployment_start() {
    local version="$1"
    local environment="$2"
    local git_branch="${3:-unknown}"
    local git_commit="${4:-unknown}"
    local git_author="${5:-unknown}"
    
    local variables
    variables=$(cat << EOF
{
  "version": "${version}",
  "environment": "${environment}",
  "git_branch": "${git_branch}",
  "git_commit": "${git_commit}",
  "git_author": "${git_author}",
  "start_time": "$(date -u +"%Y-%m-%d %H:%M:%S UTC")"
}
EOF
)
    
    send_notification "deployment_start" "${variables}"
}

# 部署成功通知
notify_deployment_success() {
    local version="$1"
    local environment="$2"
    local duration="$3"
    local app_url="${4:-}"
    
    local variables
    variables=$(cat << EOF
{
  "version": "${version}",
  "environment": "${environment}",
  "duration": "${duration}",
  "end_time": "$(date -u +"%Y-%m-%d %H:%M:%S UTC")",
  "app_url": "${app_url}"
}
EOF
)
    
    send_notification "deployment_success" "${variables}"
}

# 部署失败通知
notify_deployment_failure() {
    local version="$1"
    local environment="$2"
    local failed_step="$3"
    local error_message="$4"
    local log_file="${5:-}"
    
    local variables
    variables=$(cat << EOF
{
  "version": "${version}",
  "environment": "${environment}",
  "failed_step": "${failed_step}",
  "error_message": "${error_message}",
  "log_file": "${log_file}"
}
EOF
)
    
    send_notification "deployment_failure" "${variables}"
}

# 健康检查失败通知
notify_health_check_failure() {
    local environment="$1"
    local failed_services="$2"
    local error_details="$3"
    
    local variables
    variables=$(cat << EOF
{
  "environment": "${environment}",
  "failed_services": "${failed_services}",
  "error_details": "${error_details}",
  "check_time": "$(date -u +"%Y-%m-%d %H:%M:%S UTC")"
}
EOF
)
    
    send_notification "health_check_failure" "${variables}"
}

# 初始化通知系统
init_notification_system() {
    log_info "初始化通知系统..."
    
    create_notification_config
    create_notification_templates
    
    log_success "通知系统初始化完成"
}

# 测试通知系统
test_notification_system() {
    log_info "测试通知系统..."
    
    local test_variables
    test_variables=$(cat << EOF
{
  "version": "v1.0.0-test",
  "environment": "test",
  "git_branch": "main",
  "git_commit": "abc123",
  "git_author": "Test User",
  "start_time": "$(date -u +"%Y-%m-%d %H:%M:%S UTC")"
}
EOF
)
    
    send_notification "deployment_start" "${test_variables}"
}

# 如果直接运行此脚本，执行相应命令
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-help}" in
        "init")
            init_notification_system
            ;;
        "test")
            test_notification_system
            ;;
        "start")
            notify_deployment_start "${2:-v1.0.0}" "${3:-production}" "${4:-main}" "${5:-abc123}" "${6:-User}"
            ;;
        "success")
            notify_deployment_success "${2:-v1.0.0}" "${3:-production}" "${4:-120}" "${5:-https://example.com}"
            ;;
        "failure")
            notify_deployment_failure "${2:-v1.0.0}" "${3:-production}" "${4:-build}" "${5:-Build failed}" "${6:-/logs/deploy.log}"
            ;;
        "health")
            notify_health_check_failure "${2:-production}" "${3:-database,api}" "${4:-Connection timeout}"
            ;;
        *)
            cat << EOF
部署通知系统

使用方法:
    $0 [命令] [参数]

命令:
    init                                    - 初始化通知系统
    test                                    - 测试通知系统
    start <版本> <环境> [分支] [提交] [作者]  - 发送部署开始通知
    success <版本> <环境> <耗时> [URL]       - 发送部署成功通知
    failure <版本> <环境> <步骤> <错误> [日志] - 发送部署失败通知
    health <环境> <服务> <错误>              - 发送健康检查失败通知
    help                                    - 显示此帮助信息

配置文件:
    ${NOTIFICATION_CONFIG_FILE}

模板目录:
    ${NOTIFICATION_TEMPLATE_DIR}

示例:
    $0 init                                 # 初始化系统
    $0 test                                 # 测试通知
    $0 start v1.2.0 production main abc123  # 部署开始
    $0 success v1.2.0 production 120        # 部署成功

EOF
            ;;
    esac
fi