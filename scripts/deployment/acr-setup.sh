#!/bin/bash

#==============================================================================
# 脚本名称: acr-setup.sh
# 脚本描述: 阿里云ACR镜像仓库设置脚本
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

# 阿里云ACR配置
readonly DEFAULT_REGISTRY="registry.cn-hangzhou.aliyuncs.com"
readonly DEFAULT_NAMESPACE="guessing-pen"

#==============================================================================
# 日志和输出函数
#==============================================================================

# 打印信息日志
log_info() {
    local message="$1"
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - ${message}"
}

# 打印成功日志
log_success() {
    local message="$1"
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - ${message}"
}

# 打印警告日志
log_warning() {
    local message="$1"
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - ${message}"
}

# 打印错误日志并退出
log_error() {
    local message="$1"
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - ${message}"
    exit 1
}

#==============================================================================
# 工具函数
#==============================================================================

# 检查命令是否存在
check_command() {
    local cmd="$1"
    if ! command -v "${cmd}" &> /dev/null; then
        log_error "命令 '${cmd}' 未找到，请先安装阿里云CLI工具"
    fi
}

# 确认操作
confirm_action() {
    local message="$1"
    echo -e "${YELLOW}${message}${NC}"
    read -p "是否继续? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "操作已取消"
        exit 0
    fi
}

#==============================================================================
# ACR设置函数
#==============================================================================

# 检查阿里云CLI配置
check_aliyun_cli() {
    log_info "检查阿里云CLI配置..."
    
    check_command "aliyun"
    
    # 检查是否已配置访问密钥
    if ! aliyun configure list &> /dev/null; then
        log_error "阿里云CLI未配置，请先运行 'aliyun configure' 配置访问密钥"
    fi
    
    log_success "阿里云CLI配置检查完成"
}

# 创建ACR命名空间
create_acr_namespace() {
    local registry="${1:-$DEFAULT_REGISTRY}"
    local namespace="${2:-$DEFAULT_NAMESPACE}"
    
    log_info "创建ACR命名空间: ${namespace}"
    
    # 检查命名空间是否已存在
    if aliyun cr GetNamespace --NamespaceName "${namespace}" &> /dev/null; then
        log_warning "命名空间 '${namespace}' 已存在"
        return 0
    fi
    
    # 创建命名空间
    aliyun cr CreateNamespace \
        --NamespaceName "${namespace}" \
        --AutoCreateRepo true \
        --DefaultRepoType PUBLIC
    
    log_success "命名空间 '${namespace}' 创建成功"
}

# 创建镜像仓库
create_acr_repositories() {
    local namespace="${1:-$DEFAULT_NAMESPACE}"
    
    log_info "创建镜像仓库..."
    
    # 前端镜像仓库
    local frontend_repo="${namespace}/guessing-pen-frontend"
    if ! aliyun cr GetRepo --RepoNamespace "${namespace}" --RepoName "guessing-pen-frontend" &> /dev/null; then
        aliyun cr CreateRepo \
            --RepoNamespace "${namespace}" \
            --RepoName "guessing-pen-frontend" \
            --Summary "旮旯画师前端应用镜像" \
            --Detail "基于React + TypeScript的前端应用Docker镜像" \
            --RepoType PUBLIC
        log_success "前端镜像仓库创建成功: ${frontend_repo}"
    else
        log_warning "前端镜像仓库已存在: ${frontend_repo}"
    fi
    
    # API镜像仓库
    local api_repo="${namespace}/guessing-pen-api"
    if ! aliyun cr GetRepo --RepoNamespace "${namespace}" --RepoName "guessing-pen-api" &> /dev/null; then
        aliyun cr CreateRepo \
            --RepoNamespace "${namespace}" \
            --RepoName "guessing-pen-api" \
            --Summary "旮旯画师API服务镜像" \
            --Detail "基于Node.js + Express的API服务Docker镜像" \
            --RepoType PUBLIC
        log_success "API镜像仓库创建成功: ${api_repo}"
    else
        log_warning "API镜像仓库已存在: ${api_repo}"
    fi
}

