#!/bin/bash

#==============================================================================
# 脚本名称: server-init.sh
# 脚本描述: 服务器初始化脚本 - 一键配置部署环境
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
readonly PROJECT_DIR="/opt/guessing-pen"
readonly ACR_REGISTRY="crpi-1dj58zvwo0jdkh2y.cn-shenzhen.personal.cr.aliyuncs.com"
readonly ACR_NAMESPACE="guessing-pen"
readonly FRONTEND_IMAGE="guessing-pen-frontend"

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

# 检查是否为root用户
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_warning "建议使用非root用户运行此脚本"
        read -p "是否继续? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi
}

# 安装Docker
install_docker() {
    log_info "检查Docker安装..."
    
    if command -v docker &> /dev/null; then
        log_success "Docker已安装: $(docker --version)"
        return 0
    fi
    
    log_info "安装Docker..."
    
    # 下载安装脚本
    curl -fsSL https://get.docker.com -o get-docker.sh
    
    # 执行安装
    sudo sh get-docker.sh
    
    # 启动Docker
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # 添加当前用户到docker组
    sudo usermod -aG docker $USER
    
    log_success "Docker安装完成"
    log_warning "请注销并重新登录以使docker组权限生效"
}

# 安装Docker Compose
install_docker_compose() {
    log_info "检查Docker Compose安装..."
    
    if command -v docker-compose &> /dev/null; then
        log_success "Docker Compose已安装: $(docker-compose --version)"
        return 0
    fi
    
    log_info "安装Docker Compose..."
    
    # 下载最新版本
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    
    # 添加执行权限
    sudo chmod +x /usr/local/bin/docker-compose
    
    log_success "Docker Compose安装完成"
}

# 创建项目目录
setup_project_directory() {
    log_info "设置项目目录..."
    
    if [[ -d "$PROJECT_DIR" ]]; then
        log_warning "项目目录已存在: $PROJECT_DIR"
    else
        sudo mkdir -p "$PROJECT_DIR"
        sudo chown $USER:$USER "$PROJECT_DIR"
        log_success "项目目录创建完成: $PROJECT_DIR"
    fi
}

# 创建docker-compose配置
create_docker_compose() {
    log_info "创建docker-compose配置..."
    
    cat > "$PROJECT_DIR/docker-compose.prod.yml" << 'EOF'
version: '3.8'

services:
  frontend:
    image: crpi-1dj58zvwo0jdkh2y.cn-shenzhen.personal.cr.aliyuncs.com/guessing-pen/guessing-pen-frontend:latest
    container_name: guessing-pen-frontend
    ports:
      - "80:80"
    restart: unless-stopped
    environment:
      - NODE_ENV=production
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
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
  default:
    name: guessing-pen-network
EOF
    
    log_success "docker-compose配置创建完成"
}

# 配置防火墙
setup_firewall() {
    log_info "配置防火墙..."
    
    if command -v ufw &> /dev/null; then
        sudo ufw allow 22/tcp
        sudo ufw allow 80/tcp
        sudo ufw allow 443/tcp
        sudo ufw --force enable
        log_success "防火墙配置完成"
    else
        log_warning "ufw未安装，请手动配置防火墙"
    fi
}

# 生成SSH密钥
generate_ssh_key() {
    log_info "生成GitHub Actions SSH密钥..."
    
    local key_path="$HOME/.ssh/github_actions"
    
    if [[ -f "$key_path" ]]; then
        log_warning "SSH密钥已存在"
    else
        ssh-keygen -t ed25519 -C "github-actions" -f "$key_path" -N ""
        cat "${key_path}.pub" >> "$HOME/.ssh/authorized_keys"
        log_success "SSH密钥生成完成"
    fi
    
    echo ""
    log_info "请将以下私钥添加到GitHub Secrets (SERVER_SSH_KEY):"
    echo "================================================"
    cat "$key_path"
    echo "================================================"
}

