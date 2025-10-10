# 🔧 502 Bad Gateway 错误排查

## 问题诊断

### 发现的错误
- **URL**: http://game.akinokuni.cn/
- **错误**: 502 Bad Gateway
- **影响文件**: `index-b30199b8.css`
- **控制台错误**: `Cannot read properties of undefined (reading 'headers')`

### 错误原因

502 错误通常由以下原因引起：

1. **后端服务未运行** - API 容器未启动或崩溃
2. **Nginx 配置错误** - 反向代理配置不正确
3. **网络连接问题** - 容器间无法通信
4. **端口配置错误** - 端口映射不正确

## 🔍 诊断步骤

### 1. 检查容器状态

```bash
# 查看所有容器
docker-compose -f docker-compose.prod.yml ps

# 查看容器日志
docker-compose -f docker-compose.prod.yml logs
```

### 2. 检查 API 服务

```bash
# 检查 API 容器是否运行
docker ps | grep guessing-pen-api

# 查看 API 日志
docker logs guessing-pen-api

# 测试 API 健康检查
curl http://localhost:3001/api/health
```

### 3. 检查 Nginx 配置

```bash
# 进入前端容器
docker exec -it guessing-pen-frontend sh

# 测试 Nginx 配置
nginx -t

# 查看 Nginx 错误日志
cat /var/log/nginx/error.log
```

### 4. 检查网络连接

```bash
# 测试容器间连接
docker exec guessing-pen-frontend ping -c 3 api

# 测试 API 端口
docker exec guessing-pen-frontend wget -O- http://api:3001/api/health
```

## 🛠️ 解决方案

### 方案1: 重启服务（最常见）

```bash
# 停止所有服务
docker-compose -f docker-compose.prod.yml down

# 重新启动
docker-compose -f docker-compose.prod.yml up -d

# 等待服务启动
sleep 10

# 检查状态
docker-compose -f docker-compose.prod.yml ps
```

### 方案2: 检查 Nginx 配置

确保 `nginx.conf` 中的 API 代理配置正确：

```nginx
location /api/ {
    proxy_pass http://api:3001/api/;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    
    # 超时设置
    proxy_connect_timeout 60s;
    proxy_send_timeout 60s;
    proxy_read_timeout 60s;
}
```

### 方案3: 修复静态文件问题

如果是静态文件（CSS/JS）返回 502，可能是构建问题：

```bash
# 重新构建前端
docker-compose -f docker-compose.prod.yml build --no-cache frontend

# 重启服务
docker-compose -f docker-compose.prod.yml up -d frontend
```

### 方案4: 检查 API 服务配置

确保 API 服务正确启动：

```bash
# 查看 API 环境变量
docker exec guessing-pen-api env | grep DB_

# 测试数据库连接
docker exec guessing-pen-api node database/check-db.js

# 重启 API 服务
docker-compose -f docker-compose.prod.yml restart api
```

### 方案5: 检查端口映射

确保 `docker-compose.prod.yml` 中的端口配置正确：

```yaml
services:
  api:
    ports:
      - "3001:3001"  # 确保端口映射正确
  
  frontend:
    ports:
      - "8080:80"    # 如果 80 端口被占用，使用 8080
```

## 🔧 快速修复脚本

创建并运行修复脚本：

```bash
#!/bin/bash
# fix-502.sh

echo "🔧 修复 502 错误..."

# 1. 停止服务
echo "停止服务..."
docker-compose -f docker-compose.prod.yml down

# 2. 清理旧容器和网络
echo "清理资源..."
docker system prune -f

# 3. 重新构建（无缓存）
echo "重新构建..."
docker-compose -f docker-compose.prod.yml build --no-cache

# 4. 启动服务
echo "启动服务..."
docker-compose -f docker-compose.prod.yml up -d

# 5. 等待服务启动
echo "等待服务启动..."
sleep 15

# 6. 检查状态
echo "检查服务状态..."
docker-compose -f docker-compose.prod.yml ps

# 7. 测试 API
echo "测试 API..."
curl -f http://localhost:3001/api/health && echo "✅ API 正常" || echo "❌ API 异常"

# 8. 查看日志
echo "查看日志..."
docker-compose -f docker-compose.prod.yml logs --tail=50

echo "✅ 修复完成！"
```

