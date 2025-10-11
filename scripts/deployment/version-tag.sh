#!/bin/bash

#==============================================================================
# 脚本名称: version-tag.sh
# 脚本描述: 语义化版本标签管理脚本
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
# 版本管理函数
#==============================================================================

# 检查Git仓库状态
check_git_status() {
    log_info "检查Git仓库状态..."
    
    if [[ ! -d "${PROJECT_ROOT}/.git" ]]; then
        log_error "当前目录不是Git仓库"
    fi
    
    # 检查是否有未提交的更改
    if ! git diff --quiet || ! git diff --cached --quiet; then
        log_error "存在未提交的更改，请先提交所有更改"
    fi
    
    # 检查是否在main分支
    local current_branch=$(git rev-parse --abbrev-ref HEAD)
    if [[ "${current_branch}" != "main" ]]; then
        log_warning "当前不在main分支 (当前分支: ${current_branch})"
        log_warning "语义化版本标签通常在main分支上创建"
    fi
    
    log_success "Git仓库状态检查完成"
}

# 获取当前版本
get_current_version() {
    # 尝试从Git标签获取最新版本
    local latest_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
    
    if [[ -n "${latest_tag}" ]]; then
        # 验证标签是否符合语义化版本格式
        if [[ "${latest_tag}" =~ ^v?([0-9]+)\.([0-9]+)\.([0-9]+)(-[a-zA-Z0-9.-]+)?(\+[a-zA-Z0-9.-]+)?$ ]]; then
            CURRENT_VERSION="${latest_tag}"
            MAJOR="${BASH_REMATCH[1]}"
            MINOR="${BASH_REMATCH[2]}"
            PATCH="${BASH_REMATCH[3]}"
            PRERELEASE="${BASH_REMATCH[4]}"
            BUILD="${BASH_REMATCH[5]}"
        else
            log_warning "最新标签 '${latest_tag}' 不符合语义化版本格式"
            CURRENT_VERSION=""
            MAJOR=0
            MINOR=0
            PATCH=0
            PRERELEASE=""
            BUILD=""
        fi
    else
        log_info "未找到现有版本标签，将从 v0.1.0 开始"
        CURRENT_VERSION=""
        MAJOR=0
        MINOR=1
        PATCH=0
        PRERELEASE=""
        BUILD=""
    fi
}

# 计算下一个版本
calculate_next_version() {
    local bump_type="$1"
    
    case "${bump_type}" in
        "major")
            MAJOR=$((MAJOR + 1))
            MINOR=0
            PATCH=0
            ;;
        "minor")
            MINOR=$((MINOR + 1))
            PATCH=0
            ;;
        "patch")
            PATCH=$((PATCH + 1))
            ;;
        *)
            log_error "无效的版本类型: ${bump_type} (支持: major, minor, patch)"
            ;;
    esac
    
    NEW_VERSION="v${MAJOR}.${MINOR}.${PATCH}"
}

# 生成版本标签策略
generate_tag_strategy() {
    local version="$1"
    local registry="${2:-registry.cn-hangzhou.aliyuncs.com}"
    local namespace="${3:-guessing-pen}"
    
    # 移除版本号前的 'v' 前缀用于Docker标签
    local clean_version="${version#v}"
    
    # 生成标签策略
    DOCKER_TAGS=(
        # 完整语义化版本
        "${registry}/${namespace}/guessing-pen-frontend:${clean_version}"
        "${registry}/${namespace}/guessing-pen-api:${clean_version}"
        
        # 主版本标签
        "${registry}/${namespace}/guessing-pen-frontend:${MAJOR}"
        "${registry}/${namespace}/guessing-pen-api:${MAJOR}"
        
        # 主.次版本标签
        "${registry}/${namespace}/guessing-pen-frontend:${MAJOR}.${MINOR}"
        "${registry}/${namespace}/guessing-pen-api:${MAJOR}.${MINOR}"
    )
    
    # 如果是稳定版本，添加latest标签
    if [[ -z "${PRERELEASE}" ]]; then
        DOCKER_TAGS+=(
            "${registry}/${namespace}/guessing-pen-frontend:latest"
            "${registry}/${namespace}/guessing-pen-api:latest"
        )
    fi
}

# 创建Git标签
create_git_tag() {
    local version="$1"
    local message="$2"
    
    log_info "创建Git标签: ${version}"
    
    # 检查标签是否已存在
    if git tag -l | grep -q "^${version}$"; then
        log_error "标签 '${version}' 已存在"
    fi
    
    # 创建带注释的标签
    git tag -a "${version}" -m "${message}"
    
    log_success "Git标签创建成功: ${version}"
}

# 推送标签到远程仓库
push_git_tag() {
    local version="$1"
    
    log_info "推送标签到远程仓库: ${version}"
    
    git push origin "${version}"
    
    log_success "标签推送成功: ${version}"
}

