#!/bin/bash

# 清理所有旧容器并重新部署

echo "🧹 清理所有旧容器..."
echo ""

# 停止所有相关容器
echo "停止所有容器..."
docker stop guessing-pen-api guessing-pen-postgrest guessing-pen-frontend 2>/dev/null || true

# 删除所有相关容器
echo "删除所有容器..."
docker rm guessing-pen-api guessing-pen-postgrest guessing-pen-frontend 2>/dev/null || true

# 停止 docker-compose 服务
echo "停止 docker-compose 服务..."
docker-compose -f docker-compose.prod.yml down 2>/dev/null || true

# 清理资源
echo "清理 Docker 资源..."
docker system prune -f

echo ""
echo "✅ 清理完成！"
echo ""
echo "🚀 开始重新部署..."
echo ""

# 重新构建
echo "构建镜像..."
docker-compose -f docker-compose.prod.yml build --no-cache

# 启动服务
echo "启动服务..."
docker-compose -f docker-compose.prod.yml up -d

# 等待
echo "等待服务启动..."
sleep 20

# 检查状态
echo ""
echo "服务状态:"
docker-compose -f docker-compose.prod.yml ps

echo ""
echo "✅ 部署完成！"
echo ""
echo "访问地址:"
echo "  - 前端: http://game.akinokuni.cn/"
echo "  - PostgREST: http://localhost:3002/"
echo ""
echo "查看日志:"
echo "  docker-compose -f docker-compose.prod.yml logs -f"