## 📊 常见场景

### 场景1: API 容器未启动

**症状**: 
- `docker ps` 看不到 `guessing-pen-api`
- 日志显示 API 启动失败

**解决**:
```bash
# 查看 API 启动日志
docker-compose -f docker-compose.prod.yml logs api

# 检查环境变量
docker exec guessing-pen-api env

# 重启 API
docker-compose -f docker-compose.prod.yml restart api
```

### 场景2: 数据库连接失败

**症状**:
- API 日志显示数据库连接错误
- 健康检查失败

**解决**:
```bash
# 测试数据库连接
docker exec guessing-pen-api node database/check-db.js

# 检查 .env 配置
cat .env

# 验证 RDS 白名单
# 需要在阿里云控制台添加服务器 IP
```

### 场景3: Nginx 配置错误

**症状**:
- Nginx 日志显示 "upstream" 错误
- 无法连接到后端服务

**解决**:
```bash
# 测试 Nginx 配置
docker exec guessing-pen-frontend nginx -t

# 重新加载配置
docker exec guessing-pen-frontend nginx -s reload

# 查看错误日志
docker exec guessing-pen-frontend cat /var/log/nginx/error.log
```

### 场景4: 容器网络问题

**症状**:
- 容器间无法通信
- ping 不通其他容器

**解决**:
```bash
# 重建网络
docker-compose -f docker-compose.prod.yml down
docker network prune -f
docker-compose -f docker-compose.prod.yml up -d

# 检查网络
docker network inspect guessing-pen-network
```

## 🎯 预防措施

### 1. 健康检查

确保 `docker-compose.prod.yml` 中配置了健康检查：

```yaml
services:
  api:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3001/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

### 2. 依赖关系

确保前端依赖 API 启动：

```yaml
services:
  frontend:
    depends_on:
      api:
        condition: service_healthy
```

### 3. 日志监控

定期检查日志：

```bash
# 实时查看日志
docker-compose -f docker-compose.prod.yml logs -f

# 查看错误日志
docker-compose -f docker-compose.prod.yml logs | grep -i error
```

### 4. 自动重启

配置自动重启策略：

```yaml
services:
  api:
    restart: unless-stopped
  frontend:
    restart: unless-stopped
```

## 📝 检查清单

部署后检查：

- [ ] 所有容器都在运行
- [ ] API 健康检查通过
- [ ] 前端可以访问
- [ ] 静态文件加载正常
- [ ] API 请求正常
- [ ] 数据库连接正常
- [ ] 日志无错误

## 🆘 仍然无法解决？

如果以上方法都无法解决，请：

1. **收集信息**:
```bash
# 导出所有日志
docker-compose -f docker-compose.prod.yml logs > debug.log

# 导出容器状态
docker-compose -f docker-compose.prod.yml ps > containers.txt

# 导出网络信息
docker network inspect guessing-pen-network > network.json
```

2. **检查系统资源**:
```bash
# 检查内存
free -h

# 检查磁盘
df -h

# 检查 CPU
top
```

3. **查看详细错误**:
```bash
# Nginx 错误日志
docker exec guessing-pen-frontend cat /var/log/nginx/error.log

# API 错误日志
docker logs guessing-pen-api 2>&1 | grep -i error
```

## 📚 相关文档

- [Docker 部署指南](./DOCKER_DEPLOYMENT.md)
- [快速开始](../../DOCKER_QUICK_START.md)
- [数据库配置](../database/QUICK_START_DB.md)

---

**最后更新**: 2025-10-10  
**适用版本**: Docker 20.10+
