-- ============================================
-- 猜猜笔挑战 - 手动数据库初始化脚本
-- 适用于阿里云RDS PostgreSQL
-- 请在阿里云RDS控制台的SQL窗口中执行
-- ============================================

-- 第一步：创建角色（如果权限允许）
-- 如果执行失败，可以跳过这一步
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'web_anon') THEN
        CREATE ROLE web_anon NOLOGIN;
    END IF;
EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'Skipping role creation due to insufficient privileges';
END
$$;

-- 第二步：创建表

-- 玩家表
CREATE TABLE IF NOT EXISTS players (
    id SERIAL PRIMARY KEY,
    nickname VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 游戏会话表
CREATE TABLE IF NOT EXISTS game_sessions (
    id SERIAL PRIMARY KEY,
    player_id INTEGER REFERENCES players(id) ON DELETE CASCADE,
    total_score INTEGER DEFAULT 0,
    combinations_count INTEGER DEFAULT 0,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 答案组合表
CREATE TABLE IF NOT EXISTS answer_combinations (
    id SERIAL PRIMARY KEY,
    session_id INTEGER REFERENCES game_sessions(id) ON DELETE CASCADE,
    card_ids TEXT[] NOT NULL,
    ai_marked_card_id TEXT,
    is_grouping_correct BOOLEAN DEFAULT FALSE,
    is_ai_detection_correct BOOLEAN DEFAULT FALSE,
    score INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 第三步：创建视图

-- 排行榜视图
CREATE OR REPLACE VIEW leaderboard AS
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

-- 游戏统计视图
CREATE OR REPLACE VIEW game_stats AS
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

-- 第四步：创建索引

CREATE INDEX IF NOT EXISTS idx_players_nickname ON players(nickname);
CREATE INDEX IF NOT EXISTS idx_game_sessions_player_id ON game_sessions(player_id);
CREATE INDEX IF NOT EXISTS idx_game_sessions_score ON game_sessions(total_score DESC);
CREATE INDEX IF NOT EXISTS idx_answer_combinations_session_id ON answer_combinations(session_id);

-- 第五步：创建触发器函数

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 为 players 表添加更新时间触发器
DROP TRIGGER IF EXISTS update_players_updated_at ON players;
CREATE TRIGGER update_players_updated_at 
    BEFORE UPDATE ON players 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- 第六步：授予权限（如果web_anon角色存在）

DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'web_anon') THEN
        GRANT USAGE ON SCHEMA public TO web_anon;
        GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO web_anon;
        GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA public TO web_anon;
        GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO web_anon;
        
        ALTER DEFAULT PRIVILEGES IN SCHEMA public 
            GRANT SELECT, INSERT, UPDATE ON TABLES TO web_anon;
        ALTER DEFAULT PRIVILEGES IN SCHEMA public 
            GRANT SELECT, USAGE ON SEQUENCES TO web_anon;
        ALTER DEFAULT PRIVILEGES IN SCHEMA public 
            GRANT EXECUTE ON FUNCTIONS TO web_anon;
    END IF;
EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'Skipping permission grants due to insufficient privileges';
END
$$;

-- 第七步：插入测试数据

INSERT INTO players (nickname) VALUES 
    ('测试玩家1'),
    ('测试玩家2'),
    ('AI侦探'),
    ('画师猎人'),
    ('艺术鉴赏家')
ON CONFLICT DO NOTHING;

-- 插入一些测试游戏会话
INSERT INTO game_sessions (player_id, total_score, combinations_count, completed_at)
SELECT 
    id,
    FLOOR(RANDOM() * 100)::INTEGER,
    9,
    NOW() - (RANDOM() * INTERVAL '7 days')
FROM players
WHERE id <= 3;

-- 第八步：验证安装

-- 检查表
SELECT 'Tables created:' as status;
SELECT tablename FROM pg_tables WHERE schemaname = 'public' 
    AND tablename IN ('players', 'game_sessions', 'answer_combinations');

-- 检查视图
SELECT 'Views created:' as status;
SELECT viewname FROM pg_views WHERE schemaname = 'public' 
    AND viewname IN ('leaderboard', 'game_stats');

-- 检查数据
SELECT 'Sample data:' as status;
SELECT COUNT(*) as player_count FROM players;
SELECT COUNT(*) as session_count FROM game_sessions;

-- 测试视图
SELECT 'Testing leaderboard view:' as status;
SELECT * FROM leaderboard LIMIT 5;

SELECT 'Testing game_stats view:' as status;
SELECT * FROM game_stats;

-- 完成
SELECT '✅ Database initialization completed successfully!' as status;
