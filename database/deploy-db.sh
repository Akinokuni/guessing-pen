#!/bin/bash

# 数据库部署脚本 - 阿里云RDS PostgreSQL

set -e

echo "🗄️  开始部署数据库..."

# 数据库连接信息
DB_HOST="pgm-wz9z6i202l2p25wvco.pg.rds.aliyuncs.com"
DB_PORT="5432"
DB_USER="aki"
DB_PASSWORD="20138990398QGL@gmailcom"
DB_NAME="postgres"

# 设置 PGPASSWORD 环境变量以避免密码提示
export PGPASSWORD="$DB_PASSWORD"

echo "📋 检查数据库连接..."
if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT version();" > /dev/null 2>&1; then
    echo "✅ 数据库连接成功"
else
    echo "❌ 数据库连接失败，请检查连接信息"
    exit 1
fi

echo "🔧 执行数据库初始化脚本..."
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f init.sql

if [ $? -eq 0 ]; then
    echo "✅ 数据库初始化成功！"
    echo ""
    echo "📊 数据库信息:"
    echo "  主机: $DB_HOST"
    echo "  端口: $DB_PORT"
    echo "  数据库: $DB_NAME"
    echo "  用户: $DB_USER"
    echo ""
    echo "🔑 PostgREST 角色:"
    echo "  匿名角色: web_anon"
    echo "  认证角色: authenticator"
    echo ""
    echo "📝 创建的表:"
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "\dt"
    echo ""
    echo "👁️  创建的视图:"
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "\dv"
else
    echo "❌ 数据库初始化失败"
    exit 1
fi

# 清除密码环境变量
unset PGPASSWORD

echo ""
echo "🎉 数据库部署完成！"
echo "现在可以启动 PostgREST 服务了"
