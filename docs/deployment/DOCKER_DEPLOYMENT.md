# 🐳 Docker 部署指南

## 📋 目录

- [快速开始](#快速开始)
- [前置要求](#前置要求)
- [部署步骤](#部署步骤)
- [配置说明](#配置说明)
- [常用命令](#常用命令)
- [故障排查](#故障排查)
- [性能优化](#性能优化)

## 🚀 快速开始

### 一键部署

**Linux/Mac:**
```bash
chmod +x scripts/docker-deploy.sh
./scripts/docker-deploy.sh
```

**Windows:**
```cmd
scripts\docker-deploy.bat
```

## 📦 前置要求

### 必需软件
- Docker Engine 20.10+
- Docker Compose 2.0+

### 检查安装
```bash
docker --version
docker-compose --version
```

### 安装 Docker

**Ubuntu/Debian:**
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

**CentOS/RHEL:**
```bash
sudo yum install -y docker-ce docker-ce-cli containerd.io
sudo systemctl start docker
sudo systemctl enable docker
```

**Windows/Mac:**
- 下载并安装 [Docker Desktop](https://www.docker.com/products/docker-desktop)

## 🔧 部署步骤

### 1. 准备环境变量

复制环境变量模板：
```bash
cp .env.example .env
```

编辑 `.env` 文件，配置数据库连接：
```env
# 数据库配置（必填）
DB_HOST=pgm-wz9z6i202l2p25wvco.pg.rds.aliyuncs.com
DB_PORT=5432
DB_USER=aki
DB_PASSWORD=your-password
DB_NAME=aki
DB_SSL=false
```

### 2. 初始化数据库（首次部署）

如果数据库还未初始化：
```bash
npm run db:init
```

### 3. 构建和启动服务

**使用脚本（推荐）:**
```bash
# Linux/Mac
./scripts/docker-deploy.sh

# Windows
scripts\docker-deploy.bat
```

**手动部署:**
```bash
# 构建镜像
docker-compose -f docker-compose.prod.yml build

# 启动服务
docker-compose -f docker-compose.prod.yml up -d

# 查看日志
docker-compose -f docker-compose.prod.yml logs -f
```

### 4. 验证部署

访问以下地址验证服务：
- **前端**: http://localhost
- **API**: http://localhost:3001/api/health

检查容器状态：
```bash
docker-compose -f docker-compose.prod.yml ps
```

## 📝 配置说明

### Docker Compose 配置

项目包含两个 Docker Compose 文件：

1. **docker-compose.yml** - 开发环境（包含 PostgREST）
2. **docker-compose.prod.yml** - 生产环境（推荐）

### 服务架构

```
┌─────────────────┐
│   Nginx (80)    │  前端静态文件 + 反向代理
└────────┬────────┘
         │
         ├─→ /          → 前端应用
         └─→ /api/*     → API 服务器
                         └─→ PostgreSQL (阿里云RDS)
```

### 端口映射

| 服务 | 容器端口 | 主机端口 | 说明 |
|------|---------|---------|------|
| 前端 | 80 | 80 | Nginx Web服务器 |
| API | 3001 | 3001 | Node.js API服务器 |

### 环境变量

#### 必需变量
```env
DB_HOST=数据库主机地址
DB_USER=数据库用户名
DB_PASSWORD=数据库密码
DB_NAME=数据库名称
```

#### 可选变量
```env
DB_PORT=5432                    # 数据库端口
DB_SSL=false                    # 是否启用SSL
NODE_ENV=production             # Node环境
```

## 🛠️ 常用命令

### 启动和停止

```bash
# 启动所有服务
docker-compose -f docker-compose.prod.yml up -d

# 停止所有服务
docker-compose -f docker-compose.prod.yml down

# 重启服务
docker-compose -f docker-compose.prod.yml restart

# 停止并删除所有数据
docker-compose -f docker-compose.prod.yml down -v
```

### 查看日志

```bash
# 查看所有服务日志
docker-compose -f docker-compose.prod.yml logs -f

# 查看特定服务日志
docker-compose -f docker-compose.prod.yml logs -f api
docker-compose -f docker-compose.prod.yml logs -f frontend

# 查看最近100行日志
docker-compose -f docker-compose.prod.yml logs --tail=100
```

### 容器管理

```bash
# 查看容器状态
docker-compose -f docker-compose.prod.yml ps

# 进入容器
docker exec -it guessing-pen-api sh
docker exec -it guessing-pen-frontend sh

# 查看容器资源使用
docker stats guessing-pen-api guessing-pen-frontend
```

### 镜像管理

```bash
# 重新构建镜像
docker-compose -f docker-compose.prod.yml build --no-cache

# 拉取最新镜像
docker-compose -f docker-compose.prod.yml pull

# 查看镜像
docker images | grep guessing-pen

# 删除未使用的镜像
docker image prune -a
```

### 数据库操作

```bash
# 在容器中执行数据库脚本
docker exec -i guessing-pen-api node database/verify-db.js

# 备份数据库（从主机）
npm run db:backup

# 恢复数据库
npm run db:restore backup.sql
```

## 🔍 故障排查

### 问题1: 容器无法启动

**症状**: `docker-compose up` 失败

**检查步骤**:
```bash
# 1. 查看详细日志
docker-compose -f docker-compose.prod.yml logs

# 2. 检查端口占用
netstat -tulpn | grep :80
netstat -tulpn | grep :3001

# 3. 检查 .env 文件
cat .env
```

**解决方案**:
- 确保端口未被占用
- 验证 .env 文件配置正确
- 检查 Docker 服务是否运行

### 问题2: API 连接数据库失败

**症状**: API 健康检查失败

**检查步骤**:
```bash
# 查看 API 日志
docker-compose -f docker-compose.prod.yml logs api

# 测试数据库连接
docker exec guessing-pen-api node database/check-db.js
```

**解决方案**:
- 验证数据库配置
- 检查阿里云RDS白名单
- 确认网络连接

### 问题3: 前端无法访问

**症状**: 浏览器无法打开 http://localhost

**检查步骤**:
```bash
# 检查 Nginx 状态
docker exec guessing-pen-frontend nginx -t

# 查看 Nginx 日志
docker-compose -f docker-compose.prod.yml logs frontend
```

**解决方案**:
- 检查 nginx.conf 配置
- 验证构建产物是否存在
- 重启容器

### 问题4: 内存不足

**症状**: 容器频繁重启

**检查步骤**:
```bash
# 查看资源使用
docker stats

# 查看系统资源
free -h
df -h
```

**解决方案**:
- 增加 Docker 内存限制
- 优化应用配置
- 清理未使用的镜像和容器

## ⚡ 性能优化

### 1. 构建优化

**使用构建缓存**:
```bash
# 不使用缓存（首次构建）
docker-compose -f docker-compose.prod.yml build --no-cache

# 使用缓存（后续构建）
docker-compose -f docker-compose.prod.yml build
```

**多阶段构建**:
- Dockerfile 已使用多阶段构建
- 生产镜像只包含必要文件
- 减小镜像体积

### 2. 运行时优化

**资源限制**:
```yaml
# 在 docker-compose.prod.yml 中添加
services:
  api:
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
```

**健康检查**:
- 已配置健康检查
- 自动重启不健康的容器

### 3. 网络优化

**使用桥接网络**:
- 容器间通信更快
- 隔离外部网络

**启用 HTTP/2**:
```nginx
# 在 nginx.conf 中
listen 443 ssl http2;
```

### 4. 日志管理

**限制日志大小**:
```yaml
services:
  api:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

## 📊 监控和维护

### 健康检查

```bash
# 检查所有服务健康状态
docker-compose -f docker-compose.prod.yml ps

# 手动健康检查
curl http://localhost:3001/api/health
curl http://localhost/health
```

### 日志轮转

日志文件位置：
- Nginx: `./logs/nginx/`
- API: Docker logs

配置日志轮转：
```bash
# 创建 logrotate 配置
sudo nano /etc/logrotate.d/guessing-pen
```

### 备份策略

**定期备份**:
```bash
# 备份脚本
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
docker exec guessing-pen-api node database/backup.js > backup_$DATE.sql
```

**自动备份**:
```bash
# 添加到 crontab
0 2 * * * /path/to/backup.sh
```

## 🔒 安全建议

### 1. 环境变量安全
- ✅ 不要提交 .env 到 Git
- ✅ 使用强密码
- ✅ 定期更换密码

### 2. 网络安全
- ✅ 配置防火墙规则
- ✅ 使用 HTTPS（生产环境）
- ✅ 限制 API 访问

### 3. 容器安全
- ✅ 定期更新镜像
- ✅ 使用非 root 用户
- ✅ 扫描漏洞

## 📚 相关文档

- [主README](../../README.md)
- [数据库配置](../database/QUICK_START_DB.md)
- [部署检查清单](./DEPLOYMENT_CHECKLIST.md)
- [项目结构](../PROJECT_STRUCTURE.md)

## 🆘 获取帮助

遇到问题？

1. 查看 [故障排查](#故障排查) 部分
2. 检查 Docker 日志
3. 查看 [常见问题](./FAQ.md)
4. 提交 Issue

---

**文档版本**: 1.0.0  
**最后更新**: 2025-10-10  
**适用于**: Docker 20.10+, Docker Compose 2.0+
