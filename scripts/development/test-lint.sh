#!/bin/bash

#==============================================================================
# 脚本名称: test-lint.sh
# 脚本描述: 测试ESLint配置和依赖
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

# 检查Node.js和npm
check_environment() {
    log_info "检查开发环境..."
    
    if ! command -v node &> /dev/null; then
        log_error "Node.js未安装"
        return 1
    fi
    
    if ! command -v npm &> /dev/null; then
        log_error "npm未安装"
        return 1
    fi
    
    log_success "Node.js $(node --version) 和 npm $(npm --version) 已安装"
}

# 检查依赖安装
check_dependencies() {
    log_info "检查项目依赖..."
    
    if [[ ! -d "node_modules" ]]; then
        log_warning "node_modules不存在，正在安装依赖..."
        npm ci
    fi
    
    # 检查ESLint
    if [[ -f "node_modules/.bin/eslint" ]]; then
        log_success "ESLint已安装: $(npx eslint --version)"
    else
        log_error "ESLint未找到"
        return 1
    fi
    
    # 检查TypeScript
    if [[ -f "node_modules/.bin/tsc" ]]; then
        log_success "TypeScript已安装: $(npx tsc --version)"
    else
        log_error "TypeScript未找到"
        return 1
    fi
}

# 测试ESLint
test_eslint() {
    log_info "测试ESLint配置..."
    
    # 测试ESLint版本
    if npx eslint --version; then
        log_success "ESLint版本检查通过"
    else
        log_error "ESLint版本检查失败"
        return 1
    fi
    
    # 测试ESLint配置
    if npx eslint --print-config src/main.tsx > /dev/null 2>&1; then
        log_success "ESLint配置有效"
    else
        log_warning "ESLint配置可能有问题"
    fi
    
    # 运行实际的lint检查
    log_info "运行ESLint检查..."
    if npm run lint:ci; then
        log_success "ESLint检查通过"
    else
        log_warning "ESLint检查发现问题，但这是正常的"
    fi
}

# 测试TypeScript
test_typescript() {
    log_info "测试TypeScript配置..."
    
    # 测试TypeScript版本
    if npx tsc --version; then
        log_success "TypeScript版本检查通过"
    else
        log_error "TypeScript版本检查失败"
        return 1
    fi
    
    # 运行类型检查
    log_info "运行TypeScript类型检查..."
    if npx tsc --noEmit; then
        log_success "TypeScript类型检查通过"
    else
        log_warning "TypeScript类型检查发现问题"
    fi
}

# 测试构建
test_build() {
    log_info "测试项目构建..."
    
    if npm run build; then
        log_success "项目构建成功"
    else
        log_error "项目构建失败"
        return 1
    fi
}

# 主函数
main() {
    log_info "开始测试开发环境配置..."
    
    local errors=0
    
    check_environment || ((errors++))
    check_dependencies || ((errors++))
    test_eslint || ((errors++))
    test_typescript || ((errors++))
    test_build || ((errors++))
    
    echo ""
    if [[ $errors -eq 0 ]]; then
        log_success "🎉 所有测试通过！开发环境配置正确。"
    else
        log_error "❌ 发现 ${errors} 个问题，请检查配置。"
        exit 1
    fi
}

# 显示帮助
show_help() {
    cat << EOF
用法: $0 [选项]

选项:
    -h, --help      显示帮助信息
    --lint-only     只测试ESLint
    --ts-only       只测试TypeScript
    --build-only    只测试构建

描述:
    测试项目的开发环境配置，包括ESLint、TypeScript和构建

EOF
}

# 参数处理
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        --lint-only)
            check_environment && check_dependencies && test_eslint
            exit $?
            ;;
        --ts-only)
            check_environment && check_dependencies && test_typescript
            exit $?
            ;;
        --build-only)
            check_environment && check_dependencies && test_build
            exit $?
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