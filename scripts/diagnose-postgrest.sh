#!/bin/bash

# PostgREST 诊断脚本

echo "🔍 诊断 PostgREST 问题..."
echo ""

# 1. 检查容器状态
echo "=========================================="
echo "1. 容器状态"
echo "=========================================="
docker ps -a | grep postgrest

echo ""
echo "=========================================="
echo "2. PostgREST 日志（最后50行）"
echo "=========================================="
docker logs guessing-pen-postgrest --tail=50

echo ""
echo "=========================================="
echo "3. 测试数据库连接"
echo "=========================================="
echo "尝试从容器内连接数据库..."
docker run --rm postgres:15 psql "postgres://aki:20138990398QGL%40gmailcom@pgm-wz9z6i202l2p25wvco.pg.rds.aliyuncs.com:5432/aki" -c "SELECT version();" 2>&1 || echo "❌ 数据库连接失败"

echo ""
echo "=========================================="
echo "4. 检查网络连接"
echo "=========================================="
echo "测试到 RDS 的网络连接..."
nc -zv pgm-wz9z6i202l2p25wvco.pg.rds.aliyuncs.com 5432 2>&1 || echo "❌ 无法连接到 RDS"

echo ""
echo "=========================================="
echo "5. 服务器公网 IP"
echo "=========================================="
echo "当前服务器公网 IP（需要添加到 RDS 白名单）："
curl -s ifconfig.me
echo ""

echo ""
echo "=========================================="
echo "诊断完成"
echo "=========================================="
echo ""
echo "常见问题："
echo "1. 如果看到 'connection refused' - 检查 RDS 白名单"
echo "2. 如果看到 'authentication failed' - 检查数据库密码"
echo "3. 如果看到 'database does not exist' - 检查数据库名称"
echo ""
