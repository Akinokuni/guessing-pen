-- 阿里云RDS用户专用初始化脚本
-- 在用户自己的schema中创建表（避免public schema权限问题）

-- 创建用户专用schema（如果不存在）
CREATE SCHEMA IF NOT EXISTS aki_schema;

-- 设置搜索路径
SET search_path TO aki_schema;

-- 玩家表
CREATE TABLE IF NOT EXISTS aki_schema.players (
    id SERIAL PRIMARY KEY,
    nickname VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 游戏会话表
CREATE TABLE IF NOT EXISTS aki_schema.game_sessions (
    id SERIAL PRIMARY KEY,
    player_id INTEGER REFERENCES aki_schema.players(id) ON DELETE CASCADE,
    total_score INTEGER DEFAULT 0,
    combinations_count INTEGER DEFAULT 0,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 答案组合表
CREATE TABLE IF NOT EXISTS aki_schema.answer_combinations (
    id SERIAL PRIMARY KEY,
    session_id INTEGER REFERENCES aki_schema.game_sessions(id) ON DELETE CASCADE,
    card_ids TEXT[] NOT NULL,
    ai_marked_card_id TEXT,
    is_grouping_correct BOOLEAN DEFAULT FALSE,
    is_ai_detection_correct BOOLEAN DEFAULT FALSE,
    score INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 排行榜视图
CREATE OR REPLACE VIEW aki_schema.leaderboard AS
SELECT 
    p.nickname,
    gs.total_score,
    gs.combinations_count,
    gs.completed_at,
    ROW_NUMBER() OVER (ORDER BY gs.total_score DESC, gs.completed_at ASC) as rank
FROM aki_schema.game_sessions gs
JOIN aki_schema.players p ON gs.player_id = p.id
WHERE gs.completed_at IS NOT NULL
ORDER BY gs.total_score DESC, gs.completed_at ASC;

-- 游戏统计视图
CREATE OR REPLACE VIEW aki_schema.game_stats AS
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
FROM aki_schema.players p
LEFT JOIN aki_schema.game_sessions gs ON p.id = gs.player_id
LEFT JOIN aki_schema.answer_combinations ac ON gs.id = ac.session_id;

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_players_nickname ON aki_schema.players(nickname);
CREATE INDEX IF NOT EXISTS idx_game_sessions_player_id ON aki_schema.game_sessions(player_id);
CREATE INDEX IF NOT EXISTS idx_game_sessions_score ON aki_schema.game_sessions(total_score DESC);
CREATE INDEX IF NOT EXISTS idx_answer_combinations_session_id ON aki_schema.answer_combinations(session_id);

-- 创建更新时间触发器函数
CREATE OR REPLACE FUNCTION aki_schema.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 为 players 表添加更新时间触发器
DROP TRIGGER IF EXISTS update_players_updated_at ON aki_schema.players;
CREATE TRIGGER update_players_updated_at 
    BEFORE UPDATE ON aki_schema.players 
    FOR EACH ROW 
    EXECUTE FUNCTION aki_schema.update_updated_at_column();

-- 插入测试数据
INSERT INTO aki_schema.players (nickname) VALUES 
    ('测试玩家1'),
    ('测试玩家2'),
    ('AI侦探'),
    ('画师猎人'),
    ('艺术鉴赏家')
ON CONFLICT DO NOTHING;

-- 插入测试游戏会话
INSERT INTO aki_schema.game_sessions (player_id, total_score, combinations_count, completed_at)
SELECT 
    id,
    FLOOR(RANDOM() * 100)::INTEGER,
    9,
    NOW() - (RANDOM() * INTERVAL '7 days')
FROM aki_schema.players
WHERE id <= 3;

-- 完成提示
DO $$
BEGIN
    RAISE NOTICE '✅ 数据库初始化完成！';
    RAISE NOTICE 'Schema: aki_schema';
    RAISE NOTICE '表: players, game_sessions, answer_combinations';
    RAISE NOTICE '视图: leaderboard, game_stats';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  重要：请更新应用配置使用 aki_schema';
END
$$;
