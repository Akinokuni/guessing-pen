#!/bin/bash

#==============================================================================
# 部署到服务器 47.115.146.78
# 使用正确的PostgreSQL数据库配置
#==============================================================================

set -euo pipefail

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# 配置
PROJECT_DIR="/opt/guessing-pen"
ACR_REGISTRY="crpi-1dj58zvwo0jdkh2y.cn-shenzhen.personal.cr.aliyuncs.com"
ACR_NAMESPACE="guessing-pen"
IMAGE_NAME="guessing-pen-frontend"

# 数据库配置
DB_HOST="pgm-wz9z6i202l2p25wvco.pg.rds.aliyuncs.com"
DB_PORT="5432"
DB_NAME="postgres"
DB_USER="aki"
DB_PASSWORD="20138990398QGL@gmailcom"

log_info "🚀 开始部署到服务器..."

# 1. 创建项目目录
log_info "创建项目目录..."
mkdir -p "${PROJECT_DIR}"
mkdir -p "${PROJECT_DIR}/logs"
cd "${PROJECT_DIR}"

# 2. 创建docker-compose.yml
log_info "创建docker-compose.yml..."
cat > docker-compose.yml << 'EOF'
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
      - DB_PORT=${DB_PORT}
      - DB_NAME=${DB_NAME}
      - DB_USER=${DB_USER}
      - DB_PASSWORD=${DB_PASSWORD}
      - DB_SSL=false
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

# 3. 创建.env文件
log_info "创建.env文件..."
cat > .env << EOF
# PostgreSQL数据库配置
DB_HOST=${DB_HOST}
DB_PORT=${DB_PORT}
DB_NAME=${DB_NAME}
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}

# ACR配置（需要手动填写）
ACR_REGISTRY=${ACR_REGISTRY}
ACR_NAMESPACE=${ACR_NAMESPACE}
ACR_USERNAME=YOUR_ACR_USERNAME
ACR_PASSWORD=YOUR_ACR_PASSWORD
EOF

chmod 600 .env

log_warning "请编辑 ${PROJECT_DIR}/.env 文件，填入ACR凭证"
log_info "运行: nano ${PROJECT_DIR}/.env"
log_info ""
log_info "需要填写："
log_info "  ACR_USERNAME=你的ACR用户名"
log_info "  ACR_PASSWORD=你的ACR密码"
log_info ""
read -p "按Enter继续编辑.env文件..." 

nano .env

# 4. 加载环境变量
log_info "加载环境变量..."
source .env

# 5. 检查ACR凭证
if [[ "${ACR_USERNAME}" == "YOUR_ACR_USERNAME" ]] || [[ "${ACR_PASSWORD}" == "YOUR_ACR_PASSWORD" ]]; then
    log_error "请先配置ACR凭证"
fi

# 6. 登录ACR
log_info "登录阿里云ACR..."
echo "${ACR_PASSWORD}" | docker login "${ACR_REGISTRY}" -u "${ACR_USERNAME}" --password-stdin

# 7. 拉取镜像
log_info "拉取最新镜像..."
docker pull "${ACR_REGISTRY}/${ACR_NAMESPACE}/${IMAGE_NAME}:latest"

# 8. 停止旧容器
log_info "停止旧容器..."
docker compose down || true

# 9. 启动新容器
log_info "启动新容器..."
docker compose up -d

# 10. 等待服务启动
log_info "等待服务启动..."
sleep 15

# 11. 检查容器状态
log_info "检查容器状态..."
if docker compose ps | grep -q "Up"; then
    log_success "✅ 部署成功！"
    docker compose ps
else
    log_error "❌ 部署失败"
fi

# 12. 健康检查
log_info "执行健康检查..."
sleep 5

if curl -f http://localhost:3000/api/health &> /dev/null; then
    log_success "✅ 健康检查通过！"
else
    log_warning "⚠️ 健康检查失败，查看日志"
    docker logs --tail 50 guessing-pen-app
fi

# 13. 显示访问信息
log_success "🎉 部署完成！"
echo ""
echo "访问地址："
echo "  - 应用: http://47.115.146.78:3000"
echo "  - 健康检查: http://47.115.146.78:3000/api/health"
echo ""
echo "管理命令："
echo "  - 查看日志: docker logs -f guessing-pen-app"
echo "  - 重启服务: docker compose restart"
echo "  - 停止服务: docker compose down"
echo ""
