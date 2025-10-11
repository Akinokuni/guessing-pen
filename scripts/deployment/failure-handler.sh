#!/bin/bash

#==============================================================================
# 脚本名称: failure-handler.sh
# 脚本描述: 部署失败处理逻辑
# 作者: Kiro AI Assistant
# 创建日期: 2025-10-11
# 版本: 1.0.0
#==============================================================================

# 设置严格模式
set -euo pipefail

# 脚本配置
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly LOG_FILE="${PROJECT_ROOT}/logs/failure-handler-$(date +%Y%m%d-%H%M%S).log"

# 颜色定义
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# 配置变量
FAILURE_TYPE=""
FAILURE_STAGE=""
ERROR_MESSAGE=""
AUTO_ROLLBACK=true
RETRY_COUNT=0
MAX_RETRIES=3

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
# 失败检测函数
#==============================================================================

# 检测构建失败
detect_build_failure() {
    local exit_code="$1"
    local build_log="$2"
    
    if [[ "${exit_code}" -ne 0 ]]; then
        log_error "构建失败，退出码: ${exit_code}"
        
        # 分析构建日志
        if [[ -f "${build_log}" ]]; then
            log_info "分析构建日志..."
            
            if grep -q "npm ERR!" "${build_log}"; then
                ERROR_MESSAGE="NPM依赖安装失败"
            elif grep -q "TypeScript error" "${build_log}"; then
                ERROR_MESSAGE="TypeScript编译错误"
            elif grep -q "ENOSPC" "${build_log}"; then
                ERROR_MESSAGE="磁盘空间不足"
            elif grep -q "ECONNRESET\|ETIMEDOUT" "${build_log}"; then
                ERROR_MESSAGE="网络连接问题"
            else
                ERROR_MESSAGE="未知构建错误"
            fi
        else
            ERROR_MESSAGE="构建失败，无法获取详细信息"
        fi
        
        return 0  # 检测到失败
    fi
    
    return 1  # 没有失败
}

# 检测部署失败
detect_deployment_failure() {
    local exit_code="$1"
    local deploy_log="$2"
    
    if [[ "${exit_code}" -ne 0 ]]; then
        log_error "部署失败，退出码: ${exit_code}"
        
        # 分析部署日志
        if [[ -f "${deploy_log}" ]]; then
            log_info "分析部署日志..."
            
            if grep -q "docker: Error response from daemon" "${deploy_log}"; then
                ERROR_MESSAGE="Docker守护进程错误"
            elif grep -q "pull access denied" "${deploy_log}"; then
                ERROR_MESSAGE="镜像拉取权限被拒绝"
            elif grep -q "network is unreachable" "${deploy_log}"; then
                ERROR_MESSAGE="网络不可达"
            elif grep -q "port is already allocated" "${deploy_log}"; then
                ERROR_MESSAGE="端口已被占用"
            elif grep -q "insufficient memory" "${deploy_log}"; then
                ERROR_MESSAGE="内存不足"
            else
                ERROR_MESSAGE="未知部署错误"
            fi
        else
            ERROR_MESSAGE="部署失败，无法获取详细信息"
        fi
        
        return 0  # 检测到失败
    fi
    
    return 1  # 没有失败
}

# 检测健康检查失败
detect_health_failure() {
    local health_status="$1"
    
    if [[ "${health_status}" != "healthy" ]]; then
        log_error "健康检查失败，状态: ${health_status}"
        
        case "${health_status}" in
            "unhealthy")
                ERROR_MESSAGE="服务健康检查失败"
                ;;
            "timeout")
                ERROR_MESSAGE="健康检查超时"
                ;;
            "connection_refused")
                ERROR_MESSAGE="服务连接被拒绝"
                ;;
            *)
                ERROR_MESSAGE="未知健康检查错误"
                ;;
        esac
        
        return 0  # 检测到失败
    fi
    
    return 1  # 没有失败
}

#==============================================================================
# 失败处理策略
#==============================================================================

