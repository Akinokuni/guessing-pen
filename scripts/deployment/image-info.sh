#!/bin/bash

#==============================================================================
# 脚本名称: image-info.sh
# 脚本描述: Docker镜像元数据查看脚本
# 作者: Kiro AI Assistant
# 创建日期: 2025-10-11
# 版本: 1.0.0
#==============================================================================

# 设置严格模式
set -euo pipefail

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
    echo -e "${BLUE}[INFO]${NC} ${message}"
}

log_success() {
    local message="$1"
    echo -e "${GREEN}[SUCCESS]${NC} ${message}"
}

log_warning() {
    local message="$1"
    echo -e "${YELLOW}[WARNING]${NC} ${message}"
}

log_error() {
    local message="$1"
    echo -e "${RED}[ERROR]${NC} ${message}"
    exit 1
}

#==============================================================================
# 镜像信息函数
#==============================================================================

# 检查镜像是否存在
check_image_exists() {
    local image="$1"
    
    if ! docker image inspect "${image}" &> /dev/null; then
        log_error "镜像不存在: ${image}"
    fi
}

# 显示镜像基本信息
show_basic_info() {
    local image="$1"
    
    log_info "镜像基本信息："
    echo "  镜像名称: ${image}"
    
    # 获取镜像ID
    local image_id=$(docker image inspect "${image}" --format '{{.Id}}' | cut -d: -f2 | cut -c1-12)
    echo "  镜像ID: ${image_id}"
    
    # 获取镜像大小
    local size=$(docker image inspect "${image}" --format '{{.Size}}' | numfmt --to=iec)
    echo "  镜像大小: ${size}"
    
    # 获取创建时间
    local created=$(docker image inspect "${image}" --format '{{.Created}}')
    echo "  创建时间: ${created}"
    
    # 获取架构信息
    local arch=$(docker image inspect "${image}" --format '{{.Architecture}}')
    local os=$(docker image inspect "${image}" --format '{{.Os}}')
    echo "  系统架构: ${os}/${arch}"
}

# 显示镜像标签信息
show_labels() {
    local image="$1"
    
    log_info "镜像标签信息："
    
    # 获取所有标签
    local labels=$(docker image inspect "${image}" --format '{{json .Config.Labels}}')
    
    if [[ "${labels}" == "null" ]] || [[ "${labels}" == "{}" ]]; then
        echo "  无标签信息"
        return
    fi
    
    # 解析并显示标签
    echo "${labels}" | jq -r 'to_entries[] | "  \(.key): \(.value)"' 2>/dev/null || {
        echo "  标签数据: ${labels}"
    }
}

# 显示构建信息
show_build_info() {
    local image="$1"
    
    log_info "构建信息："
    
    # 获取构建相关的标签
    local build_date=$(docker image inspect "${image}" --format '{{index .Config.Labels "org.opencontainers.image.created"}}' 2>/dev/null || echo "未知")
    local version=$(docker image inspect "${image}" --format '{{index .Config.Labels "org.opencontainers.image.version"}}' 2>/dev/null || echo "未知")
    local revision=$(docker image inspect "${image}" --format '{{index .Config.Labels "org.opencontainers.image.revision"}}' 2>/dev/null || echo "未知")
    local git_branch=$(docker image inspect "${image}" --format '{{index .Config.Labels "git.branch"}}' 2>/dev/null || echo "未知")
    local git_tag=$(docker image inspect "${image}" --format '{{index .Config.Labels "git.tag"}}' 2>/dev/null || echo "未知")
    
    echo "  构建日期: ${build_date}"
    echo "  版本号: ${version}"
    echo "  Git提交: ${revision}"
    echo "  Git分支: ${git_branch}"
    echo "  Git标签: ${git_tag}"
}

# 显示层信息
show_layers() {
    local image="$1"
    
    log_info "镜像层信息："
    
    # 获取层数
    local layer_count=$(docker image inspect "${image}" --format '{{len .RootFS.Layers}}')
    echo "  层数: ${layer_count}"
    
    # 显示历史记录（最近5层）
    echo "  最近构建步骤:"
    docker image history "${image}" --format "table {{.CreatedBy}}" --no-trunc | head -6 | tail -5 | while read -r line; do
        if [[ -n "${line}" ]] && [[ "${line}" != "CREATED BY" ]]; then
            echo "    - ${line:0:80}..."
        fi
    done
}

# 显示安全信息
show_security_info() {
    local image="$1"
    
    log_info "安全信息："
    
    # 获取用户信息
    local user=$(docker image inspect "${image}" --format '{{.Config.User}}')
    echo "  运行用户: ${user:-root}"
    
    # 获取暴露端口
    local ports=$(docker image inspect "${image}" --format '{{json .Config.ExposedPorts}}')
    if [[ "${ports}" != "null" ]] && [[ "${ports}" != "{}" ]]; then
        echo "  暴露端口: $(echo "${ports}" | jq -r 'keys[]' | tr '\n' ' ')"
    else
        echo "  暴露端口: 无"
    fi
    
    # 获取环境变量（不显示敏感信息）
    local env_count=$(docker image inspect "${image}" --format '{{len .Config.Env}}')
    echo "  环境变量数: ${env_count}"
}

