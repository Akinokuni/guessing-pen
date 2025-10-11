#!/bin/bash

#==============================================================================
# 脚本名称: docker-build.sh
# 脚本描述: Docker镜像构建脚本，支持多阶段构建和阿里云ACR推送
# 作者: Guessing Pen Team
# 创建日期: 2025-10-11
# 版本: 1.0.0
#==============================================================================

# 设置严格模式
set -euo pipefail

# 脚本配置
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly LOG_FILE="${PROJECT_ROOT}/logs/docker-build-$(date +%Y%m%d-%H%M%S).log"

# 颜色定义
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# 默认配置
DEFAULT_REGISTRY="registry.cn-hangzhou.aliyuncs.com"
DEFAULT_NAMESPACE="guessing-pen"
DEFAULT_VERSION="latest"

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
# Docker构建函数
#==============================================================================

# 环境检查
check_environment() {
    log_info "检查构建环境..."
    
    # 检查必需的命令
    check_command "docker"
    check_command "git"
    
    # 检查必需的文件
    check_file "${PROJECT_ROOT}/Dockerfile"
    check_file "${PROJECT_ROOT}/Dockerfile.api"
    check_file "${PROJECT_ROOT}/package.json"
    
    # 检查Docker服务
    if ! docker info &> /dev/null; then
        log_error "Docker服务未运行，请启动Docker"
    fi
    
    log_success "环境检查完成"
}

# 设置构建变量
setup_build_vars() {
    log_info "设置构建变量..."
    
    # 从环境变量或参数获取配置
    REGISTRY="${ACR_REGISTRY:-${DEFAULT_REGISTRY}}"
    NAMESPACE="${ACR_NAMESPACE:-${DEFAULT_NAMESPACE}}"
    VERSION="${VERSION:-${DEFAULT_VERSION}}"
    
    # 生成构建信息
    BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
    GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
    
    # 如果是main分支，使用commit hash作为版本
    if [[ "${GIT_BRANCH}" == "main" && "${VERSION}" == "latest" ]]; then
        VERSION="main-${GIT_COMMIT}"
    fi
    
    # 设置镜像标签
    FRONTEND_IMAGE="${REGISTRY}/${NAMESPACE}/frontend"
    API_IMAGE="${REGISTRY}/${NAMESPACE}/api"
    
    log_info "构建配置:"
    log_info "- 镜像仓库: ${REGISTRY}"
    log_info "- 命名空间: ${NAMESPACE}"
    log_info "- 版本标签: ${VERSION}"
    log_info "- 构建时间: ${BUILD_DATE}"
    log_info "- Git提交: ${GIT_COMMIT}"
    log_info "- Git分支: ${GIT_BRANCH}"
}

# 构建前端镜像
build_frontend() {
    log_info "构建前端镜像..."
    
    docker build \
        --file "${PROJECT_ROOT}/Dockerfile" \
        --target production \
        --build-arg BUILD_DATE="${BUILD_DATE}" \
        --build-arg VERSION="${VERSION}" \
        --build-arg GIT_COMMIT="${GIT_COMMIT}" \
        --tag "${FRONTEND_IMAGE}:${VERSION}" \
        --tag "${FRONTEND_IMAGE}:latest" \
        "${PROJECT_ROOT}"
    
    log_success "前端镜像构建完成: ${FRONTEND_IMAGE}:${VERSION}"
}

# 构建API镜像
build_api() {
    log_info "构建API镜像..."
    
    docker build \
        --file "${PROJECT_ROOT}/Dockerfile.api" \
        --target production \
        --build-arg BUILD_DATE="${BUILD_DATE}" \
        --build-arg VERSION="${VERSION}" \
        --build-arg GIT_COMMIT="${GIT_COMMIT}" \
        --tag "${API_IMAGE}:${VERSION}" \
        --tag "${API_IMAGE}:latest" \
        "${PROJECT_ROOT}"
    
    log_success "API镜像构建完成: ${API_IMAGE}:${VERSION}"
}

# 推送镜像到ACR
push_images() {
    if [[ "${PUSH_TO_ACR:-false}" == "true" ]]; then
        log_info "推送镜像到阿里云ACR..."
        
        # 检查是否已登录
        if ! docker info | grep -q "Username:"; then
            log_warning "未检测到Docker登录信息"
            confirm_action "是否需要登录到阿里云ACR? (需要提供用户名和密码)"
            
            read -p "ACR用户名: " ACR_USERNAME
            read -s -p "ACR密码: " ACR_PASSWORD
            echo
            
            echo "${ACR_PASSWORD}" | docker login "${REGISTRY}" --username "${ACR_USERNAME}" --password-stdin
        fi
        
        # 推送前端镜像
        log_info "推送前端镜像..."
        docker push "${FRONTEND_IMAGE}:${VERSION}"
        docker push "${FRONTEND_IMAGE}:latest"
        
        # 推送API镜像
        log_info "推送API镜像..."
        docker push "${API_IMAGE}:${VERSION}"
        docker push "${API_IMAGE}:latest"
        
        log_success "镜像推送完成"
    else
        log_info "跳过镜像推送 (PUSH_TO_ACR=false)"
    fi
}

