#!/bin/bash

#==============================================================================
# 脚本名称: acr-config-validator.sh
# 脚本描述: 阿里云ACR配置验证脚本
# 作者: Kiro AI Assistant
# 创建日期: 2025-10-11
# 版本: 1.0.0
#==============================================================================

# 设置严格模式
set -euo pipefail

# 脚本配置
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# 颜色定义
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# 默认配置
readonly EXPECTED_REGISTRY="crpi-1dj58zvwo0jdkh2y.cn-shenzhen.personal.cr.aliyuncs.com"
readonly EXPECTED_NAMESPACE="guessing-pen"

#==============================================================================
# 日志和输出函数
#==============================================================================

log_info() {
    local message="$1"
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - ${message}"
}

log_success() {
    local message="$1"
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - ${message}"
}

log_warning() {
    local message="$1"
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - ${message}"
}

log_error() {
    local message="$1"
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - ${message}"
}

#==============================================================================
# 验证函数
#==============================================================================

# 验证环境变量
validate_environment_variables() {
    log_info "验证环境变量配置..."
    
    local errors=0
    
    # 检查必需的环境变量
    local required_vars=(
        "ACR_REGISTRY"
        "ACR_NAMESPACE" 
        "ACR_USERNAME"
        "ACR_PASSWORD"
    )
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            log_error "环境变量 ${var} 未设置"
            ((errors++))
        else
            log_success "环境变量 ${var} 已设置"
        fi
    done
    
    # 验证ACR_REGISTRY值
    if [[ "${ACR_REGISTRY:-}" != "${EXPECTED_REGISTRY}" ]]; then
        log_warning "ACR_REGISTRY (${ACR_REGISTRY:-未设置}) 与期望值不匹配: ${EXPECTED_REGISTRY}"
    fi
    
    # 验证ACR_NAMESPACE值
    if [[ "${ACR_NAMESPACE:-}" != "${EXPECTED_NAMESPACE}" ]]; then
        log_warning "ACR_NAMESPACE (${ACR_NAMESPACE:-未设置}) 与期望值不匹配: ${EXPECTED_NAMESPACE}"
    fi
    
    return $errors
}

# 验证Docker连接
validate_docker_connection() {
    log_info "验证Docker连接..."
    
    # 检查Docker是否运行
    if ! docker info &> /dev/null; then
        log_error "Docker未运行或无法连接"
        return 1
    fi
    
    log_success "Docker连接正常"
    return 0
}

# 验证ACR登录
validate_acr_login() {
    log_info "验证ACR登录..."
    
    local registry="${ACR_REGISTRY:-$EXPECTED_REGISTRY}"
    local username="${ACR_USERNAME:-}"
    local password="${ACR_PASSWORD:-}"
    
    if [[ -z "${username}" ]] || [[ -z "${password}" ]]; then
        log_error "ACR用户名或密码未设置"
        return 1
    fi
    
    # 尝试登录ACR
    if echo "${password}" | docker login "${registry}" -u "${username}" --password-stdin &> /dev/null; then
        log_success "ACR登录验证成功"
        return 0
    else
        log_error "ACR登录验证失败"
        return 1
    fi
}

# 验证镜像仓库访问
validate_repository_access() {
    log_info "验证镜像仓库访问..."
    
    local registry="${ACR_REGISTRY:-$EXPECTED_REGISTRY}"
    local namespace="${ACR_NAMESPACE:-$EXPECTED_NAMESPACE}"
    
    # 尝试拉取一个小的测试镜像来验证访问权限
    local test_image="hello-world:latest"
    local acr_test_image="${registry}/${namespace}/test:latest"
    
    # 拉取测试镜像
    if docker pull "${test_image}" &> /dev/null; then
        log_info "测试镜像拉取成功"
        
        # 标记并尝试推送到ACR（测试推送权限）
        docker tag "${test_image}" "${acr_test_image}"
        
        if docker push "${acr_test_image}" &> /dev/null; then
            log_success "镜像仓库推送权限验证成功"
            
            # 清理测试镜像
            docker rmi "${acr_test_image}" &> /dev/null || true
            docker rmi "${test_image}" &> /dev/null || true
            
            return 0
        else
            log_error "镜像仓库推送权限验证失败"
            return 1
        fi
    else
        log_error "测试镜像拉取失败"
        return 1
    fi
}

# 验证GitHub Actions配置
validate_github_actions_config() {
    log_info "验证GitHub Actions配置..."
    
    local ci_config="${PROJECT_ROOT}/.github/workflows/ci-cd.yml"
    
    if [[ ! -f "${ci_config}" ]]; then
        log_error "GitHub Actions配置文件不存在: ${ci_config}"
        return 1
    fi
    
    # 检查配置文件中的关键配置
    local config_errors=0
    
    # 检查ACR_REGISTRY配置
    if ! grep -q "ACR_REGISTRY.*${EXPECTED_REGISTRY}" "${ci_config}"; then
        log_warning "CI/CD配置中的ACR_REGISTRY可能不正确"
        ((config_errors++))
    fi
    
    # 检查ACR_NAMESPACE配置
    if ! grep -q "ACR_NAMESPACE.*${EXPECTED_NAMESPACE}" "${ci_config}"; then
        log_warning "CI/CD配置中的ACR_NAMESPACE可能不正确"
        ((config_errors++))
    fi
    
    # 检查Docker登录步骤
    if ! grep -q "docker/login-action" "${ci_config}"; then
        log_error "CI/CD配置中缺少Docker登录步骤"
        ((config_errors++))
    fi
    
    if [[ $config_errors -eq 0 ]]; then
        log_success "GitHub Actions配置验证通过"
        return 0
    else
        log_warning "GitHub Actions配置存在 ${config_errors} 个问题"
        return 1
    fi
}