# 测试ACR连接
test_acr_connection() {
    log_info "测试ACR连接..."
    
    echo ""
    read -p "请输入ACR用户名: " ACR_USERNAME
    read -s -p "请输入ACR密码: " ACR_PASSWORD
    echo ""
    
    if echo "$ACR_PASSWORD" | docker login "$ACR_REGISTRY" -u "$ACR_USERNAME" --password-stdin; then
        log_success "ACR登录成功"
        
        # 测试拉取镜像
        log_info "测试拉取镜像..."
        if docker pull "$ACR_REGISTRY/$ACR_NAMESPACE/$FRONTEND_IMAGE:latest"; then
            log_success "镜像拉取成功"
        else
            log_warning "镜像拉取失败，可能镜像还未推送"
        fi
    else
        log_error "ACR登录失败"
        return 1
    fi
}

# 创建部署脚本
create_deploy_script() {
    log_info "创建部署脚本..."
    
    cat > "$PROJECT_DIR/deploy.sh" << 'EOF'
#!/bin/bash
set -e

echo "🚀 开始部署..."

# 拉取最新镜像
echo "📦 拉取最新镜像..."
docker-compose -f docker-compose.prod.yml pull

# 停止旧容器
echo "⏹️ 停止旧容器..."
docker-compose -f docker-compose.prod.yml down

# 启动新容器
echo "▶️ 启动新容器..."
docker-compose -f docker-compose.prod.yml up -d

# 等待启动
echo "⏳ 等待服务启动..."
sleep 10

# 检查状态
if docker-compose -f docker-compose.prod.yml ps | grep -q "Up"; then
    echo "✅ 部署成功！"
else
    echo "❌ 部署失败"
    docker-compose -f docker-compose.prod.yml logs
    exit 1
fi

# 清理旧镜像
echo "🧹 清理旧镜像..."
docker image prune -f

echo "🎉 部署完成！"
EOF
    
    chmod +x "$PROJECT_DIR/deploy.sh"
    log_success "部署脚本创建完成: $PROJECT_DIR/deploy.sh"
}

# 显示配置摘要
show_summary() {
    echo ""
    echo "========================================="
    echo "🎉 服务器初始化完成！"
    echo "========================================="
    echo ""
    echo "📋 配置摘要:"
    echo "  - 项目目录: $PROJECT_DIR"
    echo "  - Docker: $(docker --version)"
    echo "  - Docker Compose: $(docker-compose --version)"
    echo ""
    echo "🔑 GitHub Secrets配置:"
    echo "  - SERVER_HOST: <你的服务器IP>"
    echo "  - SERVER_USER: $USER"
    echo "  - SERVER_SSH_KEY: <上面显示的私钥>"
    echo "  - SERVER_PORT: 22"
    echo ""
    echo "🚀 下一步:"
    echo "  1. 在GitHub中配置Secrets"
    echo "  2. 推送代码触发自动部署"
    echo "  3. 访问 http://<服务器IP> 查看应用"
    echo ""
    echo "📖 详细文档:"
    echo "  docs/deployment/SERVER_SETUP_GUIDE.md"
    echo ""
}

# 主函数
main() {
    log_info "开始服务器初始化..."
    
    check_root
    install_docker
    install_docker_compose
    setup_project_directory
    create_docker_compose
    setup_firewall
    create_deploy_script
    generate_ssh_key
    
    echo ""
    read -p "是否测试ACR连接? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        test_acr_connection
    fi
    
    show_summary
}

# 显示帮助
show_help() {
    cat << EOF
用法: $0 [选项]

选项:
    -h, --help      显示帮助信息
    --skip-docker   跳过Docker安装
    --skip-firewall 跳过防火墙配置

描述:
    一键初始化服务器部署环境

EOF
}

# 参数处理
SKIP_DOCKER=false
SKIP_FIREWALL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        --skip-docker)
            SKIP_DOCKER=true
            shift
            ;;
        --skip-firewall)
            SKIP_FIREWALL=true
            shift
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
