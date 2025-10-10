# ✅ 最终部署检查清单

## 配置验证

### 1. Docker Compose 配置 ✅
- [x] PostgREST 服务：端口 3001:3000
- [x] Frontend 服务：端口 80:80
- [x] 移除了旧的 API 服务
- [x] 健康检查配置正确
- [x] 依赖关系正确（frontend depends on postgrest）

### 2. 环境变量配置 ✅
```env
VITE_POSTGREST_URL=/api          # ✅ 生产环境通过 nginx 代理
VITE_USE_POSTGREST=true          # ✅ 启用 PostgREST
VITE_USE_SUPABASE=false          # ✅ 禁用 Supabase
DB_HOST=pgm-wz9z6i202l2p25wvco.pg.rds.aliyuncs.com  # ✅ 阿里云 RDS
DB_USER=aki                       # ✅ 数据库用户
DB_NAME=aki                       # ✅ 数据库名称
```

### 3. Nginx 配置 ✅
```nginx
location /api/ {
    proxy_pass http://postgrest:3000/;  # ✅ 代理到 PostgREST
    # ... 其他配置
}
```

### 4. 前端代码配置 ✅
- [x] `src/services/api.ts` - 强制使用 PostgREST
- [x] `src/services/postgrestService.ts` - 生产环境使用 `/api`
- [x] 移除了所有 Supabase 依赖

### 5. 数据库配置 ✅
- [x] 数据库已初始化
- [x] 表结构正确
- [x] 测试数据存在
- [x] RDS 白名单已配置

## 部署流程

### 步骤 1: 停止旧服务
```bash
docker-compose -f docker-compose.prod.yml down
```

### 步骤 2: 构建镜像
```bash
docker-compose -f docker-compose.prod.yml build --no-cache
```

### 步骤 3: 启动服务
```bash
docker-compose -f docker-compose.prod.yml up -d
```

### 步骤 4: 等待启动
```bash
sleep 20
```

### 步骤 5: 验证部署
```bash
# 检查容器状态
docker-compose -f docker-compose.prod.yml ps

# 应该看到：
# guessing-pen-postgrest   Up (healthy)
# guessing-pen-frontend    Up (healthy)
```

## 验证测试

### 1. PostgREST API 测试
```bash
# 测试 PostgREST 根路径
curl http://localhost:3001/

# 应该返回 OpenAPI 文档
```

### 2. 前端测试
```bash
# 测试前端
curl -I http://localhost/

# 应该返回 200 OK
```

### 3. API 代理测试
```bash
# 测试通过 nginx 代理访问 PostgREST
curl http://localhost/api/

# 应该返回 OpenAPI 文档
```

### 4. 浏览器测试
- 访问：http://game.akinokuni.cn/
- 打开开发者工具
- 检查网络请求
- 确认无错误

## 可能的问题和解决方案

### 问题 1: PostgREST 无法连接数据库
**症状**：PostgREST 容器启动失败或健康检查失败

**解决**：
```bash
# 查看日志
docker logs guessing-pen-postgrest

# 检查数据库连接
# 确认 RDS 白名单已配置
# 验证数据库凭据正确
```

### 问题 2: 前端无法访问 API
**症状**：浏览器控制台显示 API 请求失败

**解决**：
```bash
# 检查 nginx 配置
docker exec guessing-pen-frontend nginx -t

# 查看 nginx 日志
docker logs guessing-pen-frontend

# 确认 PostgREST 正在运行
docker ps | grep postgrest
```

### 问题 3: 502 Bad Gateway
**症状**：访问网站返回 502

**解决**：
```bash
# 检查所有容器状态
docker-compose -f docker-compose.prod.yml ps

# 重启服务
docker-compose -f docker-compose.prod.yml restart

# 查看详细日志
docker-compose -f docker-compose.prod.yml logs
```

## 关键配置点

### 1. PostgREST URL
- **开发环境**：`http://localhost:3001`
- **生产环境**：`/api`（通过 nginx 代理）

### 2. 端口映射
- PostgREST 容器：3000 → 主机 3001
- Frontend 容器：80 → 主机 80

### 3. 网络通信
- 浏览器 → Nginx (80) → PostgREST (3000)
- PostgREST → 阿里云 RDS (5432)

### 4. 数据库连接
- URI: `postgres://aki:password@host:5432/aki`
- Schema: `public`
- Role: `aki`

## 部署命令（一键执行）

```bash
cd /www/wwwroot/release
chmod +x scripts/deploy-final.sh
./scripts/deploy-final.sh
```

## 成功标志

部署成功后应该看到：

1. **容器状态**
   ```
   NAME                    STATUS
   guessing-pen-postgrest  Up (healthy)
   guessing-pen-frontend   Up (healthy)
   ```

2. **端口监听**
   ```
   80   - nginx (frontend)
   3001 - PostgREST
   ```

3. **网站访问**
   - http://game.akinokuni.cn/ - 正常显示
   - 控制台无错误
   - API 请求成功

4. **日志无错误**
   ```bash
   docker-compose -f docker-compose.prod.yml logs --tail=50
   # 应该没有 ERROR 级别的日志
   ```

---

**所有配置已验证！准备部署！** 🚀