# 配置Docker登录凭证
setup_docker_credentials() {
    local registry="${1:-$DEFAULT_REGISTRY}"
    
    log_info "配置Docker登录凭证..."
    
    if [[ -z "${ACR_USERNAME:-}" ]] || [[ -z "${ACR_PASSWORD:-}" ]]; then
        log_warning "未设置ACR_USERNAME或ACR_PASSWORD环境变量"
        log_info "请在GitHub Secrets中配置以下变量："
        echo "  - ACR_USERNAME: 阿里云ACR用户名"
        echo "  - ACR_PASSWORD: 阿里云ACR密码"
        echo "  - ACR_REGISTRY: ${registry}"
        echo "  - ACR_NAMESPACE: ${DEFAULT_NAMESPACE}"
        return 0
    fi
    
    # 测试Docker登录
    echo "${ACR_PASSWORD}" | docker login "${registry}" -u "${ACR_USERNAME}" --password-stdin
    log_success "Docker登录测试成功"
}

# 显示配置信息
show_configuration() {
    local registry="${1:-$DEFAULT_REGISTRY}"
    local namespace="${2:-$DEFAULT_NAMESPACE}"
    
    log_info "ACR配置信息："
    echo "  镜像仓库地址: ${registry}"
    echo "  命名空间: ${namespace}"
    echo "  前端镜像: ${registry}/${namespace}/guessing-pen-frontend"
    echo "  API镜像: ${registry}/${namespace}/guessing-pen-api"
    echo ""
    echo "GitHub Secrets配置："
    echo "  ACR_REGISTRY=${registry}"
    echo "  ACR_NAMESPACE=${namespace}"
    echo "  ACR_USERNAME=<你的阿里云ACR用户名>"
    echo "  ACR_PASSWORD=<你的阿里云ACR密码>"
}

#==============================================================================
# 主函数
#==============================================================================

main() {
    local registry="${ACR_REGISTRY:-$DEFAULT_REGISTRY}"
    local namespace="${ACR_NAMESPACE:-$DEFAULT_NAMESPACE}"
    
    log_info "开始设置阿里云ACR镜像仓库..."
    
    # 确认操作
    confirm_action "即将创建ACR命名空间和镜像仓库，这将在阿里云上创建资源。"
    
    # 执行设置步骤
    check_aliyun_cli
    create_acr_namespace "${registry}" "${namespace}"
    create_acr_repositories "${namespace}"
    setup_docker_credentials "${registry}"
    
    # 显示配置信息
    show_configuration "${registry}" "${namespace}"
    
    log_success "阿里云ACR设置完成！"
}

# 帮助信息
show_help() {
    cat << EOF
用法: $0 [选项]

选项:
    -h, --help          显示此帮助信息
    -r, --registry      指定ACR注册表地址 (默认: ${DEFAULT_REGISTRY})
    -n, --namespace     指定命名空间 (默认: ${DEFAULT_NAMESPACE})
    --dry-run          试运行模式（仅显示配置信息）

环境变量:
    ACR_REGISTRY       ACR注册表地址
    ACR_NAMESPACE      ACR命名空间
    ACR_USERNAME       ACR用户名
    ACR_PASSWORD       ACR密码

示例:
    $0                                    # 使用默认配置
    $0 -n my-namespace                    # 指定命名空间
    $0 --dry-run                         # 试运行模式

EOF
}

# 参数解析
DRY_RUN=false
REGISTRY="${ACR_REGISTRY:-$DEFAULT_REGISTRY}"
NAMESPACE="${ACR_NAMESPACE:-$DEFAULT_NAMESPACE}"

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -r|--registry)
            REGISTRY="$2"
            shift 2
            ;;
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            log_error "未知参数: $1"
            ;;
    esac
done

# 试运行模式
if [[ "$DRY_RUN" == "true" ]]; then
    show_configuration "$REGISTRY" "$NAMESPACE"
    exit 0
fi

# 执行主函数
ACR_REGISTRY="$REGISTRY" ACR_NAMESPACE="$NAMESPACE" main "$@"