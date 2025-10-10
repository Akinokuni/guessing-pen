# 🧪 测试和部署指南

## 在服务器上测试

### 步骤 1: 测试数据库连接

```bash
cd /www/wwwroot/release

# 赋予执行权限
chmod +x scripts/test-db-connection.sh

# 测试数据库连接
./scripts/test-db-connection.sh
```

**预期结果**：
- ✅ 网络连接成功
- ✅ 显示服务器公网 IP
- ✅ 数据库连接成功
- ✅ 能查询到表

**如果失败**：
1. 记下显示的服务器 IP
2. 登录阿里云 RDS 控制台
3. 添加该 IP 到白名单
4. 重新测试

### 步骤 2: 测试 PostgREST

```bash
# 赋予执行权限
chmod +x scripts/test-postgrest-only.sh

# 测试 PostgREST
./scripts/test-postgrest-only.sh
```

**预期结果**：
- ✅ PostgREST 容器启动
- ✅ 日志无错误
- ✅ API 返回 OpenAPI 文档
- ✅ 能查询到数据

**如果失败**：
- 查看日志中的错误信息
- 确认数据库连接字符串正确
- 确认白名单已配置

### 步骤 3: 清理测试容器

```bash
# 清理测试容器
docker-compose -f docker-compose.test.yml down
```

### 步骤 4: 正式部署

```bash
# 赋予执行权限
chmod +x scripts/deploy-final.sh

# 部署
./scripts/deploy-final.sh
```

## 在本地测试（Windows）

### 前提条件
- Docker Desktop 已安装并运行
- 有网络连接到阿里云 RDS

### 测试步骤

```cmd
cd C:\Documents\Galgame群活动\旮旯画师之猜猜笔\web\release

REM 测试 PostgREST
scripts\test-postgrest.bat
```

## 常见问题

### 问题 1: 数据库连接超时

**症状**：
```
could not connect to server: Connection timed out
```

**解决**：
1. 检查服务器 IP：`curl ifconfig.me`
2. 添加到 RDS 白名单
3. 等待 1-2 分钟生效
4. 重新测试

### 问题 2: 认证失败

**症状**：
```
FATAL: password authentication failed for user "aki"
```

**解决**：
1. 检查密码是否正确
2. 确认密码中的 `@` 已编码为 `%40`
3. 检查用户名是否正确

### 问题 3: 数据库不存在

**症状**：
```
FATAL: database "aki" does not exist
```

**解决**：
1. 确认数据库名称
2. 运行数据库初始化：`npm run db:init`

### 问题 4: PostgREST 无法启动

**症状**：
```
Container is unhealthy
```

**解决**：
1. 查看日志：`docker logs guessing-pen-postgrest`
2. 检查数据库连接
3. 确认配置正确

## 验证清单

部署前确认：

- [ ] 数据库连接测试通过
- [ ] PostgREST 测试通过
- [ ] 服务器 IP 在 RDS 白名单中
- [ ] 数据库已初始化
- [ ] 环境变量配置正确

部署后验证：

- [ ] 容器状态为 healthy
- [ ] 日志无错误
- [ ] API 可以访问
- [ ] 前端可以访问
- [ ] 浏览器控制台无错误

## 快速命令参考

```bash
# 测试数据库
./scripts/test-db-connection.sh

# 测试 PostgREST
./scripts/test-postgrest-only.sh

# 查看日志
docker logs guessing-pen-postgrest
docker logs guessing-pen-frontend

# 检查状态
docker-compose -f docker-compose.prod.yml ps

# 重启服务
docker-compose -f docker-compose.prod.yml restart

# 完全重新部署
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml build --no-cache
docker-compose -f docker-compose.prod.yml up -d
```

## 获取帮助

如果遇到问题：

1. 运行诊断脚本：`./scripts/diagnose-postgrest.sh`
2. 收集日志：`docker-compose -f docker-compose.prod.yml logs > debug.log`
3. 检查配置文件
4. 查看文档

---

**按照这个顺序测试，确保每一步都成功再进行下一步！** 🎯
