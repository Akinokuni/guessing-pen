# 🚨 502 错误诊断报告

## 错误信息

**检测时间**: 2025-10-10  
**网站**: http://game.akinokuni.cn/  
**错误类型**: 502 Bad Gateway

## 🔍 发现的问题

### 1. 控制台错误
```
Error> Failed to load resource: the server responded with a status of 502 (Bad Gateway)
index-b30199b8.css:undefined:undefined
Error: Cannot read properties of undefined (reading 'headers')
```

### 2. 网络请求分析

| 资源 | 状态 | 说明 |
|------|------|------|
| http://game.akinokuni.cn/ | ✅ 200 | HTML 加载成功 |
| /assets/index-bc153a6e.js | ✅ 200 | JS 加载成功 |
| /assets/index-b30199b8.css | ❌ 502 | **CSS 加载失败** |
| /vite.svg | ✅ 200 | 图标加载成功 |

### 3. 页面状态
- 页面显示空白
- CSS 文件无法加载
- JavaScript 可以加载但因缺少样式无法正常显示

## 🎯 问题原因分析

### 可能的原因

1. **Nginx 反向代理配置问题**
   - 静态文件路径配置错误
   - 代理超时设置不当
   - 缓存配置问题

2. **后端服务问题**
   - API 容器未正常运行
   - 容器间网络通信失败
   - 服务启动顺序问题

3. **构建问题**
   - 前端构建不完整
   - 静态文件未正确复制到容器
   - 文件权限问题

4. **资源问题**
   - 服务器内存不足
   - 磁盘空间不足
   - CPU 负载过高

## 🛠️ 推荐解决方案

### 立即执行（优先级：高）

#### 1. 重启服务
```bash
cd /www/wwwroot
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d
```

#### 2. 检查容器状态
```bash
docker-compose -f docker-compose.prod.yml ps
docker-compose -f docker-compose.prod.yml logs
```

#### 3. 使用修复脚本
```bash
chmod +x scripts/fix-502.sh
./scripts/fix-502.sh
```

### 详细排查（如果重启无效）

#### 1. 检查 Nginx 配置
```bash
# 进入容器
docker exec -it guessing-pen-frontend sh

# 测试配置
nginx -t

# 查看错误日志
cat /var/log/nginx/error.log

# 检查静态文件
ls -la /usr/share/nginx/html/assets/
```

#### 2. 检查构建产物
```bash
# 查看构建的文件
docker exec guessing-pen-frontend ls -la /usr/share/nginx/html/

# 检查 CSS 文件是否存在
docker exec guessing-pen-frontend ls -la /usr/share/nginx/html/assets/ | grep css
```

#### 3. 重新构建前端
```bash
# 无缓存重新构建
docker-compose -f docker-compose.prod.yml build --no-cache frontend

# 重启前端服务
docker-compose -f docker-compose.prod.yml up -d frontend
```

#### 4. 检查系统资源
```bash
# 内存使用
free -h

# 磁盘使用
df -h

# Docker 资源使用
docker stats --no-stream
```

## 📋 检查清单

执行以下检查：

- [ ] 容器是否都在运行？
  ```bash
  docker ps | grep guessing-pen
  ```

- [ ] API 服务是否健康？
  ```bash
  curl http://localhost:3001/api/health
  ```

- [ ] 前端容器中文件是否存在？
  ```bash
  docker exec guessing-pen-frontend ls /usr/share/nginx/html/assets/
  ```

- [ ] Nginx 配置是否正确？
  ```bash
  docker exec guessing-pen-frontend nginx -t
  ```

- [ ] 容器日志中是否有错误？
  ```bash
  docker logs guessing-pen-frontend --tail=50
  docker logs guessing-pen-api --tail=50
  ```

- [ ] 网络是否正常？
  ```bash
  docker network inspect guessing-pen-network
  ```

## 🔧 Nginx 配置检查

确保 `nginx.conf` 包含正确的静态文件配置：

```nginx
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    # 静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files $uri =404;
    }

    # SPA 路由处理
    location / {
        try_files $uri $uri/ /index.html;
    }

    # API 代理
    location /api/ {
        proxy_pass http://api:3001/api/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        
        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
```

## 📊 预期结果

修复后应该看到：

1. **容器状态**
   ```
   NAME                    STATUS
   guessing-pen-api        Up (healthy)
   guessing-pen-frontend   Up (healthy)
   ```

2. **网络请求**
   - 所有资源返回 200 状态码
   - CSS 文件正常加载
   - 页面正常显示

3. **控制台**
   - 无错误信息
   - 应用正常运行

## 🆘 如果仍然失败

### 收集诊断信息

```bash
# 创建诊断目录
mkdir -p /tmp/diagnosis

# 导出日志
docker-compose -f docker-compose.prod.yml logs > /tmp/diagnosis/docker-logs.txt

# 导出容器状态
docker-compose -f docker-compose.prod.yml ps > /tmp/diagnosis/containers.txt

# 导出网络信息
docker network inspect guessing-pen-network > /tmp/diagnosis/network.json

# 导出 Nginx 配置
docker exec guessing-pen-frontend cat /etc/nginx/nginx.conf > /tmp/diagnosis/nginx.conf

# 导出 Nginx 错误日志
docker exec guessing-pen-frontend cat /var/log/nginx/error.log > /tmp/diagnosis/nginx-error.log

# 打包诊断信息
tar -czf diagnosis-$(date +%Y%m%d-%H%M%S).tar.gz -C /tmp diagnosis/

echo "诊断信息已保存到: diagnosis-*.tar.gz"
```

### 联系支持

提供以下信息：
1. 诊断信息包
2. 服务器配置（CPU、内存、磁盘）
3. Docker 版本
4. 操作系统版本

## 📚 相关文档

- [502 错误排查指南](./TROUBLESHOOTING_502.md)
- [Docker 部署指南](./DOCKER_DEPLOYMENT.md)
- [快速开始](../../DOCKER_QUICK_START.md)

## 📝 后续建议

修复后建议：

1. **添加监控**
   - 配置健康检查告警
   - 监控容器资源使用
   - 记录错误日志

2. **优化配置**
   - 调整 Nginx 超时设置
   - 优化缓存策略
   - 配置日志轮转

3. **定期维护**
   - 定期重启服务
   - 清理 Docker 资源
   - 更新镜像版本

---

**报告生成**: 2025-10-10  
**状态**: 待修复  
**优先级**: 高
