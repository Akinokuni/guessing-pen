#!/bin/bash

#==============================================================================
# 脚本名称: alert-system.sh
# 脚本描述: 错误通知和告警系统
# 作者: Kiro AI Assistant
# 创建日期: 2025-10-11
# 版本: 1.0.0
#==============================================================================

# 设置严格模式
set -euo pipefail

# 脚本配置
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly LOG_FILE="${PROJECT_ROOT}/logs/alert-system-$(date +%Y%m%d-%H%M%S).log"
readonly CONFIG_FILE="${SCRIPT_DIR}/alert-config.json"

# 颜色定义
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# 告警配置
ALERT_LEVEL="info"
ALERT_TYPE=""
ALERT_MESSAGE=""
ALERT_TITLE=""
RECIPIENTS=""
WEBHOOK_URL=""
EMAIL_ENABLED=false
WEBHOOK_ENABLED=false
SMS_ENABLED=false

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
}

#==============================================================================
# 配置管理
#==============================================================================

# 加载告警配置
load_alert_config() {
    if [[ -f "${CONFIG_FILE}" ]]; then
        log_info "加载告警配置: ${CONFIG_FILE}"
        
        # 使用jq解析JSON配置
        if command -v jq &> /dev/null; then
            EMAIL_ENABLED=$(jq -r '.email.enabled // false' "${CONFIG_FILE}")
            WEBHOOK_ENABLED=$(jq -r '.webhook.enabled // false' "${CONFIG_FILE}")
            SMS_ENABLED=$(jq -r '.sms.enabled // false' "${CONFIG_FILE}")
            RECIPIENTS=$(jq -r '.email.recipients[]? // empty' "${CONFIG_FILE}" | tr '\n' ',' | sed 's/,$//')
            WEBHOOK_URL=$(jq -r '.webhook.url // ""' "${CONFIG_FILE}")
        else
            log_warning "jq未安装，使用默认配置"
        fi
    else
        log_info "配置文件不存在，创建默认配置"
        create_default_config
    fi
}

# 创建默认配置
create_default_config() {
    cat > "${CONFIG_FILE}" << 'EOF'
{
  "email": {
    "enabled": false,
    "smtp_server": "smtp.example.com",
    "smtp_port": 587,
    "username": "",
    "password": "",
    "from": "noreply@example.com",
    "recipients": [
      "admin@example.com"
    ]
  },
  "webhook": {
    "enabled": false,
    "url": "",
    "timeout": 30,
    "retry_count": 3
  },
  "sms": {
    "enabled": false,
    "provider": "aliyun",
    "access_key": "",
    "access_secret": "",
    "sign_name": "",
    "template_code": "",
    "phone_numbers": []
  },
  "alert_levels": {
    "critical": {
      "email": true,
      "webhook": true,
      "sms": true
    },
    "error": {
      "email": true,
      "webhook": true,
      "sms": false
    },
    "warning": {
      "email": false,
      "webhook": true,
      "sms": false
    },
    "info": {
      "email": false,
      "webhook": false,
      "sms": false
    }
  }
}
EOF
    
    log_success "默认配置已创建: ${CONFIG_FILE}"
}

# 检查告警级别配置
check_alert_level_config() {
    local level="$1"
    
    if [[ ! -f "${CONFIG_FILE}" ]] || ! command -v jq &> /dev/null; then
        return 0
    fi
    
    # 根据告警级别决定发送方式
    local email_for_level=$(jq -r ".alert_levels.${level}.email // false" "${CONFIG_FILE}")
    local webhook_for_level=$(jq -r ".alert_levels.${level}.webhook // false" "${CONFIG_FILE}")
    local sms_for_level=$(jq -r ".alert_levels.${level}.sms // false" "${CONFIG_FILE}")
    
    # 更新全局配置
    if [[ "${email_for_level}" == "true" ]]; then
        EMAIL_ENABLED=true
    fi
    
    if [[ "${webhook_for_level}" == "true" ]]; then
        WEBHOOK_ENABLED=true
    fi
    
    if [[ "${sms_for_level}" == "true" ]]; then
        SMS_ENABLED=true
    fi
}

