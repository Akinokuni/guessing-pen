# 手动数据库设置指南

## 📋 准备工作

### 连接信息
- **主机**: pgm-wz9z6i202l2p25wvco.pg.rds.aliyuncs.com
- **端口**: 5432
- **用户**: aki
- **密码**: 20138990398QGL@gmailcom
- **数据库**: postgres

## 🚀 执行步骤

### 方法1: 使用阿里云RDS控制台（推荐）

1. **登录阿里云控制台**
   - 访问: https://rdsnext.console.aliyun.com/
   - 找到你的PostgreSQL实例

2. **打开SQL窗口**
   - 点击实例名称
   - 左侧菜单选择"SQL窗口"或"数据库管理"
   - 选择数据库: `postgres`

3. **执行SQL脚本**
   - 打开文件: `database/MANUAL_SETUP.sql`
   - 复制全部内容
   - 粘贴到SQL窗口
   - 点击"执行"按钮

4. **查看结果**
   - 检查执行结果
   - 应该看到"Database initialization completed successfully!"

### 方法2: 使用DBeaver（图形化工具）

1. **下载安装DBeaver**
   - 访问: https://dbeaver.io/download/
   - 下载并安装

2. **创建连接**
   - 新建连接 → PostgreSQL
   - 填写连接信息（见上方）
   - 测试连接

3. **执行脚本**
   - 打开SQL编辑器
   - 粘贴`database/MANUAL_SETUP.sql`内容
   - 执行（Ctrl+Enter或点击执行按钮）

### 方法3: 使用pgAdmin

1. **下载安装pgAdmin**
   - 访问: https://www.pgadmin.org/download/
   - 下载并安装

2. **添加服务器**
   - 右键"Servers" → "Register" → "Server"
   - General标签: 输入名称
   - Connection标签: 填写连接信息

3. **执行脚本**
   - 右键数据库 → "Query Tool"
   - 粘贴SQL脚本
   - 点击执行按钮（▶️）

### 方法4: 使用命令行（需要安装PostgreSQL客户端）

```bash
# Windows PowerShell
$env:PGPASSWORD="20138990398QGL@gmailcom"
psql -h pgm-wz9z6i202l2p25wvco.pg.rds.aliyuncs.com -p 5432 -U aki -d postgres -f database/MANUAL_SETUP.sql

# Linux/macOS
export PGPASSWORD="20138990398QGL@gmailcom"
psql -h pgm-wz9z6i202l2p25wvco.pg.rds.aliyuncs.com -p 5432 -U aki -d postgres -f database/MANUAL_SETUP.sql
```

## ✅ 验证安装

执行以下SQL命令验证：

```sql
-- 检查表
SELECT tablename FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('players', 'game_sessions', 'answer_combinations');

-- 应该返回3行：
-- players
-- game_sessions
-- answer_combinations

-- 检查视图
SELECT viewname FROM pg_views 
WHERE schemaname = 'public' 
AND viewname IN ('leaderboard', 'game_stats');

-- 应该返回2行：
-- leaderboard
-- game_stats

-- 测试数据
SELECT * FROM players;
SELECT * FROM leaderboard;
SELECT * FROM game_stats;
```

## 🔧 完成后的操作

### 1. 重启PostgREST容器

```bash
# 停止旧容器
docker stop guessing-pen-postgrest-aliyun
docker rm guessing-pen-postgrest-aliyun

# 启动新容器
docker run -d --name guessing-pen-postgrest-aliyun \
  -p 3001:3001 \
  -e PGRST_DB_URI="postgres://aki:20138990398QGL%40gmailcom@pgm-wz9z6i202l2p25wvco.pg.rds.aliyuncs.com:5432/postgres" \
  -e PGRST_DB_SCHEMAS="public" \
  -e PGRST_DB_ANON_ROLE="aki" \
  -e PGRST_SERVER_PORT="3001" \
  postgrest/postgrest
```

**注意**: 如果web_anon角色创建失败，使用`PGRST_DB_ANON_ROLE="aki"`

### 2. 测试PostgREST API

```bash
# 测试根路径
curl http://localhost:3001/

# 测试表
curl http://localhost:3001/players
curl http://localhost:3001/game_sessions

# 测试视图
curl http://localhost:3001/leaderboard
curl http://localhost:3001/game_stats
```

### 3. 更新前端配置

修改`.env`文件：

```env
VITE_USE_POSTGREST=true
VITE_POSTGREST_URL=http://localhost:3001
```

### 4. 重启前端开发服务器

```bash
# 停止当前服务器（Ctrl+C）
# 然后重新启动
npm run dev
```

## 📊 预期结果

执行成功后，你应该看到：

```
✅ 3个表已创建
✅ 2个视图已创建
✅ 5条测试玩家数据
✅ 3条测试游戏会话
✅ 索引已创建
✅ 触发器已创建
```

## 🐛 常见问题

### 问题1: 权限错误
**错误**: `permission denied for schema public`

**解决**: 
- 使用阿里云RDS控制台的SQL窗口（通常有更高权限）
- 或联系管理员授予CREATE权限

### 问题2: 角色创建失败
**错误**: `insufficient privilege to create role`

**解决**: 
- 这是正常的，脚本会跳过角色创建
- PostgREST使用`aki`用户即可

### 问题3: 连接超时
**错误**: `could not connect to server`

**解决**:
- 检查网络连接
- 确认阿里云RDS白名单已添加你的IP
- 使用外网地址而非内网地址

## 📞 获取帮助

如果遇到问题：
1. 检查SQL执行结果中的错误信息
2. 查看`ALIYUN_RDS_PERMISSION_ISSUE.md`
3. 联系阿里云技术支持

## 🎉 完成！

数据库初始化完成后，你的应用架构将是：

```
前端 (React)
  ↓
PostgREST (Docker :3001)
  ↓
阿里云RDS PostgreSQL ✅
  ├─ players 表
  ├─ game_sessions 表
  ├─ answer_combinations 表
  ├─ leaderboard 视图
  └─ game_stats 视图
```

现在可以开始测试完整的应用功能了！
