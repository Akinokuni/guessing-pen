# 🚀 使用 PostgREST 部署指南

## 配置说明

现在应用已配置为使用：
- **阿里云 PostgreSQL RDS** - 数据库
- **PostgREST** - API 服务器
- **Nginx** - 前端 + 反向代理

## 快速部署

### 1. 确保 .env 配置正确

```env
# 数据库配置
DB_HOST=pgm-wz9z6i202l2p25wvco.pg.rds.aliyuncs.com
DB_PORT=5432
DB_USER=aki
DB_PASSWORD=20138990398QGL@gmailcom
DB_NAME=aki
DB_SSL=false

# PostgREST 配置（启用）
VITE_POSTGREST_URL=http://localhost:3001
VITE_USE_POSTGREST=true
VITE_USE_SUPABASE=false
```

### 2. 停止旧服务

```bash
docker-compose -f docker-compose.prod.yml down
```

### 3. 重新构建和启动

```bash
# 构建镜像
docker-compose -f docker-compose.prod.yml build --no-cache

# 启动服务
docker-compose -f docker-compose.prod.yml up -d
```

### 4. 检查服务状态

```bash
# 查看容器状态
docker-compose -f docker-compose.prod.yml ps

# 应该看到：
# guessing-pen-postgrest   Up (healthy)
# guessing-pen-frontend    Up (healthy)
```

### 5. 测试 API

```bash
# 测试 PostgREST
curl http://localhost:3001/

# 测试前端
curl http://localhost/
```

## 服务架构

```
浏览器
  ↓
Nginx (80) → 前端静态文件
  ↓
  └→ /api/* → PostgREST (3001)
                  ↓
              PostgreSQL (阿里云 RDS)
```

## PostgREST 配置

PostgREST 会自动：
- 连接到阿里云 PostgreSQL
- 暴露数据库表为 REST API
- 处理所有 CRUD 操作

### API 端点

- `GET /players` - 获取玩家列表
- `POST /players` - 创建玩家
- `GET /game_sessions` - 获取游戏会话
- `GET /leaderboard` - 获取排行榜
- `GET /game_stats` - 获取统计数据

## 故障排查

### PostgREST 无法连接数据库

```bash
# 查看 PostgREST 日志
docker logs guessing-pen-postgrest

# 检查数据库连接
docker exec guessing-pen-postgrest wget -O- http://localhost:3000/
```

**解决方案**：
1. 确认阿里云 RDS 白名单已配置
2. 检查 .env 中的数据库配置
3. 验证数据库用户权限

### 前端无法访问 API

```bash
# 查看 Nginx 日志
docker logs guessing-pen-frontend

# 测试 Nginx 配置
docker exec guessing-pen-frontend nginx -t
```

**解决方案**：
1. 检查 nginx.conf 中的代理配置
2. 确认 PostgREST 容器正在运行
3. 重启前端容器

## 完整部署命令

```bash
#!/bin/bash

# 1. 停止服务
docker-compose -f docker-compose.prod.yml down

# 2. 清理资源
docker system prune -f

# 3. 重新构建
docker-compose -f docker-compose.prod.yml build --no-cache

# 4. 启动服务
docker-compose -f docker-compose.prod.yml up -d

# 5. 等待启动
sleep 20

# 6. 检查状态
docker-compose -f docker-compose.prod.yml ps

# 7. 测试 API
curl http://localhost:3001/

echo "✅ 部署完成！"
echo "访问: http://game.akinokuni.cn/"
```

## 注意事项

1. **数据库权限** - 确保数据库用户有足够权限
2. **RDS 白名单** - 添加服务器 IP 到白名单
3. **端口映射** - PostgREST 容器端口 3000 映射到主机 3001
4. **网络配置** - 所有容器在同一网络中

## 下一步

- [ ] 部署服务
- [ ] 测试所有功能
- [ ] 配置 HTTPS
- [ ] 设置监控

---

**准备就绪！现在可以部署了！** 🎉