#==============================================================================
# 邮件通知
#==============================================================================

# 发送邮件通知
send_email_alert() {
    if [[ "${EMAIL_ENABLED}" != "true" ]] || [[ -z "${RECIPIENTS}" ]]; then
        log_info "邮件通知已禁用或无收件人"
        return 0
    fi
    
    log_info "发送邮件通知..."
    
    # 检查邮件发送工具
    local mail_cmd=""
    if command -v mail &> /dev/null; then
        mail_cmd="mail"
    elif command -v sendmail &> /dev/null; then
        mail_cmd="sendmail"
    else
        log_warning "未找到邮件发送工具"
        return 1
    fi
    
    # 构建邮件内容
    local subject="[部署告警] ${ALERT_TITLE}"
    local body="
告警级别: ${ALERT_LEVEL}
告警类型: ${ALERT_TYPE}
告警时间: $(date '+%Y-%m-%d %H:%M:%S')
服务器: $(hostname)
项目: 旮旯画师

告警详情:
${ALERT_MESSAGE}

---
此邮件由自动化部署系统发送
"
    
    # 发送邮件
    IFS=',' read -ra ADDR <<< "${RECIPIENTS}"
    for recipient in "${ADDR[@]}"; do
        if [[ "${mail_cmd}" == "mail" ]]; then
            echo "${body}" | mail -s "${subject}" "${recipient}"
        else
            echo -e "To: ${recipient}\nSubject: ${subject}\n\n${body}" | sendmail "${recipient}"
        fi
        log_info "邮件已发送到: ${recipient}"
    done
    
    log_success "邮件通知发送完成"
}

#==============================================================================
# Webhook通知
#==============================================================================

# 发送Webhook通知
send_webhook_alert() {
    if [[ "${WEBHOOK_ENABLED}" != "true" ]] || [[ -z "${WEBHOOK_URL}" ]]; then
        log_info "Webhook通知已禁用或无URL"
        return 0
    fi
    
    log_info "发送Webhook通知到: ${WEBHOOK_URL}"
    
    # 构建JSON负载
    local payload=$(cat << EOF
{
  "alert_level": "${ALERT_LEVEL}",
  "alert_type": "${ALERT_TYPE}",
  "title": "${ALERT_TITLE}",
  "message": "${ALERT_MESSAGE}",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "hostname": "$(hostname)",
  "project": "guessing-pen",
  "environment": "${NODE_ENV:-production}"
}
EOF
)
    
    # 发送HTTP请求
    local response_code
    response_code=$(curl -s -o /dev/null -w "%{http_code}" \
        -X POST \
        -H "Content-Type: application/json" \
        -d "${payload}" \
        --connect-timeout 10 \
        --max-time 30 \
        "${WEBHOOK_URL}")
    
    if [[ "${response_code}" -ge 200 ]] && [[ "${response_code}" -lt 300 ]]; then
        log_success "Webhook通知发送成功 (HTTP ${response_code})"
    else
        log_error "Webhook通知发送失败 (HTTP ${response_code})"
        return 1
    fi
}

# 发送钉钉通知
send_dingtalk_alert() {
    local dingtalk_url="$1"
    
    if [[ -z "${dingtalk_url}" ]]; then
        return 0
    fi
    
    log_info "发送钉钉通知..."
    
    # 构建钉钉消息格式
    local dingtalk_payload=$(cat << EOF
{
  "msgtype": "markdown",
  "markdown": {
    "title": "${ALERT_TITLE}",
    "text": "## ${ALERT_TITLE}\n\n**告警级别**: ${ALERT_LEVEL}\n\n**告警类型**: ${ALERT_TYPE}\n\n**告警时间**: $(date '+%Y-%m-%d %H:%M:%S')\n\n**服务器**: $(hostname)\n\n**详情**: ${ALERT_MESSAGE}"
  }
}
EOF
)
    
    local response_code
    response_code=$(curl -s -o /dev/null -w "%{http_code}" \
        -X POST \
        -H "Content-Type: application/json" \
        -d "${dingtalk_payload}" \
        "${dingtalk_url}")
    
    if [[ "${response_code}" -eq 200 ]]; then
        log_success "钉钉通知发送成功"
    else
        log_error "钉钉通知发送失败 (HTTP ${response_code})"
    fi
}

