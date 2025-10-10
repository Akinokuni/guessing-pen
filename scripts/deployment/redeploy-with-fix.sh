#!/bin/bash

# 修复并重新部署

echo "🔧 修复密码编码并重新部署..."
echo ""

# 1. 停止服务
echo "停止服务..."
docker-compose -f docker-compose.prod.yml down

# 2. 重新启动（不需要重新构建，只是配置变了）
echo "启动服务..."
docker-compose -f docker-compose.prod.yml up -d

# 3. 等待
echo "等待 PostgREST 启动..."
sleep 15

# 4. 检查状态
echo ""
echo "=========================================="
echo "PostgREST 状态:"
echo "=========================================="
docker ps | grep postgrest

echo ""
echo "=========================================="
echo "PostgREST 日志:"
echo "=========================================="
docker logs guessing-pen-postgrest --tail=30

echo ""
echo "=========================================="
echo "健康检查:"
echo "=========================================="
docker inspect guessing-pen-postgrest | grep -A 10 Health

echo ""
if docker ps | grep postgrest | grep -q "healthy"; then
    echo "✅ PostgREST 健康！"
    echo ""
    echo "测试 API:"
    curl http://localhost:3001/ 2>/dev/null | head -20
else
    echo "❌ PostgREST 仍然不健康"
    echo ""
    echo "运行诊断脚本:"
    echo "  chmod +x scripts/diagnose-postgrest.sh"
    echo "  ./scripts/diagnose-postgrest.sh"
fi
echo ""
