#!/bin/bash

#==============================================================================
# 脚本名称: acr-push.sh
# 脚本描述: 阿里云ACR镜像推送脚本
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
readonly DEFAULT_REGISTRY="crpi-1dj58zvwo0jdkh2y.cn-shenzhen.personal.cr.aliyuncs.com"
readonly DEFAULT_NAMESPACE="guessing-pen"

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
    exit 1
}

#==============================================================================
# 工具函数
#==============================================================================

# 检查命令是否存在
check_command() {
    local cmd="$1"
    if ! command -v "${cmd}" &> /dev/null; then
        log_error "命令 '${cmd}' 未找到，请先安装"
    fi
}

# 检查Docker镜像是否存在
check_image_exists() {
    local image="$1"
    if ! docker image inspect "${image}" &> /dev/null; then
        log_error "Docker镜像不存在: ${image}"
    fi
}

# 获取Git信息
get_git_info() {
    if [[ -d "${PROJECT_ROOT}/.git" ]]; then
        GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
        GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
        GIT_TAG=$(git describe --tags --exact-match 2>/dev/null || echo "")
    else
        GIT_COMMIT="unknown"
        GIT_BRANCH="unknown"
        GIT_TAG=""
    fi
}

# 生成镜像标签
generate_image_tags() {
    local base_name="$1"
    local registry="$2"
    local namespace="$3"
    
    get_git_info
    
    # 基础镜像名
    local image_base="${registry}/${namespace}/${base_name}"
    
    # 生成标签数组
    TAGS=()
    
    # 1. 基于Git提交哈希的标签 (总是生成)
    TAGS+=("${image_base}:${GIT_BRANCH}-${GIT_COMMIT}")
    
    # 2. 如果是main分支，添加latest标签
    if [[ "${GIT_BRANCH}" == "main" ]]; then
        TAGS+=("${image_base}:latest")
    fi
    
    # 3. 如果有Git标签，添加语义化版本标签
    if [[ -n "${GIT_TAG}" ]]; then
        TAGS+=("${image_base}:${GIT_TAG}")
    fi
    
    # 4. 添加时间戳标签
    local timestamp=$(date +%Y%m%d-%H%M%S)
    TAGS+=("${image_base}:${timestamp}")
}

# 添加镜像元数据标签
add_image_metadata() {
    local dockerfile="$1"
    local build_context="$2"
    
    # 构建参数
    BUILD_ARGS=(
        "--build-arg" "BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
        "--build-arg" "GIT_COMMIT=${GIT_COMMIT}"
        "--build-arg" "GIT_BRANCH=${GIT_BRANCH}"
        "--build-arg" "GIT_TAG=${GIT_TAG}"
        "--build-arg" "VERSION=${GIT_TAG:-${GIT_COMMIT}}"
    )
    
    # 标签参数
    LABEL_ARGS=(
        "--label" "org.opencontainers.image.created=$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
        "--label" "org.opencontainers.image.source=https://github.com/your-username/guessing-pen"
        "--label" "org.opencontainers.image.version=${GIT_TAG:-${GIT_COMMIT}}"
        "--label" "org.opencontainers.image.revision=${GIT_COMMIT}"
        "--label" "org.opencontainers.image.title=旮旯画师"
        "--label" "org.opencontainers.image.description=AI艺术鉴别游戏"
    )
}

#==============================================================================
# 镜像构建和推送函数
#==============================================================================

# 登录ACR
login_acr() {
    local registry="$1"
    local username="$2"
    local password="$3"
    
    log_info "登录阿里云ACR: ${registry}"
    
    echo "${password}" | docker login "${registry}" -u "${username}" --password-stdin
    
    log_success "ACR登录成功"
}

# 构建镜像
build_image() {
    local dockerfile="$1"
    local build_context="$2"
    local temp_tag="$3"
    
    log_info "构建Docker镜像: ${temp_tag}"
    
    # 添加元数据
    add_image_metadata "${dockerfile}" "${build_context}"
    
    # 构建镜像
    docker build \
        -f "${dockerfile}" \
        "${BUILD_ARGS[@]}" \
        "${LABEL_ARGS[@]}" \
        -t "${temp_tag}" \
        "${build_context}"
    
    log_success "镜像构建完成: ${temp_tag}"
}

# 标记镜像
tag_image() {
    local source_tag="$1"
    local target_tag="$2"
    
    log_info "标记镜像: ${source_tag} -> ${target_tag}"
    docker tag "${source_tag}" "${target_tag}"
}

# 推送镜像
push_image() {
    local image_tag="$1"
    
    log_info "推送镜像: ${image_tag}"
    
    # 推送镜像，带重试机制
    local max_retries=3
    local retry_count=0
    
    while [[ $retry_count -lt $max_retries ]]; do
        if docker push "${image_tag}"; then
            log_success "镜像推送成功: ${image_tag}"
            return 0
        else
            ((retry_count++))
            log_warning "镜像推送失败，重试 ${retry_count}/${max_retries}"
            sleep 5
        fi
    done
    
    log_error "镜像推送失败，已达到最大重试次数: ${image_tag}"
}