# 显示健康检查信息
show_health_check() {
    local image="$1"
    
    log_info "健康检查："
    
    local healthcheck=$(docker image inspect "${image}" --format '{{json .Config.Healthcheck}}')
    
    if [[ "${healthcheck}" == "null" ]]; then
        echo "  未配置健康检查"
    else
        local test=$(echo "${healthcheck}" | jq -r '.Test[]' 2>/dev/null | tr '\n' ' ')
        local interval=$(echo "${healthcheck}" | jq -r '.Interval' 2>/dev/null)
        local timeout=$(echo "${healthcheck}" | jq -r '.Timeout' 2>/dev/null)
        local retries=$(echo "${healthcheck}" | jq -r '.Retries' 2>/dev/null)
        
        echo "  检查命令: ${test}"
        echo "  检查间隔: ${interval}"
        echo "  超时时间: ${timeout}"
        echo "  重试次数: ${retries}"
    fi
}

# 显示完整信息
show_full_info() {
    local image="$1"
    
    echo ""
    echo "========================================"
    echo "Docker镜像详细信息"
    echo "========================================"
    echo ""
    
    show_basic_info "${image}"
    echo ""
    show_build_info "${image}"
    echo ""
    show_security_info "${image}"
    echo ""
    show_health_check "${image}"
    echo ""
    show_layers "${image}"
    echo ""
    show_labels "${image}"
    echo ""
    echo "========================================"
}

# 比较两个镜像
compare_images() {
    local image1="$1"
    local image2="$2"
    
    log_info "比较镜像: ${image1} vs ${image2}"
    
    # 检查镜像是否存在
    check_image_exists "${image1}"
    check_image_exists "${image2}"
    
    # 比较大小
    local size1=$(docker image inspect "${image1}" --format '{{.Size}}')
    local size2=$(docker image inspect "${image2}" --format '{{.Size}}')
    local size_diff=$((size2 - size1))
    
    echo "  镜像大小:"
    echo "    ${image1}: $(echo "${size1}" | numfmt --to=iec)"
    echo "    ${image2}: $(echo "${size2}" | numfmt --to=iec)"
    echo "    差异: $(echo "${size_diff}" | numfmt --to=iec)"
    
    # 比较创建时间
    local created1=$(docker image inspect "${image1}" --format '{{.Created}}')
    local created2=$(docker image inspect "${image2}" --format '{{.Created}}')
    
    echo "  创建时间:"
    echo "    ${image1}: ${created1}"
    echo "    ${image2}: ${created2}"
    
    # 比较版本信息
    local version1=$(docker image inspect "${image1}" --format '{{index .Config.Labels "org.opencontainers.image.version"}}' 2>/dev/null || echo "未知")
    local version2=$(docker image inspect "${image2}" --format '{{index .Config.Labels "org.opencontainers.image.version"}}' 2>/dev/null || echo "未知")
    
    echo "  版本信息:"
    echo "    ${image1}: ${version1}"
    echo "    ${image2}: ${version2}"
}

#==============================================================================
# 主函数
#==============================================================================

main() {
    local image="${1:-}"
    local action="${2:-info}"
    
    if [[ -z "${image}" ]]; then
        log_error "请指定镜像名称"
    fi
    
    # 检查Docker是否可用
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装或不可用"
    fi
    
    case "${action}" in
        "info"|"full")
            check_image_exists "${image}"
            show_full_info "${image}"
            ;;
        "basic")
            check_image_exists "${image}"
            show_basic_info "${image}"
            ;;
        "labels")
            check_image_exists "${image}"
            show_labels "${image}"
            ;;
        "build")
            check_image_exists "${image}"
            show_build_info "${image}"
            ;;
        "compare")
            local image2="${3:-}"
            if [[ -z "${image2}" ]]; then
                log_error "比较模式需要指定第二个镜像"
            fi
            compare_images "${image}" "${image2}"
            ;;
        *)
            log_error "未知操作: ${action}"
            ;;
    esac
}

# 帮助信息
show_help() {
    cat << EOF
用法: $0 <镜像名称> [操作] [选项]

操作:
    info, full      显示完整镜像信息 [默认]
    basic          显示基本信息
    labels         显示标签信息
    build          显示构建信息
    compare        比较两个镜像

示例:
    $0 nginx:latest                                    # 显示完整信息
    $0 nginx:latest basic                              # 显示基本信息
    $0 nginx:latest build                              # 显示构建信息
    $0 nginx:latest compare nginx:1.25                 # 比较两个镜像
    
    # 查看ACR镜像信息
    $0 registry.cn-hangzhou.aliyuncs.com/guessing-pen/guessing-pen-frontend:latest

EOF
}

# 参数解析
if [[ $# -eq 0 ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# 执行主函数
main "$@"