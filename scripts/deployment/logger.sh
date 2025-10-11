#!/bin/bash

#==============================================================================
# 脚本名称: logger.sh
# 脚本描述: 部署过程日志记录工具
# 作者: Kiro AI Assistant
# 创建日期: 2025-10-11
# 版本: 1.0.0
#==============================================================================

# 设置严格模式
set -euo pipefail

# 日志配置
readonly LOG_DIR="${PROJECT_ROOT:-$(pwd)}/logs"
readonly LOG_FILE="${LOG_DIR}/deployment-$(date +%Y%m%d-%H%M%S).log"
readonly MAX_LOG_FILES=10

# 颜色定义
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# 创建日志目录
create_log_directory() {
    if [[ ! -d "${LOG_DIR}" ]]; then
        mkdir -p "${LOG_DIR}"
    fi
}

# 清理旧日志文件
cleanup_old_logs() {
    if [[ -d "${LOG_DIR}" ]]; then
        # 保留最新的MAX_LOG_FILES个日志文件
        find "${LOG_DIR}" -name "deployment-*.log" -type f | \
            sort -r | \
            tail -n +$((MAX_LOG_FILES + 1)) | \
            xargs -r rm -f
    fi
}

# 获取时间戳
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# 记录日志到文件
log_to_file() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(get_timestamp)
    
    echo "[${level}] ${timestamp} - ${message}" >> "${LOG_FILE}"
}

# 打印信息日志
log_info() {
    local message="$1"
    local timestamp
    timestamp=$(get_timestamp)
    
    echo -e "${BLUE}[INFO]${NC} ${timestamp} - ${message}"
    log_to_file "INFO" "${message}"
}

# 打印成功日志
log_success() {
    local message="$1"
    local timestamp
    timestamp=$(get_timestamp)
    
    echo -e "${GREEN}[SUCCESS]${NC} ${timestamp} - ${message}"
    log_to_file "SUCCESS" "${message}"
}

# 打印警告日志
log_warning() {
    local message="$1"
    local timestamp
    timestamp=$(get_timestamp)
    
    echo -e "${YELLOW}[WARNING]${NC} ${timestamp} - ${message}"
    log_to_file "WARNING" "${message}"
}

# 打印错误日志
log_error() {
    local message="$1"
    local timestamp
    timestamp=$(get_timestamp)
    
    echo -e "${RED}[ERROR]${NC} ${timestamp} - ${message}"
    log_to_file "ERROR" "${message}"
}

# 打印调试日志
log_debug() {
    local message="$1"
    local timestamp
    timestamp=$(get_timestamp)
    
    if [[ "${DEBUG:-false}" == "true" ]]; then
        echo -e "${PURPLE}[DEBUG]${NC} ${timestamp} - ${message}"
        log_to_file "DEBUG" "${message}"
    fi
}

# 打印步骤开始
log_step_start() {
    local step="$1"
    local message="$2"
    local timestamp
    timestamp=$(get_timestamp)
    
    echo -e "${CYAN}[STEP ${step}]${NC} ${timestamp} - 开始: ${message}"
    log_to_file "STEP_START" "步骤${step}: ${message}"
}

# 打印步骤完成
log_step_end() {
    local step="$1"
    local message="$2"
    local duration="${3:-}"
    local timestamp
    timestamp=$(get_timestamp)
    
    if [[ -n "${duration}" ]]; then
        echo -e "${CYAN}[STEP ${step}]${NC} ${timestamp} - 完成: ${message} (耗时: ${duration}s)"
        log_to_file "STEP_END" "步骤${step}: ${message} (耗时: ${duration}s)"
    else
        echo -e "${CYAN}[STEP ${step}]${NC} ${timestamp} - 完成: ${message}"
        log_to_file "STEP_END" "步骤${step}: ${message}"
    fi
}

# 记录部署开始
log_deployment_start() {
    local version="$1"
    local environment="$2"
    
    create_log_directory
    cleanup_old_logs
    
    log_info "=========================================="
    log_info "开始部署流程"
    log_info "版本: ${version}"
    log_info "环境: ${environment}"
    log_info "日志文件: ${LOG_FILE}"
    log_info "=========================================="
}

# 记录部署结束
log_deployment_end() {
    local status="$1"
    local duration="$2"
    
    log_info "=========================================="
    if [[ "${status}" == "success" ]]; then
        log_success "部署流程完成 (总耗时: ${duration}s)"
    else
        log_error "部署流程失败 (总耗时: ${duration}s)"
    fi
    log_info "日志文件: ${LOG_FILE}"
    log_info "=========================================="
}

# 记录命令执行
log_command() {
    local command="$1"
    local description="${2:-执行命令}"
    
    log_debug "执行命令: ${command}"
    log_info "${description}..."
    
    # 执行命令并记录输出
    if eval "${command}" 2>&1 | tee -a "${LOG_FILE}"; then
        log_success "${description}完成"
        return 0
    else
        log_error "${description}失败"
        return 1
    fi
}

# 记录环境信息
log_environment_info() {
    log_info "环境信息:"
    log_info "- 操作系统: $(uname -s)"
    log_info "- 内核版本: $(uname -r)"
    log_info "- 主机名: $(hostname)"
    log_info "- 用户: $(whoami)"
    log_info "- 工作目录: $(pwd)"
    log_info "- Git分支: $(git branch --show-current 2>/dev/null || echo 'N/A')"
    log_info "- Git提交: $(git rev-parse --short HEAD 2>/dev/null || echo 'N/A')"
    
    if command -v docker &> /dev/null; then
        log_info "- Docker版本: $(docker --version)"
    fi
    
    if command -v node &> /dev/null; then
        log_info "- Node.js版本: $(node --version)"
    fi
}

# 获取当前日志文件路径
get_log_file() {
    echo "${LOG_FILE}"
}

# 获取日志目录路径
get_log_directory() {
    echo "${LOG_DIR}"
}

# 如果直接运行此脚本，显示帮助信息
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    cat << EOF
部署日志记录工具

使用方法:
    source logger.sh

可用函数:
    log_info "信息"          - 记录信息日志
    log_success "成功"       - 记录成功日志
    log_warning "警告"       - 记录警告日志
    log_error "错误"         - 记录错误日志
    log_debug "调试"         - 记录调试日志 (需要设置DEBUG=true)
    
    log_step_start 1 "步骤描述"     - 记录步骤开始
    log_step_end 1 "步骤描述" 30    - 记录步骤结束 (可选耗时)
    
    log_deployment_start "v1.0.0" "production"  - 记录部署开始
    log_deployment_end "success" 120            - 记录部署结束
    
    log_command "ls -la" "列出文件"  - 执行并记录命令
    log_environment_info             - 记录环境信息
    
    get_log_file                     - 获取当前日志文件路径
    get_log_directory                - 获取日志目录路径

环境变量:
    DEBUG=true          - 启用调试日志
    PROJECT_ROOT        - 项目根目录 (默认为当前目录)

EOF
fi