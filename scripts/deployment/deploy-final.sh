#!/bin/bash

# 最终部署脚本 - 使用默认端口

echo "🚀 开始部署..."
echo ""

# 1. 停止服务
echo "📌 停止旧服务..."
docker-compose -f docker-compose.prod.yml down

# 2. 构建
echo "📌 构建镜像..."
docker-compose -f docker-compose.prod.yml build --no-cache

# 3. 启动
echo "📌 启动服务..."
docker-compose -f docker-compose.prod.yml up -d

# 4. 等待
echo "📌 等待服务启动..."
sleep 20

# 5. 检查
echo ""
echo "=========================================="
echo "服务状态:"
echo "=========================================="
docker-compose -f docker-compose.prod.yml ps

echo ""
echo "=========================================="
echo "✅ 部署完成！"
echo "=========================================="
echo ""
echo "访问地址:"
echo "  - 前端: http://game.akinokuni.cn/"
echo "  - API:  http://localhost:3001/"
echo ""
echo "查看日志:"
echo "  docker-compose -f docker-compose.prod.yml logs -f"
echo ""
