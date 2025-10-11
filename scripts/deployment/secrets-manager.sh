#!/bin/bash

#==============================================================================
# 脚本名称: secrets-manager.sh
# 脚本描述: 敏感信息管理和加密存储工具
# 作者: DevOps团队
# 创建日期: 2025-10-11
# 版本: 1.0.0
#==============================================================================

set -euo pipefail

# 脚本配置
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly SECRETS_DIR="${PROJECT_ROOT}/.secrets"
readonly LOG_FILE="${PROJECT_ROOT}/logs/secrets-$(date +%Y%m%d-%H%M%S).log"

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
    exit 1
}

#==============================================================================
# 工具函数
#==============================================================================

check_command() {
    local cmd="$1"
    if ! command -v "${cmd}" &> /dev/null; then
        log_error "命令 '${cmd}' 未找到，请先安装"
    fi
}

check_file() {
    local file="$1"
    if [[ ! -f "${file}" ]]; then
        log_error "文件 '${file}' 不存在"
    fi
}

generate_key() {
    local key_file="$1"
    if [[ ! -f "${key_file}" ]]; then
        log_info "生成新的加密密钥..."
        openssl rand -base64 32 > "${key_file}"
        chmod 600 "${key_file}"
        log_success "加密密钥已生成: ${key_file}"
    else
        log_info "使用现有加密密钥: ${key_file}"
    fi
}

#==============================================================================
# 加密解密函数
#==============================================================================

encrypt_file() {
    local input_file="$1"
    local output_file="$2"
    local key_file="$3"
    
    check_file "${input_file}"
    check_file "${key_file}"
    
    log_info "加密文件: ${input_file}"
    
    openssl enc -aes-256-cbc -salt -in "${input_file}" -out "${output_file}" -pass file:"${key_file}"
    
    if [[ $? -eq 0 ]]; then
        log_success "文件加密成功: ${output_file}"
        # 删除原始文件
        rm "${input_file}"
        log_info "原始文件已删除: ${input_file}"
    else
        log_error "文件加密失败"
    fi
}

decrypt_file() {
    local input_file="$1"
    local output_file="$2"
    local key_file="$3"
    
    check_file "${input_file}"
    check_file "${key_file}"
    
    log_info "解密文件: ${input_file}"
    
    openssl enc -aes-256-cbc -d -in "${input_file}" -out "${output_file}" -pass file:"${key_file}"
    
    if [[ $? -eq 0 ]]; then
        log_success "文件解密成功: ${output_file}"
    else
        log_error "文件解密失败"
    fi
}

#==============================================================================
# 环境变量管理
#==============================================================================

encrypt_env_file() {
    local env_file="$1"
    local environment="${2:-production}"
    
    check_file "${env_file}"
    
    # 创建secrets目录
    mkdir -p "${SECRETS_DIR}"
    
    # 生成或使用现有密钥
    local key_file="${SECRETS_DIR}/${environment}.key"
    generate_key "${key_file}"
    
    # 加密环境文件
    local encrypted_file="${SECRETS_DIR}/${environment}.env.enc"
    encrypt_file "${env_file}" "${encrypted_file}" "${key_file}"
    
    log_success "环境文件已加密存储"
}

decrypt_env_file() {
    local environment="${1:-production}"
    local output_file="${2:-.env.${environment}}"
    
    local key_file="${SECRETS_DIR}/${environment}.key"
    local encrypted_file="${SECRETS_DIR}/${environment}.env.enc"
    
    check_file "${key_file}"
    check_file "${encrypted_file}"
    
    decrypt_file "${encrypted_file}" "${output_file}" "${key_file}"
    
    # 设置适当的权限
    chmod 600 "${output_file}"
    
    log_success "环境文件已解密: ${output_file}"
}

#==============================================================================
# GitHub Secrets管理
#==============================================================================

