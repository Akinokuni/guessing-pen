# 🚀 数据库快速启动指南

## 当前状态

✅ **数据库已初始化完成**
✅ **所有测试通过**
⏳ **等待配置RDS白名单**

## 一键命令

### 验证数据库
```bash
npm run db:verify
```

### 测试应用连接
```bash
npm run db:test
```

### 检查数据库状态
```bash
npm run db:check
```

### 启动API开发服务器
```bash
npm run dev:api
```

## 配置RDS白名单（重要！）

### 步骤1：获取你的IP地址
```bash
# Windows
curl ifconfig.me

# 或访问
# https://www.whatismyip.com/
```

### 步骤2：配置阿里云RDS
1. 访问：https://rdsnext.console.aliyun.com/
2. 找到实例：`pgm-wz9z6i202l2p25wvco`
3. 点击"数据安全性" → "白名单设置"
4. 点击"修改"
5. 添加你的IP地址（或 `0.0.0.0/0` 用于测试）
6. 点击"确定"

### 步骤3：测试连接
```bash
npm run dev:api
```

访问：http://localhost:3001/test-db-api.html

## 测试结果

### 已通过的测试 ✅

```bash
$ npm run db:test

🧪 测试应用数据库连接
============================================================

📌 测试 1: 数据库连接
   ✅ 连接成功

📌 测试 2: 创建新玩家
   ✅ 玩家创建成功

📌 测试 3: 创建游戏会话
   ✅ 会话创建成功

📌 测试 4: 添加答案组合
   ✅ 答案组合创建成功

📌 测试 5: 更新游戏会话
   ✅ 会话更新成功

📌 测试 6: 查询排行榜
   ✅ 排行榜查询成功

📌 测试 7: 查询游戏统计
   ✅ 统计查询成功

📌 测试 8: 查询玩家游戏历史
   ✅ 历史查询成功

📌 测试 9: 事务处理
   ✅ 事务回滚成功

📌 测试 10: 清理测试数据
   ✅ 测试数据清理成功

============================================================
🎉 所有测试通过！
============================================================
```

## 当前数据

```bash
$ npm run db:verify

✅ 数据库连接成功

👥 玩家列表:
   1. 测试玩家1
   2. 测试玩家2
   3. AI侦探
   4. 画师猎人

🏆 排行榜:
   1. 测试玩家2 - 68分 (9组)
   2. 测试玩家1 - 48分 (9组)
   3. AI侦探 - 32分 (9组)

📊 游戏统计:
   总玩家数: 4
   平均分数: 49.3
   最高分数: 68
   完成率: 100%
```

## 数据库信息

```
主机: pgm-wz9z6i202l2p25wvco.pg.rds.aliyuncs.com
端口: 5432
数据库: aki
用户: aki
Schema: public
```

## 表结构

### players（玩家表）
- id (SERIAL)
- nickname (VARCHAR)
- created_at, updated_at (TIMESTAMP)

### game_sessions（游戏会话表）
- id (SERIAL)
- player_id (外键)
- total_score, combinations_count (INTEGER)
- completed_at, created_at (TIMESTAMP)

### answer_combinations（答案组合表）
- id (SERIAL)
- session_id (外键)
- card_ids (TEXT[])
- ai_marked_card_id (TEXT)
- is_grouping_correct, is_ai_detection_correct (BOOLEAN)
- score (INTEGER)
- created_at (TIMESTAMP)

### leaderboard（排行榜视图）
- nickname, total_score, combinations_count
- completed_at, rank

### game_stats（统计视图）
- total_players, average_score, highest_score
- completion_rate, ai_detection_accuracy

## 下一步

### 1. 配置白名单后
```bash
# 启动API服务器
npm run dev:api

# 在浏览器打开
# http://localhost:3001/test-db-api.html
```

### 2. 集成到应用
更新 `.env`：
```env
VITE_USE_DIRECT_DB=true
```

### 3. 部署到生产
```bash
# 安装Vercel CLI
npm install -g vercel

# 部署
vercel --prod
```

## 故障排查

### 问题：连接超时
```
❌ Connection terminated due to connection timeout
```

**解决**：配置阿里云RDS白名单

### 问题：权限错误
```
❌ permission denied for schema public
```

**解决**：确保使用 `aki` 数据库（已配置）

### 问题：找不到表
```
❌ relation "players" does not exist
```

**解决**：运行初始化脚本
```bash
npm run db:init
```

## 有用的链接

- 📖 [完整文档](./APPLICATION_CONNECTION_READY.md)
- 🔍 [测试报告](./DATABASE_CONNECTION_TEST_REPORT.md)
- ✅ [初始化报告](./DATABASE_INIT_SUCCESS.md)
- 🗄️ [数据库设计](./database/DATABASE_DESIGN.md)

## 联系支持

如果遇到问题：
1. 检查 `.env` 配置
2. 运行 `npm run db:check`
3. 查看错误日志
4. 参考故障排查部分

---

**准备就绪！** 🎉 配置白名单后即可开始使用。
