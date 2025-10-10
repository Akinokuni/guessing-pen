-- 阿里云RDS PostgreSQL 初始化脚本
-- 为用户aki创建专用schema

-- 创建schema
CREATE SCHEMA IF NOT EXISTS guessing_pen;

-- 设置搜索路径
SET search_path TO guessing_pen, public;

-- 启用UUID扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" SCHEMA public;

-- 创建角色（如果不存在）
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'web_anon') THEN
        CREATE ROLE web_anon NOLOGIN;
    END IF;
END
$$;

-- 玩家表
CREATE TABLE IF NOT EXISTS guessing_pen.players (
    id UUID DEFAULT public.uuid_generate_v4() PRIMARY KEY,
    nickname VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 游戏会话表
CREATE TABLE IF NOT EXISTS guessing_pen.game_sessions (
    id UUID DEFAULT public.uuid_generate_v4() PRIMARY KEY,
    player_id UUID REFERENCES guessing_pen.players(id) ON DELETE CASCADE,
    total_score INTEGER DEFAULT 0,
    combinations_count INTEGER DEFAULT 0,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 答案组合表
CREATE TABLE IF NOT EXISTS guessing_pen.answer_combinations (
    id UUID DEFAULT public.uuid_generate_v4() PRIMARY KEY,
    session_id UUID REFERENCES guessing_pen.game_sessions(id) ON DELETE CASCADE,
    card_ids TEXT[] NOT NULL,
    ai_marked_card_id TEXT,
    is_grouping_correct BOOLEAN DEFAULT FALSE,
    is_ai_detection_correct BOOLEAN DEFAULT FALSE,
    score INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 排行榜视图
CREATE OR REPLACE VIEW guessing_pen.leaderboard AS
SELECT 
    p.nickname,
    gs.total_score,
    gs.combinations_count,
    gs.completed_at,
    ROW_NUMBER() OVER (ORDER BY gs.total_score DESC, gs.completed_at ASC) as rank
FROM guessing_pen.game_sessions gs
JOIN guessing_pen.players p ON gs.player_id = p.id
WHERE gs.completed_at IS NOT NULL
ORDER BY gs.total_score DESC, gs.completed_at ASC;

-- 游戏统计视图
CREATE OR REPLACE VIEW guessing_pen.game_stats AS
SELECT 
    COUNT(DISTINCT p.id) as total_players,
    ROUND(AVG(gs.total_score), 1) as average_score,
    MAX(gs.total_score) as highest_score,
    ROUND(
        COUNT(CASE WHEN gs.completed_at IS NOT NULL THEN 1 END)::DECIMAL / 
        NULLIF(COUNT(gs.id)::DECIMAL, 0), 2
    ) as completion_rate,
    ROUND(
        AVG(CASE WHEN ac.is_ai_detection_correct THEN 1.0 ELSE 0.0 END), 2
    ) as ai_detection_accuracy
FROM guessing_pen.players p
LEFT JOIN guessing_pen.game_sessions gs ON p.id = gs.player_id
LEFT JOIN guessing_pen.answer_combinations ac ON gs.id = ac.session_id;

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_players_nickname ON guessing_pen.players(nickname);
CREATE INDEX IF NOT EXISTS idx_game_sessions_player_id ON guessing_pen.game_sessions(player_id);
CREATE INDEX IF NOT EXISTS idx_game_sessions_score ON guessing_pen.game_sessions(total_score DESC);
CREATE INDEX IF NOT EXISTS idx_answer_combinations_session_id ON guessing_pen.answer_combinations(session_id);

-- 创建更新时间触发器函数
CREATE OR REPLACE FUNCTION guessing_pen.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为 players 表添加更新时间触发器
DROP TRIGGER IF EXISTS update_players_updated_at ON guessing_pen.players;
CREATE TRIGGER update_players_updated_at 
    BEFORE UPDATE ON guessing_pen.players 
    FOR EACH ROW 
    EXECUTE FUNCTION guessing_pen.update_updated_at_column();

-- 授予 web_anon 角色权限
GRANT USAGE ON SCHEMA guessing_pen TO web_anon;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA guessing_pen TO web_anon;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA guessing_pen TO web_anon;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA guessing_pen TO web_anon;

-- 为未来创建的对象设置默认权限
ALTER DEFAULT PRIVILEGES IN SCHEMA guessing_pen GRANT SELECT, INSERT, UPDATE ON TABLES TO web_anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA guessing_pen GRANT SELECT ON SEQUENCES TO web_anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA guessing_pen GRANT EXECUTE ON FUNCTIONS TO web_anon;

-- 插入测试数据
INSERT INTO guessing_pen.players (nickname) VALUES ('测试玩家1'), ('测试玩家2')
ON CONFLICT DO NOTHING;

-- 完成提示
DO $$
BEGIN
    RAISE NOTICE '数据库初始化完成！';
    RAISE NOTICE 'Schema: guessing_pen';
    RAISE NOTICE '表: players, game_sessions, answer_combinations';
    RAISE NOTICE '视图: leaderboard, game_stats';
END
$$;