# 处理构建失败
handle_build_failure() {
    log_info "处理构建失败..."
    
    case "${ERROR_MESSAGE}" in
        *"NPM依赖安装失败"*)
            log_info "尝试清理NPM缓存并重试..."
            npm cache clean --force
            rm -rf node_modules package-lock.json
            ;;
        *"磁盘空间不足"*)
            log_info "清理Docker镜像和容器..."
            docker system prune -f
            docker image prune -a -f
            ;;
        *"网络连接问题"*)
            log_info "等待网络恢复..."
            sleep 30
            ;;
        *"TypeScript编译错误"*)
            log_error "TypeScript编译错误需要手动修复"
            return 1
            ;;
    esac
    
    return 0
}

# 处理部署失败
handle_deployment_failure() {
    log_info "处理部署失败..."
    
    case "${ERROR_MESSAGE}" in
        *"Docker守护进程错误"*)
            log_info "重启Docker服务..."
            sudo systemctl restart docker
            sleep 10
            ;;
        *"镜像拉取权限被拒绝"*)
            log_info "重新登录镜像仓库..."
            docker login "${ACR_REGISTRY}" -u "${ACR_USERNAME}" -p "${ACR_PASSWORD}"
            ;;
        *"端口已被占用"*)
            log_info "停止占用端口的进程..."
            docker-compose down --remove-orphans
            ;;
        *"内存不足"*)
            log_info "清理系统内存..."
            docker system prune -f
            sync && echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
            ;;
    esac
    
    return 0
}

# 处理健康检查失败
handle_health_failure() {
    log_info "处理健康检查失败..."
    
    case "${ERROR_MESSAGE}" in
        *"服务健康检查失败"*)
            log_info "检查服务日志..."
            docker-compose logs --tail=50
            ;;
        *"健康检查超时"*)
            log_info "延长等待时间..."
            sleep 60
            ;;
        *"服务连接被拒绝"*)
            log_info "检查服务端口和网络配置..."
            docker-compose ps
            ;;
    esac
    
    return 0
}

#==============================================================================
# 重试机制
#==============================================================================

# 执行重试
execute_retry() {
    local command="$1"
    local max_retries="$2"
    local retry_delay="${3:-30}"
    
    local attempt=1
    
    while [[ ${attempt} -le ${max_retries} ]]; do
        log_info "执行重试 ${attempt}/${max_retries}: ${command}"
        
        if eval "${command}"; then
            log_success "重试成功"
            return 0
        else
            log_warning "重试 ${attempt} 失败"
            
            if [[ ${attempt} -lt ${max_retries} ]]; then
                log_info "等待 ${retry_delay} 秒后重试..."
                sleep "${retry_delay}"
            fi
            
            ((attempt++))
        fi
    done
    
    log_error "所有重试都失败了"
    return 1
}

# 智能重试策略
smart_retry() {
    local failure_type="$1"
    
    case "${failure_type}" in
        "build")
            if handle_build_failure; then
                execute_retry "npm run build" 2 60
            else
                return 1
            fi
            ;;
        "deployment")
            if handle_deployment_failure; then
                execute_retry "docker-compose up -d" 3 30
            else
                return 1
            fi
            ;;
        "health")
            if handle_health_failure; then
                execute_retry "bash ${SCRIPT_DIR}/health-monitor.sh" 3 60
            else
                return 1
            fi
            ;;
        *)
            log_error "未知的失败类型: ${failure_type}"
            return 1
            ;;
    esac
}

#==============================================================================
# 自动回滚
#==============================================================================

# 执行自动回滚
execute_auto_rollback() {
    log_info "执行自动回滚..."
    
    if [[ "${AUTO_ROLLBACK}" != "true" ]]; then
        log_info "自动回滚已禁用"
        return 1
    fi
    
    # 检查回滚脚本是否存在
    local rollback_script="${SCRIPT_DIR}/rollback.sh"
    if [[ ! -f "${rollback_script}" ]]; then
        log_error "回滚脚本不存在: ${rollback_script}"
        return 1
    fi
    
    # 执行回滚
    log_info "开始自动回滚到上一个稳定版本..."
    if bash "${rollback_script}" --force; then
        log_success "自动回滚成功"
        return 0
    else
        log_error "自动回滚失败"
        return 1
    fi
}

#==============================================================================
# 通知和报告
#==============================================================================

