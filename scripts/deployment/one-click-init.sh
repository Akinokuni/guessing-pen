#!/bin/bash

#==============================================================================
# 一键初始化服务器脚本
# 服务器: 47.115.146.78
# 用途: 快速配置Docker环境和部署应用
#==============================================================================

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置
PROJECT_DIR="/opt/guessing-pen"
ACR_REGISTRY="crpi-1dj58zvwo0jdkh2y.cn-shenzhen.personal.cr.aliyuncs.com"
ACR_NAMESPACE="guessing-pen"
IMAGE_NAME="guessing-pen-frontend"

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

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要root权限，请使用: sudo $0"
    fi
}

install_docker() {
    log_info "检查Docker安装状态..."
    
    if command -v docker &> /dev/null; then
        log_success "Docker已安装: $(docker --version)"
        return 0
    fi
    
    log_info "开始安装Docker..."
    
    apt-get update
    apt-get install -y ca-certificates curl gnupg lsb-release
    
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    systemctl start docker
    systemctl enable docker
    
    log_success "Docker安装完成: $(docker --version)"
}

setup_project() {
    log_info "创建项目目录..."
    
    mkdir -p "${PROJECT_DIR}"
    mkdir -p "${PROJECT_DIR}/logs"
    
    log_info "创建docker-compose.yml..."
    
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
      - DB_PORT=${DB_PORT:-5432}
      - DB_SSL=${DB_SSL:-false}
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
    
    if [[ ! -f "${PROJECT_DIR}/.env" ]]; then
        log_info "创建.env模板..."
        
        cat > "${PROJECT_DIR}/.env" << 'EOF'
# PostgreSQL数据库配置
DB_HOST=pgm-wz9z6i202l2p25wvco.pg.rds.aliyuncs.com
DB_PORT=5432
DB_NAME=postgres
DB_USER=aki
DB_PASSWORD=20138990398QGL@gmailcom

# ACR配置
ACR_REGISTRY=crpi-1dj58zvwo0jdkh2y.cn-shenzhen.personal.cr.aliyuncs.com
ACR_NAMESPACE=guessing-pen
ACR_USERNAME=YOUR_ACR_USERNAME_HERE
ACR_PASSWORD=YOUR_ACR_PASSWORD_HERE
EOF
        
        chmod 600 "${PROJECT_DIR}/.env"
        
        log_warning "请编辑 ${PROJECT_DIR}/.env 文件，填入正确的配置"
        log_warning "运行: nano ${PROJECT_DIR}/.env"
    else
        log_info ".env文件已存在，跳过创建"
    fi
}

setup_firewall() {
    log_info "配置防火墙..."
    
    if ! command -v ufw &> /dev/null; then
        apt-get install -y ufw
    fi
    
    ufw allow 22/tcp
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw allow 3000/tcp
    
    ufw --force enable
    
    log_success "防火墙配置完成"
}

deploy_app() {
    log_info "部署应用..."
    
    cd "${PROJECT_DIR}"
    
    if [[ ! -f ".env" ]]; then
        log_error ".env文件不存在，请先配置环境变量"
    fi
    
    source .env
    
    if [[ "${ACR_USERNAME}" == "YOUR_ACR_USERNAME_HERE" ]] || [[ "${ACR_PASSWORD}" == "YOUR_ACR_PASSWORD_HERE" ]]; then
        log_error "请先配置.env文件中的ACR凭证"
    fi
    
    log_info "登录ACR..."
    echo "${ACR_PASSWORD}" | docker login "${ACR_REGISTRY}" -u "${ACR_USERNAME}" --password-stdin
    
    log_info "拉取镜像..."
    docker pull "${ACR_REGISTRY}/${ACR_NAMESPACE}/${IMAGE_NAME}:latest"
    
    log_info "启动服务..."
    docker compose down || true
    docker compose up -d
    
    log_info "等待服务启动..."
    sleep 15
    
    if docker compose ps | grep -q "Up"; then
        log_success "应用部署成功！"
        docker compose ps
    else
        log_error "应用启动失败"
    fi
}

check_health() {
    log_info "执行健康检查..."
    
    sleep 5
    
    if curl -f http://localhost:3000/api/health &> /dev/null; then
        log_success "健康检查通过！"
        log_success "应用访问地址: http://47.115.146.78:3000"
    else
        log_warning "健康检查失败，请查看日志"
        log_info "查看日志: docker logs guessing-pen-app"
    fi
}

show_menu() {
    echo ""
    echo "=========================================="
    echo "  旮旯画师 - 服务器初始化脚本"
    echo "=========================================="
    echo ""
    echo "1. 完整安装（推荐首次使用）"
    echo "2. 仅安装Docker"
    echo "3. 仅配置项目"
    echo "4. 仅部署应用"
    echo "5. 查看服务状态"
    echo "6. 查看日志"
    echo "7. 重启服务"
    echo "8. 退出"
    echo ""
    read -p "请选择操作 [1-8]: " choice
    
    case $choice in
        1)
            check_root
            install_docker
            setup_project
            setup_firewall
            log_success "初始化完成！"
            log_warning "请编辑 ${PROJECT_DIR}/.env 文件后运行选项4部署应用"
            ;;
        2)
            check_root
            install_docker
            ;;
        3)
            check_root
            setup_project
            setup_firewall
            ;;
        4)
            check_root
            deploy_app
            check_health
            ;;
        5)
            cd "${PROJECT_DIR}" 2>/dev/null || log_error "项目目录不存在"
            docker compose ps
            ;;
        6)
            docker logs -f guessing-pen-app
            ;;
        7)
            check_root
            cd "${PROJECT_DIR}" 2>/dev/null || log_error "项目目录不存在"
            docker compose restart
            log_success "服务已重启"
            ;;
        8)
            log_info "退出"
            exit 0
            ;;
        *)
            log_error "无效选择"
            ;;
    esac
}

main() {
    if [[ $# -eq 0 ]]; then
        show_menu
    else
        case "$1" in
            install)
                check_root
                install_docker
                ;;
            setup)
                check_root
                setup_project
                setup_firewall
                ;;
            deploy)
                check_root
                deploy_app
                check_health
                ;;
            all)
                check_root
                install_docker
                setup_project
                setup_firewall
                log_success "初始化完成！"
                log_warning "请编辑 ${PROJECT_DIR}/.env 文件后运行: $0 deploy"
                ;;
            *)
                echo "用法: $0 [install|setup|deploy|all]"
                echo "或直接运行 $0 进入交互式菜单"
                exit 1
                ;;
        esac
    fi
}

main "$@"