# 清理构建缓存
cleanup_build() {
    if [[ "${CLEANUP_AFTER_BUILD:-false}" == "true" ]]; then
        log_info "清理Docker构建缓存..."
        docker builder prune -f
        log_success "构建缓存清理完成"
    fi
}

# 显示构建结果
show_build_info() {
    log_success "Docker镜像构建完成！"
    echo
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📦 构建的镜像:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🌐 前端镜像: ${FRONTEND_IMAGE}:${VERSION}"
    echo "🔧 API镜像:  ${API_IMAGE}:${VERSION}"
    echo
    echo "📋 镜像信息:"
    docker images | grep -E "(${NAMESPACE}/frontend|${NAMESPACE}/api)" | head -10
    echo
    echo "🚀 使用方法:"
    echo "  本地运行: docker-compose -f docker-compose.prod.yml up -d"
    echo "  查看日志: docker-compose -f docker-compose.prod.yml logs -f"
    echo "  停止服务: docker-compose -f docker-compose.prod.yml down"
    echo
    echo "📝 日志文件: ${LOG_FILE}"
}

#==============================================================================
# 错误处理
#==============================================================================

cleanup() {
    log_info "执行清理操作..."
    # 在这里添加清理逻辑
}

error_handler() {
    local line_number="$1"
    log_error "脚本在第 ${line_number} 行发生错误"
    cleanup
    exit 1
}

# 设置错误处理
trap 'error_handler ${LINENO}' ERR
trap cleanup EXIT

#==============================================================================
# 主函数
#==============================================================================

main() {
    log_info "开始Docker镜像构建..."
    
    # 创建日志目录
    mkdir -p "$(dirname "${LOG_FILE}")"
    
    # 执行构建步骤
    check_environment
    setup_build_vars
    
    # 确认构建
    if [[ "${SKIP_CONFIRMATION:-false}" != "true" ]]; then
        confirm_action "即将构建Docker镜像，版本: ${VERSION}"
    fi
    
    build_frontend
    build_api
    push_images
    cleanup_build
    show_build_info
    
    log_success "Docker镜像构建脚本执行完成！"
}

# 帮助信息
show_help() {
    cat << EOF
用法: $0 [选项]

选项:
    -h, --help              显示此帮助信息
    -v, --version VERSION   指定镜像版本标签 (默认: latest)
    -r, --registry URL      指定镜像仓库地址 (默认: ${DEFAULT_REGISTRY})
    -n, --namespace NAME    指定命名空间 (默认: ${DEFAULT_NAMESPACE})
    -p, --push              构建后推送到ACR
    -c, --cleanup           构建后清理缓存
    -y, --yes               跳过确认提示
    --verbose               详细输出模式

环境变量:
    ACR_REGISTRY           阿里云ACR仓库地址
    ACR_NAMESPACE          ACR命名空间
    ACR_USERNAME           ACR用户名
    ACR_PASSWORD           ACR密码
    VERSION                镜像版本标签
    PUSH_TO_ACR            是否推送到ACR (true/false)
    CLEANUP_AFTER_BUILD    是否清理构建缓存 (true/false)
    SKIP_CONFIRMATION      是否跳过确认 (true/false)

示例:
    $0                                    # 基本构建
    $0 --version v1.0.0 --push           # 构建并推送指定版本
    $0 --push --cleanup --yes            # 构建、推送并清理，跳过确认
    VERSION=v1.0.0 PUSH_TO_ACR=true $0   # 使用环境变量

EOF
}

# 参数解析
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        -r|--registry)
            REGISTRY="$2"
            shift 2
            ;;
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -p|--push)
            PUSH_TO_ACR=true
            shift
            ;;
        -c|--cleanup)
            CLEANUP_AFTER_BUILD=true
            shift
            ;;
        -y|--yes)
            SKIP_CONFIRMATION=true
            shift
            ;;
        --verbose)
            set -x
            shift
            ;;
        *)
            log_error "未知参数: $1"
            ;;
    esac
done

# 执行主函数
main "$@"