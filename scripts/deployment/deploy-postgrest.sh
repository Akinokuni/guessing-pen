#!/bin/bash

# PostgREST 部署脚本

echo "🚀 部署 PostgREST + 阿里云 PostgreSQL"
echo ""

# 1. 停止服务
echo "📌 步骤 1/5: 停止旧服务..."
docker-compose -f docker-compose.prod.yml down

# 2. 清理资源
echo "📌 步骤 2/5: 清理资源..."
docker system prune -f > /dev/null 2>&1

# 3. 重新构建
echo "📌 步骤 3/5: 重新构建镜像..."
docker-compose -f docker-compose.prod.yml build --no-cache

# 4. 启动服务
echo "📌 步骤 4/5: 启动服务..."
docker-compose -f docker-compose.prod.yml up -d

# 5. 等待并检查
echo "📌 步骤 5/5: 等待服务启动..."
sleep 20

echo ""
echo "检查服务状态..."
docker-compose -f docker-compose.prod.yml ps

echo ""
echo "测试 PostgREST..."
if curl -f http://localhost:3001/ > /dev/null 2>&1; then
    echo "✅ PostgREST 正常"
else
    echo "⚠️  PostgREST 未响应"
fi

echo ""
echo "✅ 部署完成！"
echo ""
echo "访问地址:"
echo "  - 前端: http://game.akinokuni.cn/"
echo "  - API:  http://localhost:3001/"
echo ""
echo "查看日志:"
echo "  docker-compose -f docker-compose.prod.yml logs -f"