# 发送失败通知
send_failure_notification() {
    local failure_type="$1"
    local stage="$2"
    local error_msg="$3"
    local retry_attempted="$4"
    local rollback_attempted="$5"
    
    log_info "发送失败通知..."
    
    local message="❌ 部署失败
阶段: ${stage}
类型: ${failure_type}
错误: ${error_msg}
重试: ${retry_attempted}
回滚: ${rollback_attempted}
时间: $(date '+%Y-%m-%d %H:%M:%S')"
    
    # 调用通知系统
    if [[ -f "${SCRIPT_DIR}/notification-system.sh" ]]; then
        bash "${SCRIPT_DIR}/notification-system.sh" \
            --type "deployment_failure" \
            --status "failed" \
            --message "${message}" \
            --stage "${stage}" \
            --error "${error_msg}"
    fi
}

# 生成失败报告
generate_failure_report() {
    local report_file="${PROJECT_ROOT}/logs/failure-report-$(date +%Y%m%d-%H%M%S).json"
    
    log_info "生成失败报告: ${report_file}"
    
    cat > "${report_file}" << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "failure_type": "${FAILURE_TYPE}",
  "failure_stage": "${FAILURE_STAGE}",
  "error_message": "${ERROR_MESSAGE}",
  "retry_count": ${RETRY_COUNT},
  "max_retries": ${MAX_RETRIES},
  "auto_rollback": ${AUTO_ROLLBACK},
  "log_file": "${LOG_FILE}",
  "environment": {
    "hostname": "$(hostname)",
    "user": "$(whoami)",
    "pwd": "$(pwd)",
    "docker_version": "$(docker --version 2>/dev/null || echo 'N/A')",
    "compose_version": "$(docker-compose --version 2>/dev/null || echo 'N/A')"
  }
}
EOF
    
    log_success "失败报告已生成: ${report_file}"
}

#==============================================================================
# 主函数
#==============================================================================

main() {
    local failure_type="$1"
    local stage="$2"
    local exit_code="${3:-1}"
    local log_file="${4:-}"
    
    log_info "开始处理部署失败..."
    
    # 创建日志目录
    mkdir -p "$(dirname "${LOG_FILE}")"
    
    # 设置全局变量
    FAILURE_TYPE="${failure_type}"
    FAILURE_STAGE="${stage}"
    
    # 检测具体失败原因
    case "${failure_type}" in
        "build")
            detect_build_failure "${exit_code}" "${log_file}"
            ;;
        "deployment")
            detect_deployment_failure "${exit_code}" "${log_file}"
            ;;
        "health")
            detect_health_failure "${stage}"
            ;;
        *)
            ERROR_MESSAGE="未知失败类型: ${failure_type}"
            ;;
    esac
    
    log_error "检测到失败: ${ERROR_MESSAGE}"
    
    # 尝试智能重试
    local retry_attempted="false"
    if smart_retry "${failure_type}"; then
        log_success "重试成功，问题已解决"
        retry_attempted="true"
        return 0
    else
        log_warning "重试失败，准备执行回滚"
        retry_attempted="true"
    fi
    
    # 执行自动回滚
    local rollback_attempted="false"
    if execute_auto_rollback; then
        log_success "自动回滚成功"
        rollback_attempted="true"
    else
        log_error "自动回滚失败"
        rollback_attempted="true"
    fi
    
    # 发送通知和生成报告
    send_failure_notification "${failure_type}" "${stage}" "${ERROR_MESSAGE}" "${retry_attempted}" "${rollback_attempted}"
    generate_failure_report
    
    log_error "部署失败处理完成，请检查日志: ${LOG_FILE}"
}

# 显示帮助信息
show_help() {
    cat << EOF
用法: $0 <failure_type> <stage> [exit_code] [log_file]

参数:
    failure_type    失败类型 (build|deployment|health)
    stage          失败阶段描述
    exit_code      退出码 (可选，默认为1)
    log_file       相关日志文件 (可选)

选项:
    -h, --help              显示此帮助信息
    --no-rollback          禁用自动回滚
    --max-retries N        设置最大重试次数 (默认3)

示例:
    $0 build "npm install" 1 /path/to/build.log
    $0 deployment "docker-compose up" 1
    $0 health "unhealthy"

EOF
}

# 参数解析
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        --no-rollback)
            AUTO_ROLLBACK=false
            shift
            ;;
        --max-retries)
            MAX_RETRIES="$2"
            shift 2
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
if [[ $# -lt 2 ]]; then
    log_error "缺少必需参数，使用 --help 查看用法"
fi

# 执行主函数
main "$@"