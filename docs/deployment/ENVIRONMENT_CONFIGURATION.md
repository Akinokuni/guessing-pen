# 环境配置管理指南

## 概述

本文档详细说明了如何管理不同环境的配置，包括开发、预发布和生产环境的配置策略和安全要求。

## 环境分类

### 开发环境 (Development)
- **用途**: 日常开发和功能测试
- **分支**: `develop`
- **域名**: `dev.your-domain.com`
- **数据库**: 开发数据库或本地数据库
- **安全级别**: 低（允许调试和详细日志）

### 预发布环境 (Staging)
- **用途**: 生产前的最终测试
- **分支**: `main` (自动部署)
- **域名**: `staging.your-domain.com`
- **数据库**: 预发布数据库（生产数据的副本）
- **安全级别**: 中（接近生产环境配置）

### 生产环境 (Production)
- **用途**: 正式对外服务
- **分支**: `main` (手动审批部署)
- **域名**: `your-domain.com`
- **数据库**: 生产数据库
- **安全级别**: 高（最严格的安全配置）

## 配置文件管理

### 配置文件结构
```
.env.template                    # 配置模板
.env.development.template        # 开发环境模板
.env.production.template         # 生产环境模板
.env.local                      # 本地开发配置（不提交）
.env.development                # 开发环境配置（不提交）
.env.production                 # 生产环境配置（不提交）
```

### 配置优先级
1. 环境变量 (最高优先级)
2. `.env.local`
3. `.env.{NODE_ENV}`
4. `.env`
5. 默认值 (最低优先级)

## GitHub Secrets配置

### 开发环境Secrets
```
# 开发环境ACR配置
ACR_REGISTRY=registry.cn-hangzhou.aliyuncs.com
ACR_NAMESPACE_DEV=guessing-pen-dev
ACR_USERNAME_DEV=dev_acr_user
ACR_PASSWORD_DEV=dev_acr_password

# 开发服务器配置
DEV_SERVER_HOST=dev.example.com
DEV_SERVER_USER=dev
DEV_SERVER_SSH_KEY=-----BEGIN OPENSSH PRIVATE KEY-----...
DEV_SERVER_PORT=22

# 开发数据库配置
DEV_DB_HOST=dev-db.example.com
DEV_DB_USER=dev_user
DEV_DB_PASSWORD=dev_password
DEV_DB_NAME=guessing_pen_dev

# 开发环境API配置
DEV_API_URL=https://api-dev.your-domain.com
```

### 预发布环境Secrets
```
# 预发布服务器配置
STAGING_SERVER_HOST=staging.example.com
STAGING_SERVER_USER=staging
STAGING_SERVER_SSH_KEY=-----BEGIN OPENSSH PRIVATE KEY-----...
STAGING_SERVER_PORT=22

# 预发布数据库配置
STAGING_DB_HOST=staging-db.example.com
STAGING_DB_USER=staging_user
STAGING_DB_PASSWORD=staging_password
STAGING_DB_NAME=guessing_pen_staging
```

### 生产环境Secrets
```
# 生产环境ACR配置
ACR_REGISTRY=registry.cn-hangzhou.aliyuncs.com
ACR_NAMESPACE=guessing-pen-prod
ACR_USERNAME=prod_acr_user
ACR_PASSWORD=prod_acr_password

# 生产服务器配置
SERVER_HOST=your-production-server-ip
SERVER_USER=deploy
SERVER_SSH_KEY=-----BEGIN OPENSSH PRIVATE KEY-----...
SERVER_PORT=22

# 生产数据库配置
DB_HOST=your-production-db-host
DB_USER=prod_user
DB_PASSWORD=STRONG_PRODUCTION_PASSWORD
DB_NAME=guessing_pen_prod

# 生产环境API配置
PROD_API_URL=https://api.your-domain.com

# 通知配置
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
EMAIL_USERNAME=notifications@your-domain.com
EMAIL_PASSWORD=email_app_password
EMAIL_NOTIFICATION=admin@your-domain.com
```

## 安全配置策略

### 开发环境安全配置
```bash
# 较宽松的安全配置，便于调试
NODE_ENV=development
DEBUG=true
LOG_LEVEL=debug
SOURCE_MAP=true
HOT_RELOAD=true

# 使用较弱的密钥（仅用于开发）
JWT_SECRET=dev_jwt_secret_not_for_production
SESSION_SECRET=dev_session_secret

# 数据库配置
DB_SSL=false
DB_POOL_SIZE=5

# 安全头配置
SECURITY_HEADERS_ENABLED=false
CORS_ORIGIN=*
RATE_LIMIT_ENABLED=false
```

### 预发布环境安全配置
```bash
# 接近生产的安全配置
NODE_ENV=staging
DEBUG=false
LOG_LEVEL=info
SOURCE_MAP=false
HOT_RELOAD=false

# 使用中等强度的密钥
JWT_SECRET=staging_jwt_secret_medium_strength
SESSION_SECRET=staging_session_secret_medium_strength

# 数据库配置
DB_SSL=true
DB_POOL_SIZE=10

# 安全头配置
SECURITY_HEADERS_ENABLED=true
CORS_ORIGIN=https://staging.your-domain.com
RATE_LIMIT_ENABLED=true
RATE_LIMIT_MAX=200
RATE_LIMIT_WINDOW=900000
```

