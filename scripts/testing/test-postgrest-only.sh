#!/bin/bash

# 只测试 PostgREST 连接

echo "🧪 测试 PostgREST 连接..."
echo ""

# 1. 先测试数据库连接
echo "=========================================="
echo "步骤 1: 测试数据库连接"
echo "=========================================="
./scripts/test-db-connection.sh

echo ""
echo "=========================================="
echo "步骤 2: 启动 PostgREST 测试容器"
echo "=========================================="

# 停止旧的测试容器
docker stop test-postgrest 2>/dev/null || true
docker rm test-postgrest 2>/dev/null || true

# 启动测试容器
docker-compose -f docker-compose.test.yml up -d

echo "等待 PostgREST 启动..."
sleep 10

echo ""
echo "=========================================="
echo "步骤 3: 检查 PostgREST 状态"
echo "=========================================="
docker ps | grep test-postgrest

echo ""
echo "=========================================="
echo "步骤 4: 查看 PostgREST 日志"
echo "=========================================="
docker logs test-postgrest

echo ""
echo "=========================================="
echo "步骤 5: 测试 PostgREST API"
echo "=========================================="
echo "测试根路径..."
curl -s http://localhost:3001/ | head -20

echo ""
echo ""
echo "测试表列表..."
curl -s http://localhost:3001/players | head -20

echo ""
echo ""
echo "=========================================="
echo "测试完成"
echo "=========================================="
echo ""
echo "清理测试容器:"
echo "  docker-compose -f docker-compose.test.yml down"
echo ""
