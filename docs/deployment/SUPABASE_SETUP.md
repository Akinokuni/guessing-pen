# Supabase 数据库设置指南

## 概述

本项目支持两种数据库部署方式：
1. **Supabase 云服务**（推荐用于生产环境）
2. **本地 Docker 数据库**（适用于开发和测试）

## 方式一：使用 Supabase 云服务

### 1. 创建 Supabase 项目

1. 访问 [Supabase](https://supabase.com)
2. 注册账号并登录
3. 点击 "New Project" 创建新项目
4. 填写项目信息：
   - Name: `guessing-pen-challenge`
   - Database Password: 设置一个强密码
   - Region: 选择离用户最近的区域

### 2. 获取项目配置

项目创建完成后，在项目设置页面获取：
- **Project URL**: `https://your-project-id.supabase.co`
- **API Key (anon public)**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

### 3. 配置环境变量

在 `.env` 文件中设置：

```env
# Supabase 配置
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# 前端环境变量
VITE_SUPABASE_URL=https://your-project-id.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
VITE_USE_SUPABASE=true
```

### 4. 执行数据库迁移

#### 方法 A：使用 Supabase CLI（推荐）

1. 安装 Supabase CLI：
   ```bash
   npm install -g supabase
   ```

2. 登录 Supabase：
   ```bash
   supabase login
   ```

3. 链接到你的项目：
   ```bash
   supabase link --project-ref your-project-id
   ```

4. 推送数据库架构：
   ```bash
   supabase db push
   ```

#### 方法 B：手动执行 SQL

1. 打开 Supabase 项目的 SQL Editor
2. 复制 `supabase/migrations/001_initial_schema.sql` 的内容
3. 粘贴并执行 SQL 语句

### 5. 验证设置

1. 在 Supabase 项目的 Table Editor 中检查是否创建了以下表：
   - `players`
   - `game_sessions`
   - `answer_combinations`

2. 检查是否创建了视图：
   - `leaderboard`
   - `game_stats`

## 方式二：使用本地 Docker 数据库

### 1. 启动本地数据库

```bash
# Linux/macOS
./deploy.sh dev

# Windows
deploy.bat
# 然后手动运行：docker-compose --profile dev up -d
```

### 2. 配置环境变量

在 `.env` 文件中设置：

```env
# 本地数据库配置
POSTGRES_PASSWORD=your-super-secret-and-long-postgres-password
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=your-local-anon-key

# 前端环境变量
VITE_SUPABASE_URL=http://localhost:54321
VITE_SUPABASE_ANON_KEY=your-local-anon-key
VITE_USE_SUPABASE=true
```

### 3. 数据库连接信息

- **主机**: localhost
- **端口**: 54322
- **数据库**: postgres
- **用户名**: postgres
- **密码**: 在 `.env` 文件中的 `POSTGRES_PASSWORD`

## 数据库架构说明

### 表结构

#### players 表
- `id`: UUID 主键
- `nickname`: 玩家昵称
- `created_at`: 创建时间
- `updated_at`: 更新时间

#### game_sessions 表
- `id`: UUID 主键
- `player_id`: 玩家ID（外键）
- `total_score`: 总分
- `combinations_count`: 组合数量
- `completed_at`: 完成时间
- `created_at`: 创建时间

#### answer_combinations 表
- `id`: UUID 主键
- `session_id`: 游戏会话ID（外键）
- `card_ids`: 卡片ID数组
- `ai_marked_card_id`: AI标记的卡片ID
- `is_grouping_correct`: 分组是否正确
- `is_ai_detection_correct`: AI检测是否正确
- `score`: 得分
- `created_at`: 创建时间

### 视图

#### leaderboard 视图
显示排行榜信息，包括玩家昵称、总分、排名等。

#### game_stats 视图
显示游戏统计信息，包括总玩家数、平均分、最高分等。

## 故障排除

### 常见问题

1. **连接失败**
   - 检查网络连接
   - 验证 URL 和 API Key 是否正确
   - 确认 Supabase 项目状态正常

2. **权限错误**
   - 检查 RLS（行级安全）策略
   - 确认 API Key 权限设置

3. **迁移失败**
   - 检查 SQL 语法
   - 确认数据库版本兼容性
   - 查看 Supabase 项目日志

### 获取帮助

- [Supabase 官方文档](https://supabase.com/docs)
- [Supabase 社区](https://github.com/supabase/supabase/discussions)
- 项目 Issues 页面