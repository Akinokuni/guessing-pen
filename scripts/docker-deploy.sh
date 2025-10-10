#!/bin/bash

# Docker 部署脚本
# 用于快速部署猜猜笔挑战应用

set -e

echo "🚀 开始 Docker 部署..."
echo ""

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 检查 .env 文件
if [ ! -f .env ]; then
    echo -e "${RED}❌ 错误: .env 文件不存在${NC}"
    echo "请先创建 .env 文件，可以从 .env.example 复制："
    echo "  cp .env.example .env"
    exit 1
fi

echo -e "${GREEN}✅ 找到 .env 文件${NC}"

# 检查必要的环境变量
required_vars=("DB_HOST" "DB_USER" "DB_PASSWORD" "DB_NAME")
missing_vars=()

for var in "${required_vars[@]}"; do
    if ! grep -q "^${var}=" .env; then
        missing_vars+=("$var")
    fi
done

if [ ${#missing_vars[@]} -ne 0 ]; then
    echo -e "${RED}❌ 错误: 缺少必要的环境变量:${NC}"
    for var in "${missing_vars[@]}"; do
        echo "  - $var"
    done
    exit 1
fi

echo -e "${GREEN}✅ 环境变量检查通过${NC}"
echo ""

# 停止并删除旧容器
echo "🛑 停止旧容器..."
docker-compose -f docker-compose.prod.yml down 2>/dev/null || true
echo -e "${GREEN}✅ 旧容器已停止${NC}"
echo ""

# 构建镜像
echo "🔨 构建 Docker 镜像..."
docker-compose -f docker-compose.prod.yml build --no-cache
echo -e "${GREEN}✅ 镜像构建完成${NC}"
echo ""

# 启动容器
echo "🚀 启动容器..."
docker-compose -f docker-compose.prod.yml up -d
echo -e "${GREEN}✅ 容器启动成功${NC}"
echo ""

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 10

# 检查服务状态
echo "🔍 检查服务状态..."
echo ""

# 检查 API 服务
if curl -f http://localhost:3001/api/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ API 服务: 运行中${NC}"
else
    echo -e "${YELLOW}⚠️  API 服务: 启动中或未响应${NC}"
fi

# 检查前端服务
if curl -f http://localhost/ > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 前端服务: 运行中${NC}"
else
    echo -e "${YELLOW}⚠️  前端服务: 启动中或未响应${NC}"
fi

echo ""
echo "📊 容器状态:"
docker-compose -f docker-compose.prod.yml ps

echo ""
echo -e "${GREEN}🎉 部署完成！${NC}"
echo ""
echo "访问地址:"
echo "  - 前端: http://localhost"
echo "  - API:  http://localhost:3001"
echo ""
echo "查看日志:"
echo "  docker-compose -f docker-compose.prod.yml logs -f"
echo ""
echo "停止服务:"
echo "  docker-compose -f docker-compose.prod.yml down"