# 发送企业微信通知
send_wechat_alert() {
    local wechat_url="$1"
    
    if [[ -z "${wechat_url}" ]]; then
        return 0
    fi
    
    log_info "发送企业微信通知..."
    
    # 构建企业微信消息格式
    local wechat_payload=$(cat << EOF
{
  "msgtype": "markdown",
  "markdown": {
    "content": "## ${ALERT_TITLE}\n**告警级别**: <font color=\"warning\">${ALERT_LEVEL}</font>\n**告警类型**: ${ALERT_TYPE}\n**告警时间**: $(date '+%Y-%m-%d %H:%M:%S')\n**服务器**: $(hostname)\n**详情**: ${ALERT_MESSAGE}"
  }
}
EOF
)
    
    local response_code
    response_code=$(curl -s -o /dev/null -w "%{http_code}" \
        -X POST \
        -H "Content-Type: application/json" \
        -d "${wechat_payload}" \
        "${wechat_url}")
    
    if [[ "${response_code}" -eq 200 ]]; then
        log_success "企业微信通知发送成功"
    else
        log_error "企业微信通知发送失败 (HTTP ${response_code})"
    fi
}

#==============================================================================
# SMS通知
#==============================================================================

# 发送短信通知
send_sms_alert() {
    if [[ "${SMS_ENABLED}" != "true" ]]; then
        log_info "短信通知已禁用"
        return 0
    fi
    
    log_info "发送短信通知..."
    
    # 这里可以集成阿里云短信服务或其他SMS提供商
    # 由于需要具体的API密钥，这里只是示例
    log_warning "短信通知功能需要配置SMS提供商API"
    
    return 0
}

#==============================================================================
# 告警历史记录
#==============================================================================

# 记录告警历史
record_alert_history() {
    local history_file="${PROJECT_ROOT}/logs/alert-history.json"
    
    # 创建告警记录
    local alert_record=$(cat << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "level": "${ALERT_LEVEL}",
  "type": "${ALERT_TYPE}",
  "title": "${ALERT_TITLE}",
  "message": "${ALERT_MESSAGE}",
  "hostname": "$(hostname)",
  "project": "guessing-pen",
  "environment": "${NODE_ENV:-production}",
  "notifications": {
    "email": ${EMAIL_ENABLED},
    "webhook": ${WEBHOOK_ENABLED},
    "sms": ${SMS_ENABLED}
  }
}
EOF
)
    
    # 追加到历史文件
    if [[ -f "${history_file}" ]]; then
        # 如果文件存在，添加到数组中
        local temp_file=$(mktemp)
        jq ". += [${alert_record}]" "${history_file}" > "${temp_file}" && mv "${temp_file}" "${history_file}"
    else
        # 如果文件不存在，创建新数组
        echo "[${alert_record}]" > "${history_file}"
    fi
    
    log_info "告警记录已保存到: ${history_file}"
}

# 清理历史记录
cleanup_alert_history() {
    local history_file="${PROJECT_ROOT}/logs/alert-history.json"
    local days_to_keep="${1:-30}"
    
    if [[ ! -f "${history_file}" ]] || ! command -v jq &> /dev/null; then
        return 0
    fi
    
    log_info "清理 ${days_to_keep} 天前的告警记录..."
    
    local cutoff_date=$(date -d "${days_to_keep} days ago" -u +%Y-%m-%dT%H:%M:%SZ)
    local temp_file=$(mktemp)
    
    jq "[.[] | select(.timestamp >= \"${cutoff_date}\")]" "${history_file}" > "${temp_file}" && mv "${temp_file}" "${history_file}"
    
    log_success "历史记录清理完成"
}