# 验证项目文件
validate_project_files() {
    log_info "验证项目文件..."
    
    local file_errors=0
    
    # 检查Dockerfile
    local dockerfiles=("Dockerfile" "Dockerfile.api")
    for dockerfile in "${dockerfiles[@]}"; do
        if [[ -f "${PROJECT_ROOT}/${dockerfile}" ]]; then
            log_success "找到 ${dockerfile}"
        else
            log_error "缺少 ${dockerfile}"
            ((file_errors++))
        fi
    done
    
    # 检查docker-compose文件
    local compose_files=("docker-compose.yml" "docker-compose.prod.yml")
    for compose_file in "${compose_files[@]}"; do
        if [[ -f "${PROJECT_ROOT}/${compose_file}" ]]; then
            log_success "找到 ${compose_file}"
        else
            log_warning "缺少 ${compose_file}"
        fi
    done
    
    # 检查ACR配置文件
    if [[ -f "${SCRIPT_DIR}/acr-config.json" ]]; then
        log_success "找到ACR配置文件"
    else
        log_warning "缺少ACR配置文件"
    fi
    
    return $file_errors
}

# 生成配置报告
generate_config_report() {
    log_info "生成配置报告..."
    
    local report_file="${PROJECT_ROOT}/acr-config-report.txt"
    
    cat > "${report_file}" << EOF
# 阿里云ACR配置验证报告

生成时间: $(date '+%Y-%m-%d %H:%M:%S')

## 环境变量配置
ACR_REGISTRY: ${ACR_REGISTRY:-未设置}
ACR_NAMESPACE: ${ACR_NAMESPACE:-未设置}
ACR_USERNAME: ${ACR_USERNAME:+已设置}
ACR_PASSWORD: ${ACR_PASSWORD:+已设置}

## 期望配置
期望的注册表: ${EXPECTED_REGISTRY}
期望的命名空间: ${EXPECTED_NAMESPACE}

## 镜像信息
前端镜像: ${ACR_REGISTRY:-$EXPECTED_REGISTRY}/${ACR_NAMESPACE:-$EXPECTED_NAMESPACE}/guessing-pen-frontend
API镜像: ${ACR_REGISTRY:-$EXPECTED_REGISTRY}/${ACR_NAMESPACE:-$EXPECTED_NAMESPACE}/guessing-pen-api

## GitHub Secrets配置建议
请在GitHub仓库的Secrets中配置以下变量:

ACR_REGISTRY=${EXPECTED_REGISTRY}
ACR_NAMESPACE=${EXPECTED_NAMESPACE}
ACR_USERNAME=<你的阿里云ACR用户名>
ACR_PASSWORD=<你的阿里云ACR密码>

## 验证命令
本地验证: bash scripts/deployment/acr-config-validator.sh
Docker登录测试: echo "\$ACR_PASSWORD" | docker login ${EXPECTED_REGISTRY} -u "\$ACR_USERNAME" --password-stdin

EOF
    
    log_success "配置报告已生成: ${report_file}"
}

#==============================================================================
# 主函数
#==============================================================================

main() {
    log_info "开始验证阿里云ACR配置..."
    
    local total_errors=0
    
    # 执行各项验证
    validate_environment_variables || ((total_errors++))
    validate_docker_connection || ((total_errors++))
    validate_acr_login || ((total_errors++))
    validate_repository_access || ((total_errors++))
    validate_github_actions_config || ((total_errors++))
    validate_project_files || ((total_errors++))
    
    # 生成配置报告
    generate_config_report
    
    # 输出验证结果
    echo ""
    if [[ $total_errors -eq 0 ]]; then
        log_success "🎉 所有验证通过！ACR配置正确。"
        echo ""
        echo "你现在可以："
        echo "1. 运行 'bash scripts/deployment/acr-push.sh' 推送镜像"
        echo "2. 触发GitHub Actions进行自动部署"
        echo "3. 查看配置报告: cat acr-config-report.txt"
    else
        log_error "❌ 发现 ${total_errors} 个配置问题，请修复后重试。"
        echo ""
        echo "常见解决方案："
        echo "1. 检查环境变量是否正确设置"
        echo "2. 确认阿里云ACR用户名和密码"
        echo "3. 验证Docker是否正常运行"
        echo "4. 检查网络连接和防火墙设置"
        exit 1
    fi
}

# 帮助信息
show_help() {
    cat << EOF
用法: $0 [选项]

选项:
    -h, --help          显示此帮助信息
    --report-only       只生成配置报告，不执行验证

环境变量:
    ACR_REGISTRY       ACR注册表地址 (期望: ${EXPECTED_REGISTRY})
    ACR_NAMESPACE      ACR命名空间 (期望: ${EXPECTED_NAMESPACE})
    ACR_USERNAME       ACR用户名 (必需)
    ACR_PASSWORD       ACR密码 (必需)

示例:
    $0                  # 执行完整验证
    $0 --report-only    # 只生成配置报告

EOF
}

# 参数解析
REPORT_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        --report-only)
            REPORT_ONLY=true
            shift
            ;;
        *)
            log_error "未知参数: $1"
            ;;
    esac
done

# 如果只生成报告
if [[ "$REPORT_ONLY" == "true" ]]; then
    generate_config_report
    exit 0
fi

# 执行主函数
main "$@"