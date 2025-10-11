#!/bin/bash

#==============================================================================
# 脚本名称: setup-server.sh
# 脚本描述: 在阿里云服务器上配置部署环境
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

# 配置
readonly SERVER_IP="47.115.146.78"
readonly PROJECT_NAME="guessing-pen"
readonly PROJECT_DIR="/opt/${PROJECT_NAME}"
readonly ACR_REGISTRY="crpi-1dj58zvwo0jdkh2y.cn-shenzhen.personal.cr.aliyuncs.com"
readonly ACR_NAMESPACE="akinokuni"

#==============================================================================
# 日志函数
#==============================================================================

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
    exit 1
}

#==============================================================================
# 检查函数
#==============================================================================

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要root权限运行，请使用: sudo $0"
    fi
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        return 1
    fi
    return 0
}

#==============================================================================
# 安装函数
#==============================================================================

install_docker() {
    log_info "检查Docker安装状态..."
    
    if check_command docker; then
        log_success "Docker已安装: $(docker --version)"
        return 0
    fi
    
    log_info "开始安装Docker..."
    
    # 更新包索引
    apt-get update
    
    # 安装依赖
    apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    
    # 添加Docker官方GPG密钥
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # 设置Docker仓库
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # 安装Docker Engine
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # 启动Docker服务
    systemctl start docker
    systemctl enable docker
    
    log_success "Docker安装完成: $(docker --version)"
}

install_docker_compose() {
    log_info "检查Docker Compose安装状态..."
    
    if check_command docker && docker compose version &> /dev/null; then
        log_success "Docker Compose已安装: $(docker compose version)"
        return 0
    fi
    
    log_info "Docker Compose已随Docker一起安装"
}

#==============================================================================
# 配置函数
#==============================================================================

setup_project_directory() {
    log_info "创建项目目录..."
    
    mkdir -p "${PROJECT_DIR}"
    mkdir -p "${PROJECT_DIR}/logs"
    mkdir -p "${PROJECT_DIR}/data"
    
    log_success "项目目录创建完成: ${PROJECT_DIR}"
}

setup_docker_compose() {
    log_info "创建docker-compose.yml配置..."
    
    cat > "${PROJECT_DIR}/docker-compose.yml" << 'EOF'
version: '3.8'

services:
  app:
    image: crpi-1dj58zvwo0jdkh2y.cn-shenzhen.personal.cr.aliyuncs.com/guessing-pen/guessing-pen-frontend:latest
    container_name: guessing-pen-app
    restart: unless-stopped
    ports:
      - "80:80"
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DB_HOST=${DB_HOST}
      - DB_PORT=${DB_PORT:-3306}
      - DB_NAME=${DB_NAME}
      - DB_USER=${DB_USER}
      - DB_PASSWORD=${DB_PASSWORD}
    volumes:
      - ./logs:/app/logs
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    networks:
      - guessing-pen-network

networks:
  guessing-pen-network:
    driver: bridge
EOF
    
    log_success "docker-compose.yml创建完成"
}

setup_env_file() {
    log_info "创建环境变量文件..."
    
    cat > "${PROJECT_DIR}/.env" << 'EOF'
# 数据库配置
DB_HOST=rm-wz9p6u2i5yz4uh5ue.mysql.rds.aliyuncs.com
DB_PORT=3306
DB_NAME=guessing_pen
DB_USER=guessing_pen_user
DB_PASSWORD=your_password_here

# ACR配置
ACR_REGISTRY=crpi-1dj58zvwo0jdkh2y.cn-shenzhen.personal.cr.aliyuncs.com
ACR_NAMESPACE=akinokuni
ACR_USERNAME=your_username_here
ACR_PASSWORD=your_password_here
EOF
    
    chmod 600 "${PROJECT_DIR}/.env"
    
    log_warning "请编辑 ${PROJECT_DIR}/.env 文件，填入正确的配置信息"
}

setup_acr_login() {
    log_info "配置ACR登录..."
    
    if [[ ! -f "${PROJECT_DIR}/.env" ]]; then
        log_error ".env文件不存在，请先运行setup_env_file"
    fi
    
    source "${PROJECT_DIR}/.env"
    
    if [[ -z "${ACR_USERNAME:-}" ]] || [[ -z "${ACR_PASSWORD:-}" ]]; then
        log_warning "ACR凭证未配置，跳过登录"
        return 0
    fi
    
    echo "${ACR_PASSWORD}" | docker login \
        --username "${ACR_USERNAME}" \
        --password-stdin \
        "${ACR_REGISTRY}"
    
    log_success "ACR登录成功"
}

setup_firewall() {
    log_info "配置防火墙规则..."
    
    if check_command ufw; then
        # 允许SSH
        ufw allow 22/tcp
        # 允许HTTP
        ufw allow 80/tcp
        # 允许HTTPS
        ufw allow 443/tcp
        # 允许应用端口
        ufw allow 3000/tcp
        
        # 启用防火墙（如果未启用）
        ufw --force enable
        
        log_success "防火墙规则配置完成"
    else
        log_warning "UFW未安装，跳过防火墙配置"
    fi
}

#==============================================================================
# 部署函数
#==============================================================================

deploy_application() {
    log_info "部署应用..."
    
    cd "${PROJECT_DIR}"
    
    # 拉取最新镜像
    docker compose pull
    
    # 停止旧容器
    docker compose down
    
    # 启动新容器
    docker compose up -d
    
    log_success "应用部署完成"
}

check_health() {
    log_info "检查应用健康状态..."
    
    sleep 10
    
    if curl -f http://localhost:3000/api/health &> /dev/null; then
        log_success "应用运行正常"
    else
        log_warning "应用健康检查失败，请查看日志"
    fi
}

#==============================================================================
# 主函数
#==============================================================================

show_usage() {
    cat << EOF
用法: $0 [选项]

选项:
    install     - 安装Docker和Docker Compose
    setup       - 配置项目目录和文件
    deploy      - 部署应用
    all         - 执行所有步骤
    help        - 显示此帮助信息

示例:
    $0 all          # 完整安装和部署
    $0 install      # 仅安装Docker
    $0 setup        # 仅配置项目
    $0 deploy       # 仅部署应用

EOF
}

main() {
    local action="${1:-help}"
    
    case "$action" in
        install)
            check_root
            install_docker
            install_docker_compose
            ;;
        setup)
            check_root
            setup_project_directory
            setup_docker_compose
            setup_env_file
            setup_firewall
            ;;
        deploy)
            check_root
            setup_acr_login
            deploy_application
            check_health
            ;;
        all)
            check_root
            log_info "开始完整安装和配置..."
            install_docker
            install_docker_compose
            setup_project_directory
            setup_docker_compose
            setup_env_file
            setup_firewall
            log_success "安装和配置完成！"
            log_warning "请编辑 ${PROJECT_DIR}/.env 文件后运行: $0 deploy"
            ;;
        help|*)
            show_usage
            ;;
    esac
}

main "$@"
