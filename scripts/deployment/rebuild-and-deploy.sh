#!/bin/bash

# 快速重新构建和部署脚本

echo "🚀 开始重新构建和部署..."
echo ""

# 1. 停止服务
echo "📌 步骤 1/4: 停止服务..."
docker-compose -f docker-compose.prod.yml down

# 2. 重新构建（无缓存）
echo "📌 步骤 2/4: 重新构建镜像..."
docker-compose -f docker-compose.prod.yml build --no-cache

# 3. 启动服务
echo "📌 步骤 3/4: 启动服务..."
docker-compose -f docker-compose.prod.yml up -d

# 4. 等待并检查
echo "📌 步骤 4/4: 等待服务启动..."
sleep 15

echo ""
echo "✅ 部署完成！"
echo ""
echo "访问地址:"
echo "  http://game.akinokuni.cn/"
echo ""
echo "查看日志:"
echo "  docker-compose -f docker-compose.prod.yml logs -f"
