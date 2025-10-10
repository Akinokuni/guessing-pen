# 手动创建数据库表 - 分步指南

## 📋 前提条件

你需要有一个**高权限账号**。如果没有，请先在阿里云RDS控制台创建。

## 🔧 创建步骤

### 步骤1: 创建 players 表

```sql
CREATE TABLE players (
    id SERIAL PRIMARY KEY,
    nickname VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**验证**:
```sql
SELECT * FROM players;
```

---

### 步骤2: 创建 game_sessions 表

```sql
CREATE TABLE game_sessions (
    id SERIAL PRIMARY KEY,
    player_id INTEGER REFERENCES players(id) ON DELETE CASCADE,
    total_score INTEGER DEFAULT 0,
    combinations_count INTEGER DEFAULT 0,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**验证**:
```sql
SELECT * FROM game_sessions;
```

---

### 步骤3: 创建 answer_combinations 表

```sql
CREATE TABLE answer_combinations (
    id SERIAL PRIMARY KEY,
    session_id INTEGER REFERENCES game_sessions(id) ON DELETE CASCADE,
    card_ids TEXT[] NOT NULL,
    ai_marked_card_id TEXT,
    is_grouping_correct BOOLEAN DEFAULT FALSE,
    is_ai_detection_correct BOOLEAN DEFAULT FALSE,
    score INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**验证**:
```sql
SELECT * FROM answer_combinations;
```

---

### 步骤4: 创建 leaderboard 视图

```sql
CREATE VIEW leaderboard AS
SELECT 
    p.nickname,
    gs.total_score,
    gs.combinations_count,
    gs.completed_at,
    ROW_NUMBER() OVER (ORDER BY gs.total_score DESC, gs.completed_at ASC) as rank
FROM game_sessions gs
JOIN players p ON gs.player_id = p.id
WHERE gs.completed_at IS NOT NULL
ORDER BY gs.total_score DESC, gs.completed_at ASC;
```

**验证**:
```sql
SELECT * FROM leaderboard;
```

---

### 步骤5: 创建 game_stats 视图

```sql
CREATE VIEW game_stats AS
SELECT 
    COUNT(DISTINCT p.id) as total_players,
    ROUND(AVG(gs.total_score), 1) as average_score,
    MAX(gs.total_score) as highest_score,
    ROUND(
        COALESCE(
            COUNT(CASE WHEN gs.completed_at IS NOT NULL THEN 1 END)::DECIMAL / 
            NULLIF(COUNT(gs.id)::DECIMAL, 0),
            0
        ), 2
    ) as completion_rate,
    ROUND(
        COALESCE(
            AVG(CASE WHEN ac.is_ai_detection_correct THEN 1.0 ELSE 0.0 END),
            0
        ), 2
    ) as ai_detection_accuracy
FROM players p
LEFT JOIN game_sessions gs ON p.id = gs.player_id
LEFT JOIN answer_combinations ac ON gs.id = ac.session_id;
```

**验证**:
```sql
SELECT * FROM game_stats;
```

---

### 步骤6: 创建索引

```sql
-- 玩家昵称索引
CREATE INDEX idx_players_nickname ON players(nickname);

-- 游戏会话玩家ID索引
CREATE INDEX idx_game_sessions_player_id ON game_sessions(player_id);

-- 游戏会话分数索引
CREATE INDEX idx_game_sessions_score ON game_sessions(total_score DESC);

-- 答案组合会话ID索引
CREATE INDEX idx_answer_combinations_session_id ON answer_combinations(session_id);
```

**验证**:
```sql
SELECT indexname FROM pg_indexes WHERE schemaname = 'public';
```

---

### 步骤7: 创建触发器函数

```sql
CREATE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

**验证**:
```sql
SELECT proname FROM pg_proc WHERE proname = 'update_updated_at_column';
```

---

### 步骤8: 添加触发器到 players 表

```sql
CREATE TRIGGER update_players_updated_at 
    BEFORE UPDATE ON players 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();
```

**验证**:
```sql
SELECT tgname FROM pg_trigger WHERE tgname = 'update_players_updated_at';
```

---

### 步骤9: 插入测试数据

```sql
-- 插入测试玩家
INSERT INTO players (nickname) VALUES 
    ('测试玩家1'),
    ('测试玩家2'),
    ('AI侦探'),
    ('画师猎人'),
    ('艺术鉴赏家');
```

**验证**:
```sql
SELECT * FROM players;
```

---

### 步骤10: 插入测试游戏会话

```sql
INSERT INTO game_sessions (player_id, total_score, combinations_count, completed_at)
VALUES 
    (1, 85, 9, NOW() - INTERVAL '1 day'),
    (2, 72, 9, NOW() - INTERVAL '2 days'),
    (3, 90, 9, NOW() - INTERVAL '3 days');
```

**验证**:
```sql
SELECT * FROM game_sessions;
SELECT * FROM leaderboard;
SELECT * FROM game_stats;
```

---

### 步骤11: 授予 aki 用户权限（如果使用高权限账号创建）

```sql
-- 授予aki用户所有权限
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO aki;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO aki;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO aki;

-- 设置默认权限
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO aki;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO aki;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO aki;
```

---

## ✅ 最终验证

执行以下SQL确认所有对象都已创建：

```sql
-- 检查表
SELECT tablename FROM pg_tables 
WHERE schemaname = 'public' 
ORDER BY tablename;

-- 应该看到:
-- answer_combinations
-- game_sessions
-- players

-- 检查视图
SELECT viewname FROM pg_views 
WHERE schemaname = 'public' 
ORDER BY viewname;

-- 应该看到:
-- game_stats
-- leaderboard

-- 检查数据
SELECT COUNT(*) as player_count FROM players;
SELECT COUNT(*) as session_count FROM game_sessions;

-- 测试视图
SELECT * FROM leaderboard;
SELECT * FROM game_stats;
```

---

## 🎉 完成！

如果所有步骤都成功执行，你应该看到：

- ✅ 3个表: players, game_sessions, answer_combinations
- ✅ 2个视图: leaderboard, game_stats
- ✅ 4个索引
- ✅ 1个触发器函数
- ✅ 1个触发器
- ✅ 5条测试玩家数据
- ✅ 3条测试游戏会话数据

现在可以继续配置PostgREST了！
