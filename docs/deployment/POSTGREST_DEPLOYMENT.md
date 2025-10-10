# PostgREST + 阿里云RDS PostgreSQL 部署指南

## 架构说明

本项目使用以下技术栈：
- **前端**: React + Vite (Docker容器)
- **API层**: PostgREST (Docker容器)
- **数据库**: 阿里云RDS PostgreSQL

## 部署步骤

### 1. 数据库初始化

#### 方式A：使用部署脚本（推荐）

**Linux/macOS:**
```bash
cd database
chmod +x deploy-db.sh
./deploy-db.sh
```

**Windows:**
```bash
cd database
deploy-db.bat
```

#### 方式B：手动执行SQL

1. 使用psql连接到数据库：
```bash
psql -h pgm-wz9z6i202l2p25wvco.pg.rds.aliyuncs.com -p 5432 -U aki -d postgres
```

2. 执行初始化脚本：
```sql
\i database/init.sql
```

### 2. 验证数据库设置

连接数据库后，检查表和视图：

```sql
-- 查看所有表
\dt

-- 查看所有视图
\dv

-- 查看角色权限
\du

-- 测试查询
SELECT * FROM players LIMIT 5;
SELECT * FROM leaderboard LIMIT 10;
SELECT * FROM game_stats;
```

### 3. 启动Docker服务

#### 开发环境（本地测试）

```bash
# 启动所有服务
docker-compose up -d

# 查看日志
docker-compose logs -f

# 查看PostgREST日志
docker-compose logs -f postgrest

# 查看前端日志
docker-compose logs -f guessing-pen-frontend
```

#### 生产环境

```bash
# 使用部署脚本
./deploy.sh

# 或者使用 Windows 脚本
deploy.bat
```

### 4. 验证服务

#### 检查PostgREST API

```bash
# 健康检查
curl http://localhost:3001/

# 获取玩家列表
curl http://localhost:3001/players

# 获取排行榜
curl http://localhost:3001/leaderboard

# 获取统计数据
curl http://localhost:3001/game_stats
```

#### 检查前端应用

访问: http://localhost

### 5. 服务器部署

#### 准备工作

1. 确保服务器已安装：
   - Docker
   - Docker Compose
   - Git

2. 克隆项目到服务器：
```bash
git clone <your-repo-url>
cd guessing-pen-challenge
```

3. 配置环境变量：
```bash
cp .env.example .env
# 编辑 .env 文件，设置正确的配置
```

#### 部署命令

```bash
# 初始化数据库（首次部署）
cd database
./deploy-db.sh
cd ..

# 启动服务
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f
```

## 配置说明

### PostgREST 配置

PostgREST通过环境变量配置，主要参数：

```yaml
PGRST_DB_URI: 数据库连接字符串
PGRST_DB_SCHEMAS: 数据库模式（默认: public）
PGRST_DB_ANON_ROLE: 匿名访问角色（默认: web_anon）
PGRST_SERVER_PORT: API端口（默认: 3001）
```

### Nginx 反向代理

前端Nginx已配置PostgREST代理：
- 前端: http://localhost/
- API: http://localhost/api/ -> PostgREST

### 数据库角色

- **web_anon**: 匿名访问角色，用于PostgREST公开API
- **authenticator**: PostgREST连接数据库的角色
- **aki**: 数据库管理员角色

## API 端点

### 玩家管理
- `GET /players` - 获取玩家列表
- `POST /players` - 创建新玩家
- `GET /players?nickname=eq.{name}` - 按昵称查询

### 游戏会话
- `GET /game_sessions` - 获取游戏会话
- `POST /game_sessions` - 创建游戏会话
- `PATCH /game_sessions?id=eq.{id}` - 更新会话

### 答案组合
- `GET /answer_combinations` - 获取答案
- `POST /answer_combinations` - 提交答案

### 视图
- `GET /leaderboard` - 排行榜
- `GET /game_stats` - 游戏统计

## 故障排除

### PostgREST 无法连接数据库

1. 检查数据库连接信息是否正确
2. 确认数据库防火墙允许Docker容器IP
3. 检查web_anon角色是否存在并有正确权限

```sql
-- 检查角色
SELECT rolname FROM pg_roles WHERE rolname = 'web_anon';

-- 检查权限
\dp players
\dp game_sessions
\dp answer_combinations
```

### API 返回403错误

检查数据库角色权限：

```sql
-- 重新授权
GRANT USAGE ON SCHEMA public TO web_anon;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO web_anon;
```

### 前端无法连接API

1. 检查docker-compose网络配置
2. 确认PostgREST容器正在运行
3. 检查nginx配置中的代理设置

```bash
# 检查容器状态
docker-compose ps

# 测试PostgREST
docker-compose exec postgrest wget -O- http://localhost:3001/
```

### 数据库连接超时

1. 检查阿里云RDS白名单设置
2. 确认服务器IP已添加到白名单
3. 测试网络连接

```bash
# 测试数据库连接
telnet pgm-wz9z6i202l2p25wvco.pg.rds.aliyuncs.com 5432
```

## 监控和维护

### 日志查看

```bash
# 所有服务日志
docker-compose logs -f

# PostgREST日志
docker-compose logs -f postgrest

# 前端日志
docker-compose logs -f guessing-pen-frontend
```

### 性能监控

```sql
-- 查看活动连接
SELECT * FROM pg_stat_activity;

-- 查看表大小
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- 查看慢查询
SELECT * FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10;
```

### 备份数据库

```bash
# 导出数据
pg_dump -h pgm-wz9z6i202l2p25wvco.pg.rds.aliyuncs.com \
        -p 5432 -U aki -d postgres \
        -f backup_$(date +%Y%m%d).sql

# 导入数据
psql -h pgm-wz9z6i202l2p25wvco.pg.rds.aliyuncs.com \
     -p 5432 -U aki -d postgres \
     -f backup_20241010.sql
```

## 安全建议

1. **修改默认密码**: 更改authenticator角色密码
2. **启用SSL**: 配置数据库SSL连接
3. **限制IP访问**: 在阿里云RDS白名单中只允许必要的IP
4. **定期备份**: 设置自动备份策略
5. **监控日志**: 定期检查异常访问

## 扩展功能

### 启用JWT认证

1. 生成JWT密钥：
```bash
openssl rand -base64 32
```

2. 更新PostgREST配置：
```yaml
PGRST_JWT_SECRET: your-secret-key
PGRST_JWT_AUD: your-audience
```

3. 在数据库中创建认证函数

### 添加缓存层

可以在PostgREST前添加Redis缓存：

```yaml
services:
  redis:
    image: redis:alpine
    ports:
      - "6379:6379"
```

## 参考资源

- [PostgREST 官方文档](https://postgrest.org/)
- [PostgreSQL 官方文档](https://www.postgresql.org/docs/)
- [阿里云RDS文档](https://help.aliyun.com/product/26090.html)
- [Docker Compose 文档](https://docs.docker.com/compose/)
