#!/bin/bash

#==============================================================================
# 脚本名称: config-validator.sh
# 脚本描述: 环境配置验证工具
# 作者: DevOps团队
# 创建日期: 2025-10-11
# 版本: 1.0.0
#==============================================================================

set -euo pipefail

# 脚本配置
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly LOG_FILE="${PROJECT_ROOT}/logs/config-validation-$(date +%Y%m%d-%H%M%S).log"

# 颜色定义
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

#==============================================================================
# 日志函数
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
# 配置验证函数
#==============================================================================

validate_required_vars() {
    local environment="$1"
    local errors=0
    
    log_info "验证 ${environment} 环境的必需变量..."
    
    # 根据环境定义必需的变量
    local required_vars=()
    
    case "${environment}" in
        "development")
            required_vars=(
                "NODE_ENV"
                "API_PORT"
                "DB_HOST"
                "DB_USER"
                "DB_PASSWORD"
                "DB_NAME"
            )
            ;;
        "staging"|"production")
            required_vars=(
                "NODE_ENV"
                "API_PORT"
                "DB_HOST"
                "DB_USER"
                "DB_PASSWORD"
                "DB_NAME"
                "JWT_SECRET"
                "SESSION_SECRET"
                "ACR_REGISTRY"
                "ACR_NAMESPACE"
                "SERVER_HOST"
            )
            ;;
        *)
            log_error "未知环境: ${environment}"
            return 1
            ;;
    esac
    
    # 检查每个必需的变量
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            log_error "缺少必需的环境变量: ${var}"
            ((errors++))
        else
            log_success "✓ ${var} 已设置"
        fi
    done
    
    return $errors
}