### 生产环境安全配置
```bash
# 最严格的安全配置
NODE_ENV=production
DEBUG=false
LOG_LEVEL=warn
SOURCE_MAP=false
HOT_RELOAD=false

# 使用强密钥（必须定期更换）
JWT_SECRET=VERY_STRONG_JWT_SECRET_FOR_PRODUCTION_CHANGE_REGULARLY
SESSION_SECRET=VERY_STRONG_SESSION_SECRET_FOR_PRODUCTION

# 数据库配置
DB_SSL=true
DB_POOL_SIZE=20
DB_CONNECTION_TIMEOUT=30000

# HTTPS配置
HTTPS_ENABLED=true
SSL_CERT_PATH=/etc/ssl/certs/your-domain.crt
SSL_KEY_PATH=/etc/ssl/private/your-domain.key

# 安全头配置
SECURITY_HEADERS_ENABLED=true
CORS_ORIGIN=https://your-domain.com
RATE_LIMIT_ENABLED=true
RATE_LIMIT_MAX=100
RATE_LIMIT_WINDOW=900000

# 额外安全配置
HELMET_ENABLED=true
CSP_ENABLED=true
HSTS_ENABLED=true
```

## 部署策略配置

### 开发环境部署策略
- **触发条件**: 推送到 `develop` 分支
- **自动化程度**: 完全自动化
- **测试要求**: 基本测试（单元测试、代码检查）
- **审批要求**: 无需审批
- **回滚策略**: 自动回滚到上一个稳定版本
- **通知**: Slack开发频道

### 预发布环境部署策略
- **触发条件**: 推送到 `main` 分支
- **自动化程度**: 完全自动化
- **测试要求**: 完整测试套件（单元、集成、安全扫描）
- **审批要求**: 无需审批
- **回滚策略**: 自动回滚 + 人工确认
- **通知**: Slack测试频道

### 生产环境部署策略
- **触发条件**: 推送到 `main` 分支或发布标签
- **自动化程度**: 半自动化（需要人工审批）
- **测试要求**: 完整测试 + 安全扫描 + 冒烟测试
- **审批要求**: 至少2人审批
- **回滚策略**: 人工触发回滚
- **通知**: Slack生产频道 + 邮件通知

## 配置管理最佳实践

### 1. 敏感信息管理
```bash
# ✅ 正确：使用环境变量
DB_PASSWORD=${DB_PASSWORD}

# ❌ 错误：硬编码密码
DB_PASSWORD=hardcoded_password
```

### 2. 环境特定配置
```bash
# ✅ 正确：根据环境调整配置
if [ "$NODE_ENV" = "production" ]; then
    LOG_LEVEL=warn
    DEBUG=false
else
    LOG_LEVEL=debug
    DEBUG=true
fi

# ❌ 错误：所有环境使用相同配置
LOG_LEVEL=debug
DEBUG=true
```

### 3. 配置验证
```bash
# ✅ 正确：验证必需的配置
required_vars=("DB_HOST" "DB_USER" "DB_PASSWORD" "JWT_SECRET")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "错误: 缺少必需的环境变量 $var"
        exit 1
    fi
done
```

### 4. 配置文档化
```bash
# ✅ 正确：为每个配置项添加注释
# 数据库主机地址（必需）
DB_HOST=localhost

# JWT令牌过期时间（秒，默认3600）
JWT_EXPIRES_IN=3600

# ❌ 错误：没有说明的配置
DB_HOST=localhost
JWT_EXPIRES_IN=3600
```

## 故障排查

### 常见配置问题

#### 1. 环境变量未生效
```bash
# 检查环境变量是否正确设置
echo $NODE_ENV
echo $DB_HOST

# 检查配置文件是否被正确加载
node -e "console.log(process.env)"
```

#### 2. 数据库连接失败
```bash
# 检查数据库配置
echo "DB_HOST: $DB_HOST"
echo "DB_PORT: $DB_PORT"
echo "DB_USER: $DB_USER"

# 测试数据库连接
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT 1;"
```

#### 3. SSL证书问题
```bash
# 检查证书文件
ls -la /etc/ssl/certs/your-domain.crt
ls -la /etc/ssl/private/your-domain.key

# 验证证书有效性
openssl x509 -in /etc/ssl/certs/your-domain.crt -text -noout
```

### 调试工具

#### 配置检查脚本
```bash
#!/bin/bash
# config-check.sh - 配置检查工具

echo "=== 环境配置检查 ==="
echo "NODE_ENV: $NODE_ENV"
echo "API_PORT: $API_PORT"
echo "DB_HOST: $DB_HOST"
echo "DB_SSL: $DB_SSL"

echo "=== 必需配置检查 ==="
required_vars=("NODE_ENV" "DB_HOST" "DB_USER" "JWT_SECRET")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "❌ 缺少: $var"
    else
        echo "✅ 已设置: $var"
    fi
done

echo "=== 安全配置检查 ==="
if [ "$NODE_ENV" = "production" ]; then
    if [ "$DEBUG" = "true" ]; then
        echo "⚠️  警告: 生产环境启用了DEBUG模式"
    fi
    if [ "$LOG_LEVEL" = "debug" ]; then
        echo "⚠️  警告: 生产环境使用了debug日志级别"
    fi
fi
```

## 配置更新流程

### 1. 开发环境配置更新
1. 修改 `.env.development.template`
2. 更新对应的GitHub Secrets
3. 重新部署开发环境
4. 验证配置生效

### 2. 生产环境配置更新
1. 修改 `.env.production.template`
2. 创建变更请求（Change Request）
3. 安全团队审核
4. 更新GitHub Secrets
5. 在预发布环境测试
6. 部署到生产环境
7. 验证和监控

### 3. 紧急配置更新
1. 立即更新GitHub Secrets
2. 触发紧急部署流程
3. 事后补充文档和审核

---

**创建日期**: 2025年10月11日  
**维护者**: DevOps团队  
**审核周期**: 每月一次  
**下次审核**: 2025年11月11日