#==============================================================================
# 主要告警函数
#==============================================================================

# 发送告警
send_alert() {
    local level="$1"
    local type="$2"
    local title="$3"
    local message="$4"
    
    # 设置全局变量
    ALERT_LEVEL="${level}"
    ALERT_TYPE="${type}"
    ALERT_TITLE="${title}"
    ALERT_MESSAGE="${message}"
    
    log_info "发送告警: [${level}] ${title}"
    
    # 加载配置
    load_alert_config
    check_alert_level_config "${level}"
    
    # 记录告警历史
    record_alert_history
    
    # 发送各种类型的通知
    local success_count=0
    local total_count=0
    
    if [[ "${EMAIL_ENABLED}" == "true" ]]; then
        ((total_count++))
        if send_email_alert; then
            ((success_count++))
        fi
    fi
    
    if [[ "${WEBHOOK_ENABLED}" == "true" ]]; then
        ((total_count++))
        if send_webhook_alert; then
            ((success_count++))
        fi
        
        # 检查特殊的Webhook URL
        if [[ "${WEBHOOK_URL}" =~ dingtalk ]]; then
            send_dingtalk_alert "${WEBHOOK_URL}"
        elif [[ "${WEBHOOK_URL}" =~ qyapi.weixin.qq.com ]]; then
            send_wechat_alert "${WEBHOOK_URL}"
        fi
    fi
    
    if [[ "${SMS_ENABLED}" == "true" ]]; then
        ((total_count++))
        if send_sms_alert; then
            ((success_count++))
        fi
    fi
    
    # 报告发送结果
    if [[ ${total_count} -eq 0 ]]; then
        log_warning "没有启用任何通知方式"
    elif [[ ${success_count} -eq ${total_count} ]]; then
        log_success "所有通知发送成功 (${success_count}/${total_count})"
    else
        log_warning "部分通知发送失败 (${success_count}/${total_count})"
    fi
}

# 快捷告警函数
send_critical_alert() {
    send_alert "critical" "$1" "$2" "$3"
}

send_error_alert() {
    send_alert "error" "$1" "$2" "$3"
}

send_warning_alert() {
    send_alert "warning" "$1" "$2" "$3"
}

send_info_alert() {
    send_alert "info" "$1" "$2" "$3"
}

#==============================================================================
# 主函数
#==============================================================================

main() {
    local level="$1"
    local type="$2"
    local title="$3"
    local message="$4"
    
    # 创建日志目录
    mkdir -p "$(dirname "${LOG_FILE}")"
    
    # 发送告警
    send_alert "${level}" "${type}" "${title}" "${message}"
    
    log_info "告警处理完成，日志文件: ${LOG_FILE}"
}

# 显示帮助信息
show_help() {
    cat << EOF
用法: $0 <level> <type> <title> <message>

参数:
    level       告警级别 (critical|error|warning|info)
    type        告警类型 (deployment|health|security|system)
    title       告警标题
    message     告警详细信息

选项:
    -h, --help              显示此帮助信息
    -c, --config FILE       指定配置文件
    --cleanup DAYS          清理历史记录 (保留指定天数)
    --test                  测试通知配置

示例:
    $0 error deployment "部署失败" "Docker容器启动失败"
    $0 critical health "服务不可用" "API健康检查失败"
    $0 warning system "磁盘空间不足" "可用空间低于10%"

EOF
}

# 测试通知配置
test_notifications() {
    log_info "测试通知配置..."
    
    send_alert "info" "test" "通知测试" "这是一条测试消息，用于验证通知配置是否正常工作。"
    
    log_success "通知测试完成"
}

# 参数解析
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -c|--config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        --cleanup)
            cleanup_alert_history "$2"
            exit 0
            ;;
        --test)
            test_notifications
            exit 0
            ;;
        -*)
            log_error "未知选项: $1"
            ;;
        *)
            break
            ;;
    esac
done

# 检查必需参数
if [[ $# -lt 4 ]]; then
    log_error "缺少必需参数，使用 --help 查看用法"
fi

# 执行主函数
main "$@"