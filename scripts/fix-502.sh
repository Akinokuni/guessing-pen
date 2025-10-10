#!/bin/bash

# 502 错误快速修复脚本

echo "🔧 开始修复 502 错误..."
echo ""

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 1. 停止服务
echo "📌 步骤 1/7: 停止服务..."
docker-compose -f docker-compose.prod.yml down
echo -e "${GREEN}✅ 服务已停止${NC}"
echo ""

# 2. 清理资源
echo "📌 步骤 2/7: 清理资源..."
docker system prune -f > /dev/null 2>&1
echo -e "${GREEN}✅ 资源已清理${NC}"
echo ""

# 3. 检查 .env 文件
echo "📌 步骤 3/7: 检查配置..."
if [ ! -f .env ]; then
    echo -e "${RED}❌ .env 文件不存在${NC}"
    exit 1
fi
echo -e "${GREEN}✅ 配置文件存在${NC}"
echo ""

# 4. 重新构建
echo "📌 步骤 4/7: 重新构建镜像（这可能需要几分钟）..."
docker-compose -f docker-compose.prod.yml build --no-cache
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ 构建失败${NC}"
    exit 1
fi
echo -e "${GREEN}✅ 镜像构建完成${NC}"
echo ""

# 5. 启动服务
echo "📌 步骤 5/7: 启动服务..."
docker-compose -f docker-compose.prod.yml up -d
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ 启动失败${NC}"
    exit 1
fi
echo -e "${GREEN}✅ 服务已启动${NC}"
echo ""

# 6. 等待服务启动
echo "📌 步骤 6/7: 等待服务启动（30秒）..."
for i in {1..30}; do
    echo -n "."
    sleep 1
done
echo ""
echo -e "${GREEN}✅ 等待完成${NC}"
echo ""

# 7. 检查服务状态
echo "📌 步骤 7/7: 检查服务状态..."
echo ""

# 检查容器状态
echo "容器状态:"
docker-compose -f docker-compose.prod.yml ps
echo ""

# 测试 API
echo "测试 API 服务..."
if curl -f http://localhost:3001/api/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ API 服务正常${NC}"
else
    echo -e "${YELLOW}⚠️  API 服务未响应${NC}"
    echo "查看 API 日志:"
    docker logs guessing-pen-api --tail=20
fi
echo ""

# 测试前端
echo "测试前端服务..."
if curl -f http://localhost:8080/ > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 前端服务正常${NC}"
else
    echo -e "${YELLOW}⚠️  前端服务未响应${NC}"
    echo "查看前端日志:"
    docker logs guessing-pen-frontend --tail=20
fi
echo ""

# 显示访问地址
echo "=========================================="
echo -e "${GREEN}🎉 修复完成！${NC}"
echo "=========================================="
echo ""
echo "访问地址:"
echo "  - 前端: http://localhost:8080"
echo "  - API:  http://localhost:3001"
echo ""
echo "如果仍有问题，请查看日志:"
echo "  docker-compose -f docker-compose.prod.yml logs -f"
echo ""
echo "或查看故障排查文档:"
echo "  docs/deployment/TROUBLESHOOTING_502.md"
echo ""