# 生成变更日志
generate_changelog() {
    local version="$1"
    local previous_version="$2"
    
    log_info "生成变更日志..."
    
    local changelog_file="${PROJECT_ROOT}/CHANGELOG.md"
    local temp_file=$(mktemp)
    
    # 生成变更日志头部
    {
        echo "# 变更日志"
        echo ""
        echo "## [${version#v}] - $(date +%Y-%m-%d)"
        echo ""
        
        if [[ -n "${previous_version}" ]]; then
            echo "### 更改内容"
            echo ""
            # 获取两个版本之间的提交
            git log --pretty=format:"- %s" "${previous_version}..HEAD" | head -20
            echo ""
            echo ""
        else
            echo "### 初始版本"
            echo ""
            echo "- 项目初始发布"
            echo ""
            echo ""
        fi
        
        # 如果已有变更日志，追加到后面
        if [[ -f "${changelog_file}" ]]; then
            tail -n +2 "${changelog_file}"
        fi
    } > "${temp_file}"
    
    mv "${temp_file}" "${changelog_file}"
    
    log_success "变更日志已更新: ${changelog_file}"
}

# 显示版本信息
show_version_info() {
    local version="$1"
    
    echo ""
    log_info "版本信息摘要："
    echo "  当前版本: ${CURRENT_VERSION:-无}"
    echo "  新版本: ${version}"
    echo "  主版本: ${MAJOR}"
    echo "  次版本: ${MINOR}"
    echo "  修订版本: ${PATCH}"
    echo ""
    
    if [[ ${#DOCKER_TAGS[@]} -gt 0 ]]; then
        echo "Docker标签策略："
        for tag in "${DOCKER_TAGS[@]}"; do
            echo "  - ${tag}"
        done
        echo ""
    fi
}

#==============================================================================
# 主函数
#==============================================================================

main() {
    local bump_type="${1:-patch}"
    local registry="${ACR_REGISTRY:-registry.cn-hangzhou.aliyuncs.com}"
    local namespace="${ACR_NAMESPACE:-guessing-pen}"
    local auto_push="${AUTO_PUSH:-false}"
    
    log_info "开始语义化版本标签管理..."
    
    # 切换到项目根目录
    cd "${PROJECT_ROOT}"
    
    # 检查Git状态
    check_git_status
    
    # 获取当前版本
    get_current_version
    
    # 计算下一个版本
    calculate_next_version "${bump_type}"
    
    # 生成标签策略
    generate_tag_strategy "${NEW_VERSION}" "${registry}" "${namespace}"
    
    # 显示版本信息
    show_version_info "${NEW_VERSION}"
    
    # 确认操作
    if [[ "${auto_push}" != "true" ]]; then
        echo -e "${YELLOW}即将创建版本标签: ${NEW_VERSION}${NC}"
        read -p "是否继续? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "操作已取消"
            exit 0
        fi
    fi
    
    # 生成变更日志
    generate_changelog "${NEW_VERSION}" "${CURRENT_VERSION}"
    
    # 创建Git标签
    local tag_message="Release ${NEW_VERSION}

版本类型: ${bump_type}
发布日期: $(date +%Y-%m-%d)
提交哈希: $(git rev-parse HEAD)"
    
    create_git_tag "${NEW_VERSION}" "${tag_message}"
    
    # 推送标签
    if [[ "${auto_push}" == "true" ]]; then
        push_git_tag "${NEW_VERSION}"
    else
        log_info "使用以下命令推送标签到远程仓库:"
        echo "  git push origin ${NEW_VERSION}"
    fi
    
    log_success "版本标签管理完成！"
    log_info "新版本: ${NEW_VERSION}"
}

# 帮助信息
show_help() {
    cat << EOF
用法: $0 [版本类型] [选项]

版本类型:
    major       主版本号 +1 (破坏性更改)
    minor       次版本号 +1 (新功能)
    patch       修订版本号 +1 (bug修复) [默认]

选项:
    -h, --help          显示此帮助信息
    --auto-push         自动推送标签到远程仓库
    --registry          ACR注册表地址
    --namespace         ACR命名空间

环境变量:
    ACR_REGISTRY       ACR注册表地址
    ACR_NAMESPACE      ACR命名空间
    AUTO_PUSH          自动推送标签 (true/false)

示例:
    $0                  # 创建patch版本 (如 v1.0.0 -> v1.0.1)
    $0 minor            # 创建minor版本 (如 v1.0.0 -> v1.1.0)
    $0 major            # 创建major版本 (如 v1.0.0 -> v2.0.0)
    $0 patch --auto-push # 创建版本并自动推送

语义化版本规范:
    MAJOR.MINOR.PATCH
    - MAJOR: 不兼容的API更改
    - MINOR: 向后兼容的功能添加
    - PATCH: 向后兼容的bug修复

EOF
}

# 参数解析
BUMP_TYPE="patch"
AUTO_PUSH="${AUTO_PUSH:-false}"
REGISTRY="${ACR_REGISTRY:-registry.cn-hangzhou.aliyuncs.com}"
NAMESPACE="${ACR_NAMESPACE:-guessing-pen}"

# 解析第一个参数作为版本类型
if [[ $# -gt 0 ]] && [[ "$1" =~ ^(major|minor|patch)$ ]]; then
    BUMP_TYPE="$1"
    shift
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        --auto-push)
            AUTO_PUSH=true
            shift
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
ACR_REGISTRY="$REGISTRY" ACR_NAMESPACE="$NAMESPACE" AUTO_PUSH="$AUTO_PUSH" main "$BUMP_TYPE"