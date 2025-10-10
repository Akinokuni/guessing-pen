#!/bin/bash

# 测试数据库连接脚本

echo "🔍 测试数据库连接..."
echo ""

# 数据库配置
DB_HOST="pgm-wz9z6i202l2p25wvco.pg.rds.aliyuncs.com"
DB_PORT="5432"
DB_USER="aki"
DB_PASSWORD="20138990398QGL@gmailcom"
DB_NAME="aki"

# URL 编码的密码（@ 编码为 %40）
DB_PASSWORD_ENCODED="20138990398QGL%40gmailcom"

echo "=========================================="
echo "1. 测试网络连接"
echo "=========================================="
echo "测试到 RDS 的连接..."
if command -v nc &> /dev/null; then
    nc -zv $DB_HOST $DB_PORT 2>&1
elif command -v telnet &> /dev/null; then
    timeout 5 telnet $DB_HOST $DB_PORT 2>&1
else
    echo "安装 nc 或 telnet 来测试网络连接"
fi

echo ""
echo "=========================================="
echo "2. 获取服务器公网 IP"
echo "=========================================="
SERVER_IP=$(curl -s ifconfig.me)
echo "服务器公网 IP: $SERVER_IP"
echo ""
echo "⚠️  请确保此 IP 已添加到阿里云 RDS 白名单！"

echo ""
echo "=========================================="
echo "3. 使用 Docker 测试数据库连接"
echo "=========================================="
echo "尝试连接数据库..."

# 使用 PostgreSQL 客户端容器测试连接
docker run --rm postgres:15-alpine psql \
  "postgres://${DB_USER}:${DB_PASSWORD_ENCODED}@${DB_HOST}:${DB_PORT}/${DB_NAME}" \
  -c "SELECT version();" 2>&1

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 数据库连接成功！"
    echo ""
    echo "测试查询表..."
    docker run --rm postgres:15-alpine psql \
      "postgres://${DB_USER}:${DB_PASSWORD_ENCODED}@${DB_HOST}:${DB_PORT}/${DB_NAME}" \
      -c "SELECT tablename FROM pg_tables WHERE schemaname='public' LIMIT 5;" 2>&1
else
    echo ""
    echo "❌ 数据库连接失败！"
    echo ""
    echo "可能的原因："
    echo "1. RDS 白名单未配置 - 需要添加 IP: $SERVER_IP"
    echo "2. 数据库密码错误"
    echo "3. 数据库不存在"
    echo "4. 网络问题"
fi

echo ""
echo "=========================================="
echo "4. 测试 PostgREST 配置"
echo "=========================================="
echo "PostgREST 连接字符串:"
echo "postgres://${DB_USER}:${DB_PASSWORD_ENCODED}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
echo ""

echo "=========================================="
echo "诊断完成"
echo "=========================================="