# 构建并推送前端镜像
build_and_push_frontend() {
    local registry="$1"
    local namespace="$2"
    
    log_info "构建并推送前端镜像..."
    
    # 生成标签
    generate_image_tags "guessing-pen-frontend" "${registry}" "${namespace}"
    
    # 临时标签
    local temp_tag="guessing-pen-frontend:build-temp"
    
    # 构建镜像
    build_image "Dockerfile" "${PROJECT_ROOT}" "${temp_tag}"
    
    # 标记并推送所有标签
    for tag in "${TAGS[@]}"; do
        tag_image "${temp_tag}" "${tag}"
        push_image "${tag}"
    done
    
    # 清理临时镜像
    docker rmi "${temp_tag}" || true
    
    log_success "前端镜像推送完成"
}

# 构建并推送API镜像
build_and_push_api() {
    local registry="$1"
    local namespace="$2"
    
    log_info "构建并推送API镜像..."
    
    # 生成标签
    generate_image_tags "guessing-pen-api" "${registry}" "${namespace}"
    
    # 临时标签
    local temp_tag="guessing-pen-api:build-temp"
    
    # 构建镜像
    build_image "Dockerfile.api" "${PROJECT_ROOT}" "${temp_tag}"
    
    # 标记并推送所有标签
    for tag in "${TAGS[@]}"; do
        tag_image "${temp_tag}" "${tag}"
        push_image "${tag}"
    done
    
    # 清理临时镜像
    docker rmi "${temp_tag}" || true
    
    log_success "API镜像推送完成"
}

# 显示推送结果
show_push_results() {
    local registry="$1"
    local namespace="$2"
    
    log_info "推送结果摘要："
    echo ""
    echo "Git信息："
    echo "  分支: ${GIT_BRANCH}"
    echo "  提交: ${GIT_COMMIT}"
    echo "  标签: ${GIT_TAG:-无}"
    echo ""
    echo "推送的镜像："
    
    # 显示前端镜像标签
    generate_image_tags "guessing-pen-frontend" "${registry}" "${namespace}"
    echo "  前端镜像:"
    for tag in "${TAGS[@]}"; do
        echo "    - ${tag}"
    done
    
    # 显示API镜像标签
    generate_image_tags "guessing-pen-api" "${registry}" "${namespace}"
    echo "  API镜像:"
    for tag in "${TAGS[@]}"; do
        echo "    - ${tag}"
    done
}

#==============================================================================
# 主函数
#==============================================================================

main() {
    local registry="${ACR_REGISTRY:-$DEFAULT_REGISTRY}"
    local namespace="${ACR_NAMESPACE:-$DEFAULT_NAMESPACE}"
    local username="${ACR_USERNAME:-}"
    local password="${ACR_PASSWORD:-}"
    local build_target="${BUILD_TARGET:-all}"
    
    log_info "开始推送镜像到阿里云ACR..."
    
    # 检查必需的工具
    check_command "docker"
    check_command "git"
    
    # 检查必需的环境变量
    if [[ -z "${username}" ]] || [[ -z "${password}" ]]; then
        log_error "请设置ACR_USERNAME和ACR_PASSWORD环境变量"
    fi
    
    # 切换到项目根目录
    cd "${PROJECT_ROOT}"
    
    # 登录ACR
    login_acr "${registry}" "${username}" "${password}"
    
    # 根据构建目标执行构建和推送
    case "${build_target}" in
        "frontend")
            build_and_push_frontend "${registry}" "${namespace}"
            ;;
        "api")
            build_and_push_api "${registry}" "${namespace}"
            ;;
        "all"|*)
            build_and_push_frontend "${registry}" "${namespace}"
            build_and_push_api "${registry}" "${namespace}"
            ;;
    esac
    
    # 显示推送结果
    show_push_results "${registry}" "${namespace}"
    
    log_success "镜像推送完成！"
}

# 帮助信息
show_help() {
    cat << EOF
用法: $0 [选项]

选项:
    -h, --help          显示此帮助信息
    -t, --target        构建目标 (frontend|api|all，默认: all)
    --registry          ACR注册表地址 (默认: ${DEFAULT_REGISTRY})
    --namespace         ACR命名空间 (默认: ${DEFAULT_NAMESPACE})

环境变量:
    ACR_REGISTRY       ACR注册表地址
    ACR_NAMESPACE      ACR命名空间
    ACR_USERNAME       ACR用户名 (必需)
    ACR_PASSWORD       ACR密码 (必需)
    BUILD_TARGET       构建目标 (frontend|api|all)

示例:
    $0                              # 构建并推送所有镜像
    $0 --target frontend            # 只构建并推送前端镜像
    $0 --target api                 # 只构建并推送API镜像

EOF
}

# 参数解析
BUILD_TARGET="all"
REGISTRY="${ACR_REGISTRY:-$DEFAULT_REGISTRY}"
NAMESPACE="${ACR_NAMESPACE:-$DEFAULT_NAMESPACE}"

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -t|--target)
            BUILD_TARGET="$2"
            shift 2
            ;;
        --registry)
            REGISTRY="$2"
            shift 2
            ;;
        --namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        *)
            log_error "未知参数: $1"
            ;;
    esac
done

# 执行主函数
ACR_REGISTRY="$REGISTRY" ACR_NAMESPACE="$NAMESPACE" BUILD_TARGET="$BUILD_TARGET" main "$@"