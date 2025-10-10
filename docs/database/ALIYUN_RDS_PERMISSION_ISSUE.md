# 阿里云RDS权限问题说明

## 问题描述

在尝试初始化数据库时遇到权限错误：

```
ERROR:  permission denied for schema public
```

## 原因分析

阿里云RDS PostgreSQL出于安全考虑，默认限制了普通用户在`public` schema中的CREATE权限。

### 当前用户权限状态

```sql
-- 用户: aki
-- 在public schema中的CREATE权限: false
SELECT has_schema_privilege('aki', 'public', 'CREATE');
-- 结果: f (false)
```

## 解决方案

### 方案1: 使用阿里云RDS超级用户（推荐）

阿里云RDS提供了一个高权限账号，需要在RDS控制台创建：

1. 登录阿里云RDS控制台
2. 选择PostgreSQL实例
3. 进入"账号管理"
4. 创建"高权限账号"（如果还没有）
5. 使用高权限账号执行初始化脚本

### 方案2: 授予aki用户权限

需要使用高权限账号执行以下SQL：

```sql
-- 授予aki用户在public schema中的CREATE权限
GRANT CREATE ON SCHEMA public TO aki;

-- 授予aki用户创建角色的权限（如果需要）
ALTER USER aki CREATEROLE;
```

### 方案3: 使用阿里云RDS SQL窗口

1. 登录阿里云RDS控制台
2. 进入"SQL窗口"或"数据库管理"
3. 使用高权限账号登录
4. 直接执行`database/init_aliyun.sql`脚本

### 方案4: 创建专用数据库（推荐）

创建一个新的数据库，aki用户将自动成为该数据库的所有者：

```sql
-- 使用高权限账号执行
CREATE DATABASE guessing_pen_db OWNER aki;
```

然后连接到新数据库并执行初始化脚本：

```bash
psql -h pgm-wz9z6i202l2p25wvco.pg.rds.aliyuncs.com \
     -p 5432 -U aki -d guessing_pen_db \
     -f database/init_simple.sql
```

## 临时解决方案：使用简化的初始化脚本

创建一个不需要特殊权限的简化版本：

```sql
-- 不创建角色，直接创建表
CREATE TABLE players (
    id SERIAL PRIMARY KEY,
    nickname VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ... 其他表
```

## 推荐操作步骤

### 立即可行的方案

1. **联系阿里云RDS管理员**
   - 请求授予`aki`用户CREATE权限
   - 或获取高权限账号凭据

2. **使用阿里云控制台**
   - 通过Web界面的SQL窗口执行脚本
   - 这通常有更高的权限

3. **创建新数据库**
   - 让管理员创建`guessing_pen_db`
   - 设置`aki`为所有者

### 修改PostgREST配置

如果创建了新数据库，需要更新PostgREST连接：

```bash
# 停止当前容器
docker stop guessing-pen-postgrest-aliyun
docker rm guessing-pen-postgrest-aliyun

# 启动新容器，连接到新数据库
docker run -d --name guessing-pen-postgrest-aliyun \
  -p 3001:3001 \
  -e PGRST_DB_URI="postgres://aki:20138990398QGL%40gmailcom@pgm-wz9z6i202l2p25wvco.pg.rds.aliyuncs.com:5432/guessing_pen_db" \
  -e PGRST_DB_SCHEMAS="public" \
  -e PGRST_DB_ANON_ROLE="web_anon" \
  -e PGRST_SERVER_PORT="3001" \
  postgrest/postgrest
```

## 当前状态

- ✅ PostgREST已成功连接到阿里云RDS
- ✅ 网络连接正常
- ⚠️ 用户权限不足，无法创建表
- ⚠️ 需要管理员介入或使用高权限账号

## 下一步行动

1. **短期**：联系阿里云RDS管理员获取权限
2. **中期**：使用阿里云控制台SQL窗口执行初始化
3. **长期**：考虑使用专用数据库或调整权限策略

## 联系信息

- 阿里云RDS实例: pgm-wz9z6i202l2p25wvco.pg.rds.aliyuncs.com
- 当前用户: aki
- 数据库: postgres
- 需要权限: CREATE ON SCHEMA public

## 参考文档

- [阿里云RDS PostgreSQL权限管理](https://help.aliyun.com/document_detail/96753.html)
- [PostgreSQL权限系统](https://www.postgresql.org/docs/current/ddl-priv.html)
- [PostgREST配置指南](https://postgrest.org/en/stable/configuration.html)