validate_security_config() {
    local environment="$1"
    local warnings=0
    
    log_info "验证 ${environment} 环境的安全配置..."
    
    # 检查生产环境的安全配置
    if [[ "${environment}" == "production" ]]; then
        # 检查调试模式
        if [[ "${DEBUG:-false}" == "true" ]]; then
            log_warning "生产环境不应启用DEBUG模式"
            ((warnings++))
        fi
        
        # 检查日志级别
        if [[ "${LOG_LEVEL:-info}" == "debug" ]]; then
            log_warning "生产环境不应使用debug日志级别"
            ((warnings++))
        fi
        
        # 检查源码映射
        if [[ "${SOURCE_MAP:-false}" == "true" ]]; then
            log_warning "生产环境不应启用源码映射"
            ((warnings++))
        fi
        
        # 检查HTTPS
        if [[ "${HTTPS_ENABLED:-false}" != "true" ]]; then
            log_warning "生产环境应启用HTTPS"
            ((warnings++))
        fi
        
        # 检查密钥强度
        if [[ -n "${JWT_SECRET:-}" ]]; then
            if [[ ${#JWT_SECRET} -lt 32 ]]; then
                log_warning "JWT_SECRET 长度应至少32个字符"
                ((warnings++))
            fi
            
            if [[ "${JWT_SECRET}" =~ ^(dev_|test_|demo_) ]]; then
                log_error "生产环境不应使用开发/测试密钥"
                ((warnings++))
            fi
        fi
    fi
    
    # 检查数据库SSL
    if [[ "${environment}" != "development" ]]; then
        if [[ "${DB_SSL:-false}" != "true" ]]; then
            log_warning "${environment} 环境应启用数据库SSL连接"
            ((warnings++))
        fi
    fi
    
    return $warnings
}

validate_database_connection() {
    local environment="$1"
    
    log_info "验证 ${environment} 环境的数据库连接..."
    
    # 检查数据库配置
    local db_host="${DB_HOST:-}"
    local db_port="${DB_PORT:-5432}"
    local db_user="${DB_USER:-}"
    local db_name="${DB_NAME:-}"
    
    if [[ -z "${db_host}" || -z "${db_user}" || -z "${db_name}" ]]; then
        log_error "数据库配置不完整"
        return 1
    fi
    
    # 尝试连接数据库（如果有psql命令）
    if command -v psql &> /dev/null; then
        log_info "测试数据库连接..."
        
        # 设置连接超时
        export PGCONNECT_TIMEOUT=10
        
        if PGPASSWORD="${DB_PASSWORD}" psql -h "${db_host}" -p "${db_port}" -U "${db_user}" -d "${db_name}" -c "SELECT 1;" &> /dev/null; then
            log_success "数据库连接成功"
        else
            log_error "数据库连接失败"
            return 1
        fi
    else
        log_warning "未找到psql命令，跳过数据库连接测试"
    fi
    
    return 0
}

validate_docker_config() {
    local environment="$1"
    
    log_info "验证 ${environment} 环境的Docker配置..."
    
    # 检查Docker Compose文件
    local compose_file="docker-compose.${environment}.yml"
    if [[ "${environment}" == "production" ]]; then
        compose_file="docker-compose.prod.yml"
    fi
    
    if [[ ! -f "${PROJECT_ROOT}/${compose_file}" ]]; then
        log_error "Docker Compose文件不存在: ${compose_file}"
        return 1
    fi
    
    # 验证Docker Compose配置
    if command -v docker-compose &> /dev/null; then
        log_info "验证Docker Compose配置..."
        
        if docker-compose -f "${compose_file}" config &> /dev/null; then
            log_success "Docker Compose配置有效"
        else
            log_error "Docker Compose配置无效"
            return 1
        fi
    else
        log_warning "未找到docker-compose命令，跳过配置验证"
    fi
    
    return 0
}

validate_acr_config() {
    local environment="$1"
    
    log_info "验证 ${environment} 环境的ACR配置..."
    
    local acr_registry="${ACR_REGISTRY:-}"
    local acr_namespace="${ACR_NAMESPACE:-}"
    local acr_username="${ACR_USERNAME:-}"
    local acr_password="${ACR_PASSWORD:-}"
    
    if [[ -z "${acr_registry}" || -z "${acr_namespace}" ]]; then
        log_error "ACR配置不完整"
        return 1
    fi
    
    # 测试ACR登录（如果有docker命令）
    if command -v docker &> /dev/null && [[ -n "${acr_username}" && -n "${acr_password}" ]]; then
        log_info "测试ACR登录..."
        
        if echo "${acr_password}" | docker login "${acr_registry}" -u "${acr_username}" --password-stdin &> /dev/null; then
            log_success "ACR登录成功"
            docker logout "${acr_registry}" &> /dev/null
        else
            log_error "ACR登录失败"
            return 1
        fi
    else
        log_warning "跳过ACR登录测试"
    fi
    
    return 0
}

#==============================================================================
# 主验证函数
#==============================================================================

validate_environment() {
    local environment="$1"
    local env_file="${2:-}"
    
    log_info "开始验证 ${environment} 环境配置..."
    
    # 加载环境文件
    if [[ -n "${env_file}" && -f "${env_file}" ]]; then
        log_info "加载环境文件: ${env_file}"
        set -a
        source "${env_file}"
        set +a
    fi
    
    local total_errors=0
    local total_warnings=0
    
    # 执行各项验证
    validate_required_vars "${environment}" || ((total_errors += $?))
    validate_security_config "${environment}" || ((total_warnings += $?))
    validate_database_connection "${environment}" || ((total_errors += $?))
    validate_docker_config "${environment}" || ((total_errors += $?))
    
    # ACR验证（仅对非开发环境）
    if [[ "${environment}" != "development" ]]; then
        validate_acr_config "${environment}" || ((total_errors += $?))
    fi
    
    # 输出验证结果
    echo ""
    log_info "=== 验证结果 ==="
    
    if [[ $total_errors -eq 0 ]]; then
        log_success "✓ 所有必需配置验证通过"
    else
        log_error "✗ 发现 ${total_errors} 个配置错误"
    fi
    
    if [[ $total_warnings -eq 0 ]]; then
        log_success "✓ 未发现安全配置问题"
    else
        log_warning "⚠ 发现 ${total_warnings} 个安全配置警告"
    fi
    
    return $total_errors
}

#==============================================================================
# 主函数
#==============================================================================

show_help() {
    cat << EOF
用法: $0 <environment> [env_file]

参数:
    environment     环境名称 (development|staging|production)
    env_file        环境配置文件路径 (可选)

选项:
    -h, --help      显示此帮助信息

示例:
    $0 development .env.development
    $0 production .env.production
    $0 staging

EOF
}

main() {
    # 创建日志目录
    mkdir -p "$(dirname "${LOG_FILE}")"
    
    local environment="${1:-}"
    local env_file="${2:-}"
    
    case "${environment}" in
        "development"|"staging"|"production")
            validate_environment "${environment}" "${env_file}"
            ;;
        "-h"|"--help"|"")
            show_help
            exit 0
            ;;
        *)
            log_error "无效的环境名称: ${environment}"
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"