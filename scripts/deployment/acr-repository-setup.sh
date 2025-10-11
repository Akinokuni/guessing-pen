#!/bin/bash

#==============================================================================
# 脚本名称: acr-repository-setup.sh
# 脚本描述: 阿里云ACR仓库设置和验证脚本
# 作者: Kiro AI Assistant
# 创建日期: 2025-10-11
# 版本: 1.0.0
#==============================================================================

set -euo pipefail

# 颜色定义
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# ACR配置
readonly ACR_REGISTRY="crpi-1dj58zvwo0jdkh2y.cn-shenzhen.personal.cr.aliyuncs.com"
readonly ACR_NAMESPACE="guessing-pen"
readonly FRONTEND_REPO="guessing-pen-frontend"
readonly API_REPO="guessing-pen-api"

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查环境变量
check_environment() {
    log_info "检查环境变量..."
    
    if [[ -z "${ACR_USERNAME:-}" ]]; then
        log_error "请设置环境变量 ACR_USERNAME"
        return 1
    fi
    
    if [[ -z "${ACR_PASSWORD:-}" ]]; then
        log_error "请设置环境变量 ACR_PASSWORD"
        return 1
    fi
    
    log_success "环境变量检查通过"
}

# 测试ACR登录
test_acr_login() {
    log_info "测试ACR登录..."
    
    if echo "${ACR_PASSWORD}" | docker login "${ACR_REGISTRY}" -u "${ACR_USERNAME}" --password-stdin; then
        log_success "ACR登录成功"
        return 0
    else
        log_error "ACR登录失败，请检查用户名和密码"
        return 1
    fi
}

# 创建测试镜像并推送
test_repository_push() {
    local repo_name="$1"
    log_info "测试仓库推送: ${repo_name}"
    
    # 创建一个简单的测试镜像
    local test_image="${ACR_REGISTRY}/${ACR_NAMESPACE}/${repo_name}:test"
    
    # 使用hello-world作为测试镜像
    if docker pull hello-world:latest; then
        docker tag hello-world:latest "${test_image}"
        
        if docker push "${test_image}"; then
            log_success "仓库 ${repo_name} 推送测试成功"
            
            # 清理测试镜像
            docker rmi "${test_image}" || true
            return 0
        else
            log_error "仓库 ${repo_name} 推送失败"
            return 1
        fi
    else
        log_error "无法拉取测试镜像"
        return 1
    fi
}

# 验证仓库访问权限
verify_repositories() {
    log_info "验证仓库访问权限..."
    
    local repos=("${FRONTEND_REPO}" "${API_REPO}")
    local failed_repos=()
    
    for repo in "${repos[@]}"; do
        if ! test_repository_push "${repo}"; then
            failed_repos+=("${repo}")
        fi
    done
    
    if [[ ${#failed_repos[@]} -eq 0 ]]; then
        log_success "所有仓库访问权限验证通过"
        return 0
    else
        log_error "以下仓库访问失败: ${failed_repos[*]}"
        return 1
    fi
}

# 生成ACR设置指南
generate_setup_guide() {
    log_info "生成ACR设置指南..."
    
    cat << 'EOF'

🔧 阿里云ACR仓库设置指南
================================

如果推送失败，请按以下步骤设置：

1. 登录阿里云控制台
   https://cr.console.aliyun.com/

2. 进入容器镜像服务 ACR

3. 创建个人实例（如果还没有）
   - 选择地域：华南1（深圳）
   - 实例名称：任意
   - 实例规格：个人版（免费）

4. 创建命名空间
   - 命名空间名称：guessing-pen
   - 自动创建仓库：开启
   - 默认仓库类型：公开

5. 创建镜像仓库（如果自动创建未生效）
   仓库名称：guessing-pen-frontend
   仓库类型：公开
   
   仓库名称：guessing-pen-api
   仓库类型：公开

6. 获取访问凭证
   - 进入"访问凭证"页面
   - 设置固定密码（推荐）
   - 记录用户名和密码

7. 设置GitHub Secrets
   在GitHub仓库设置中添加：
   - ACR_USERNAME: 你的阿里云ACR用户名
   - ACR_PASSWORD: 你的阿里云ACR密码

8. 验证设置
   运行此脚本验证配置是否正确

EOF
}

# 主函数
main() {
    log_info "开始ACR仓库设置和验证..."
    
    # 检查Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装"
        exit 1
    fi
    
    # 检查环境变量
    if ! check_environment; then
        log_warning "环境变量未设置，显示设置指南..."
        generate_setup_guide
        exit 1
    fi
    
    # 测试登录
    if ! test_acr_login; then
        log_error "ACR登录失败"
        generate_setup_guide
        exit 1
    fi
    
    # 验证仓库
    if verify_repositories; then
        log_success "🎉 ACR仓库设置验证成功！"
        echo ""
        echo "现在可以："
        echo "1. 运行GitHub Actions进行自动部署"
        echo "2. 手动推送镜像到ACR"
        echo "3. 使用docker-compose部署应用"
    else
        log_error "❌ 仓库验证失败"
        generate_setup_guide
        exit 1
    fi
}

# 显示帮助
show_help() {
    cat << EOF
用法: $0 [选项]

选项:
    -h, --help      显示帮助信息
    --guide-only    只显示设置指南

环境变量:
    ACR_USERNAME    阿里云ACR用户名
    ACR_PASSWORD    阿里云ACR密码

示例:
    export ACR_USERNAME="your-username"
    export ACR_PASSWORD="your-password"
    $0

EOF
}

# 参数处理
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        --guide-only)
            generate_setup_guide
            exit 0
            ;;
        *)
            log_error "未知参数: $1"
            show_help
            exit 1
            ;;
    esac
done

# 执行主函数
main "$@"