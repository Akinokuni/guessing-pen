# 🐳 Docker 快速开始

## 一分钟部署

### 1. 准备环境变量
```bash
cp .env.example .env
# 编辑 .env 文件，填入数据库配置
```

### 2. 初始化数据库（首次）
```bash
npm run db:init
```

### 3. 一键部署

**Linux/Mac:**
```bash
chmod +x scripts/docker-deploy.sh
npm run docker:deploy
```

**Windows:**
```cmd
scripts\docker-deploy.bat
```

### 4. 访问应用
- 前端: http://localhost
- API: http://localhost:3001

## 常用命令

```bash
# 启动服务
npm run docker:up

# 停止服务
npm run docker:down

# 查看日志
npm run docker:logs

# 查看状态
npm run docker:ps

# 重启服务
npm run docker:restart

# 清理资源
npm run docker:clean
```

## 服务架构

```
┌─────────────────────────────────┐
│   浏览器 (http://localhost)      │
└────────────┬────────────────────┘
             │
┌────────────▼────────────────────┐
│   Nginx (端口 80)                │
│   - 静态文件服务                  │
│   - API 反向代理                 │
└────────────┬────────────────────┘
             │
             ├─→ /          → 前端应用
             │
             └─→ /api/*     → API 服务器 (端口 3001)
                             │
                             └─→ PostgreSQL (阿里云RDS)
```

## 环境要求

- Docker 20.10+
- Docker Compose 2.0+
- 8GB+ RAM
- 10GB+ 磁盘空间

## 端口使用

| 服务 | 端口 | 说明 |
|------|------|------|
| 前端 | 80 | Nginx Web服务器 |
| API | 3001 | Node.js API服务器 |

## 故障排查

### 端口被占用
```bash
# 检查端口占用
netstat -tulpn | grep :80
netstat -tulpn | grep :3001

# 修改端口（编辑 docker-compose.prod.yml）
ports:
  - "8080:80"  # 改为 8080
```

### 数据库连接失败
```bash
# 检查数据库配置
cat .env

# 测试数据库连接
npm run db:check

# 查看 API 日志
docker logs guessing-pen-api
```

### 容器无法启动
```bash
# 查看详细日志
docker-compose -f docker-compose.prod.yml logs

# 重新构建
docker-compose -f docker-compose.prod.yml build --no-cache

# 清理并重启
docker-compose -f docker-compose.prod.yml down -v
docker-compose -f docker-compose.prod.yml up -d
```

## 详细文档

查看完整的 Docker 部署文档：
- [Docker 部署指南](./docs/deployment/DOCKER_DEPLOYMENT.md)
- [部署检查清单](./docs/deployment/DEPLOYMENT_CHECKLIST.md)
- [数据库配置](./docs/database/QUICK_START_DB.md)

## 生产环境建议

1. **使用 HTTPS**
   - 配置 SSL 证书
   - 使用 Let's Encrypt

2. **配置域名**
   - 修改 nginx.conf
   - 设置 DNS 记录

3. **启用监控**
   - 添加日志收集
   - 配置告警

4. **定期备份**
   - 数据库备份
   - 配置文件备份

## 下一步

- [ ] 配置阿里云RDS白名单
- [ ] 测试所有功能
- [ ] 配置域名和HTTPS
- [ ] 设置监控和告警
- [ ] 配置自动备份

---

**需要帮助？** 查看 [完整文档](./docs/deployment/DOCKER_DEPLOYMENT.md)
