# 🚨 502 错误修复指南

## 问题概述

**网站**: http://game.akinokuni.cn/  
**错误**: 502 Bad Gateway  
**影响**: CSS 文件无法加载，页面显示空白

## 🎯 快速修复（3步）

### 1. 停止并重启服务
```bash
cd /www/wwwroot
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d
```

### 2. 检查服务状态
```bash
docker-compose -f docker-compose.prod.yml ps
```

期望看到：
```
NAME                    STATUS
guessing-pen-api        Up (healthy)
guessing-pen-frontend   Up (healthy)
```

### 3. 测试访问
- 前端: http://game.akinokuni.cn/ 或 http://localhost:8080
- API: http://localhost:3001/api/health

## 🔧 使用修复脚本（推荐）

```bash
# 赋予执行权限
chmod +x scripts/fix-502.sh

# 运行修复脚本
./scripts/fix-502.sh
```

脚本会自动：
1. 停止服务
2. 清理资源
3. 重新构建镜像
4. 启动服务
5. 检查状态

## 🔍 问题原因

根据诊断，可能的原因：

1. **容器未正常启动** - API 或前端容器崩溃
2. **Nginx 配置问题** - 反向代理配置错误
3. **构建问题** - 静态文件未正确复制
4. **网络问题** - 容器间无法通信

## 📋 详细排查

如果快速修复无效，按以下步骤排查：

### 1. 查看日志
```bash
# 查看所有日志
docker-compose -f docker-compose.prod.yml logs

# 查看 API 日志
docker logs guessing-pen-api --tail=50

# 查看前端日志
docker logs guessing-pen-frontend --tail=50
```

### 2. 检查容器内部
```bash
# 进入前端容器
docker exec -it guessing-pen-frontend sh

# 检查文件是否存在
ls -la /usr/share/nginx/html/assets/

# 测试 Nginx 配置
nginx -t

# 查看 Nginx 错误日志
cat /var/log/nginx/error.log
```

### 3. 检查网络
```bash
# 测试容器间连接
docker exec guessing-pen-frontend ping -c 3 api

# 检查网络配置
docker network inspect guessing-pen-network
```

### 4. 重新构建
```bash
# 无缓存重新构建
docker-compose -f docker-compose.prod.yml build --no-cache

# 重启服务
docker-compose -f docker-compose.prod.yml up -d
```

## 🛠️ 常见解决方案

### 方案1: 端口冲突
如果端口 80 被占用：
```bash
# 修改 docker-compose.prod.yml
# 将 "80:80" 改为 "8080:80"
# 然后重启服务
```

### 方案2: 内存不足
```bash
# 检查内存
free -h

# 清理 Docker 资源
docker system prune -a -f

# 重启服务
docker-compose -f docker-compose.prod.yml up -d
```

### 方案3: 数据库连接失败
```bash
# 测试数据库连接
docker exec guessing-pen-api node database/check-db.js

# 检查 .env 配置
cat .env

# 确保阿里云 RDS 白名单已配置
```

### 方案4: Nginx 配置错误
```bash
# 检查 nginx.conf 文件
cat nginx.conf

# 确保包含正确的静态文件配置
# 重新构建前端
docker-compose -f docker-compose.prod.yml build --no-cache frontend
docker-compose -f docker-compose.prod.yml up -d frontend
```

## 📊 验证修复

修复后验证：

1. **容器状态**
   ```bash
   docker ps | grep guessing-pen
   ```
   应该看到两个容器都在运行

2. **API 健康检查**
   ```bash
   curl http://localhost:3001/api/health
   ```
   应该返回 `{"status":"ok"}`

3. **前端访问**
   ```bash
   curl -I http://localhost:8080/
   ```
   应该返回 `200 OK`

4. **浏览器测试**
   - 打开 http://game.akinokuni.cn/
   - 检查控制台无错误
   - 页面正常显示

## 📚 相关文档

- **[详细排查指南](./docs/deployment/TROUBLESHOOTING_502.md)** - 完整的故障排查步骤
- **[错误诊断报告](./docs/deployment/ERROR_REPORT_502.md)** - 详细的错误分析
- **[Docker 部署指南](./docs/deployment/DOCKER_DEPLOYMENT.md)** - 完整部署文档
- **[快速开始](./DOCKER_QUICK_START.md)** - 快速部署指南

## 🆘 仍然无法解决？

### 收集诊断信息
```bash
# 运行诊断脚本
mkdir -p /tmp/diagnosis
docker-compose -f docker-compose.prod.yml logs > /tmp/diagnosis/logs.txt
docker-compose -f docker-compose.prod.yml ps > /tmp/diagnosis/status.txt
docker network inspect guessing-pen-network > /tmp/diagnosis/network.json
tar -czf diagnosis-$(date +%Y%m%d).tar.gz -C /tmp diagnosis/
```

### 检查系统资源
```bash
# 内存
free -h

# 磁盘
df -h

# CPU
top -bn1 | head -20

# Docker 资源
docker stats --no-stream
```

## 💡 预防措施

修复后建议：

1. **配置监控**
   - 设置健康检查告警
   - 监控容器资源使用

2. **定期维护**
   - 每周重启一次服务
   - 定期清理 Docker 资源
   - 更新镜像版本

3. **备份配置**
   - 备份 docker-compose.prod.yml
   - 备份 nginx.conf
   - 备份 .env 文件

4. **文档记录**
   - 记录每次修改
   - 保存错误日志
   - 更新部署文档

---

**创建时间**: 2025-10-10  
**状态**: 待修复  
**优先级**: 🔴 高