validate_github_secrets() {
    local env_file="$1"
    
    check_file "${env_file}"
    
    log_info "验证GitHub Secrets配置..."
    
    # 必需的secrets列表
    local required_secrets=(
        "ACR_REGISTRY"
        "ACR_NAMESPACE" 
        "ACR_USERNAME"
        "ACR_PASSWORD"
        "SERVER_HOST"
        "SERVER_USER"
        "SERVER_SSH_KEY"
        "DB_HOST"
        "DB_USER"
        "DB_PASSWORD"
        "DB_NAME"
    )
    
    local missing_secrets=()
    
    # 检查每个必需的secret
    for secret in "${required_secrets[@]}"; do
        if ! grep -q "^${secret}=" "${env_file}"; then
            missing_secrets+=("${secret}")
        fi
    done
    
    if [[ ${#missing_secrets[@]} -gt 0 ]]; then
        log_error "缺少以下必需的secrets: ${missing_secrets[*]}"
    else
        log_success "所有必需的secrets都已配置"
    fi
}

generate_github_secrets_script() {
    local env_file="$1"
    local output_script="${2:-github-secrets-setup.sh}"
    
    check_file "${env_file}"
    
    log_info "生成GitHub Secrets设置脚本..."
    
    cat > "${output_script}" << 'EOF'
#!/bin/bash
# GitHub Secrets 自动设置脚本
# 使用 GitHub CLI 批量设置 secrets

set -e

# 检查 GitHub CLI 是否已安装
if ! command -v gh &> /dev/null; then
    echo "错误: GitHub CLI 未安装，请先安装 gh 命令"
    exit 1
fi

# 检查是否已登录
if ! gh auth status &> /dev/null; then
    echo "错误: 请先使用 'gh auth login' 登录 GitHub"
    exit 1
fi

echo "开始设置 GitHub Secrets..."

EOF
    
    # 读取环境文件并生成设置命令
    while IFS='=' read -r key value; do
        # 跳过注释和空行
        if [[ "$key" =~ ^#.*$ ]] || [[ -z "$key" ]]; then
            continue
        fi
        
        # 移除值中的引号
        value=$(echo "$value" | sed 's/^["'\'']//' | sed 's/["'\'']$//')
        
        echo "gh secret set ${key} --body \"${value}\"" >> "${output_script}"
        
    done < "${env_file}"
    
    echo "" >> "${output_script}"
    echo "echo \"GitHub Secrets 设置完成!\"" >> "${output_script}"
    
    chmod +x "${output_script}"
    
    log_success "GitHub Secrets设置脚本已生成: ${output_script}"
}

#==============================================================================
# 安全检查函数
#==============================================================================

security_audit() {
    log_info "执行安全审计..."
    
    local issues=0
    
    # 检查是否有明文密码文件
    log_info "检查明文密码文件..."
    if find "${PROJECT_ROOT}" -name "*.env" -not -path "*/node_modules/*" -not -name "*.template" | head -1 | grep -q .; then
        log_warning "发现明文环境文件，建议加密存储"
        ((issues++))
    fi
    
    # 检查文件权限
    log_info "检查敏感文件权限..."
    if [[ -d "${SECRETS_DIR}" ]]; then
        find "${SECRETS_DIR}" -type f -not -perm 600 | while read -r file; do
            log_warning "文件权限不安全: ${file}"
            ((issues++))
        done
    fi
    
    # 检查Git忽略配置
    log_info "检查Git忽略配置..."
    if [[ -f "${PROJECT_ROOT}/.gitignore" ]]; then
        if ! grep -q "\.env$" "${PROJECT_ROOT}/.gitignore"; then
            log_warning ".gitignore 中缺少 .env 文件忽略规则"
            ((issues++))
        fi
        if ! grep -q "\.secrets/" "${PROJECT_ROOT}/.gitignore"; then
            log_warning ".gitignore 中缺少 .secrets/ 目录忽略规则"
            ((issues++))
        fi
    fi
    
    if [[ $issues -eq 0 ]]; then
        log_success "安全审计通过，未发现问题"
    else
        log_warning "安全审计发现 ${issues} 个问题，请及时处理"
    fi
}

#==============================================================================
# 主函数
#==============================================================================

show_help() {
    cat << EOF
用法: $0 [命令] [选项]

命令:
    encrypt <env_file> [environment]     加密环境文件
    decrypt <environment> [output_file]  解密环境文件
    validate <env_file>                  验证GitHub Secrets配置
    generate-script <env_file> [output]  生成GitHub Secrets设置脚本
    audit                                执行安全审计
    
选项:
    -h, --help      显示此帮助信息

示例:
    $0 encrypt .env.production production
    $0 decrypt production .env.production
    $0 validate .env.production
    $0 generate-script .env.production
    $0 audit

EOF
}

main() {
    # 创建日志目录
    mkdir -p "$(dirname "${LOG_FILE}")"
    
    # 检查必需的命令
    check_command "openssl"
    
    case "${1:-}" in
        encrypt)
            if [[ $# -lt 2 ]]; then
                log_error "encrypt 命令需要环境文件参数"
            fi
            encrypt_env_file "$2" "${3:-production}"
            ;;
        decrypt)
            if [[ $# -lt 2 ]]; then
                log_error "decrypt 命令需要环境名称参数"
            fi
            decrypt_env_file "$2" "${3:-}"
            ;;
        validate)
            if [[ $# -lt 2 ]]; then
                log_error "validate 命令需要环境文件参数"
            fi
            validate_github_secrets "$2"
            ;;
        generate-script)
            if [[ $# -lt 2 ]]; then
                log_error "generate-script 命令需要环境文件参数"
            fi
            generate_github_secrets_script "$2" "${3:-}"
            ;;
        audit)
            security_audit
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "未知命令: ${1:-}，使用 -h 查看帮助"
            ;;
    esac
}

# 执行主函数
main "$@"