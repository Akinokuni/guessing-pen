#!/bin/bash

#==============================================================================
# 脚本名称: test-docker-build.sh
# 脚本描述: 本地测试Docker构建过程
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

# 主函数
main() {
    log_info "开始测试Docker构建..."
    
    # 检查Docker是否可用
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装或不可用"
        exit 1
    fi
    
    # 构建镜像
    log_info "构建Docker镜像..."
    if docker build -t guessing-pen-test:latest .; then
        log_success "Docker镜像构建成功！"
    else
        log_error "Docker镜像构建失败"
        exit 1
    fi
    
    # 测试镜像
    log_info "测试镜像运行..."
    if docker run --rm -d -p 8080:80 --name guessing-pen-test guessing-pen-test:latest; then
        log_success "容器启动成功！"
        log_info "等待5秒后测试..."
        sleep 5
        
        # 测试健康检查
        if curl -f http://localhost:8080/health > /dev/null 2>&1; then
            log_success "健康检查通过！"
        else
            log_warning "健康检查失败，但容器可能仍在启动中"
        fi
        
        # 停止容器
        docker stop guessing-pen-test
        log_info "测试容器已停止"
    else
        log_error "容器启动失败"
        exit 1
    fi
    
    log_success "Docker构建测试完成！"
}

# 清理函数
cleanup() {
    log_info "清理测试资源..."
    docker stop guessing-pen-test 2>/dev/null || true
    docker rm guessing-pen-test 2>/dev/null || true
}

# 设置错误处理
trap cleanup EXIT

# 执行主函数
main "$@"