import express from 'express';
import cors from 'cors';
import pg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const { Pool } = pg;
const app = express();
const PORT = 3001;

// 中间件
app.use(cors());
app.use(express.json());

// 创建数据库连接池
const pool = new Pool({
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT || '5432'),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// 测试数据库连接
pool.query('SELECT NOW()', (err, res) => {
  if (err) {
    console.error('❌ 数据库连接失败:', err.message);
  } else {
    console.log('✅ 数据库连接成功');
  }
});

// 创建或获取玩家
app.post('/api/db/players', async (req, res) => {
  try {
    const { nickname } = req.body;
    
    // 先查找现有玩家
    const existingPlayer = await pool.query(
      'SELECT * FROM players WHERE nickname = $1',
      [nickname]
    );
    
    if (existingPlayer.rows.length > 0) {
      return res.json(existingPlayer.rows[0]);
    }
    
    // 创建新玩家
    const result = await pool.query(
      'INSERT INTO players (nickname) VALUES ($1) RETURNING *',
      [nickname]
    );
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error creating player:', error);
    res.status(500).json({ error: error.message });
  }
});

// 创建游戏会话
app.post('/api/db/sessions', async (req, res) => {
  try {
    const { player_id } = req.body;
    
    const result = await pool.query(
      'INSERT INTO game_sessions (player_id) VALUES ($1) RETURNING *',
      [player_id]
    );
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error creating session:', error);
    res.status(500).json({ error: error.message });
  }
});

// 更新游戏会话
app.patch('/api/db/sessions/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { total_score, combinations_count, completed_at } = req.body;
    
    const result = await pool.query(
      `UPDATE game_sessions 
       SET total_score = $1, combinations_count = $2, completed_at = $3 
       WHERE id = $4 
       RETURNING *`,
      [total_score, combinations_count, completed_at, id]
    );
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error updating session:', error);
    res.status(500).json({ error: error.message });
  }
});

// 创建答案组合
app.post('/api/db/answers', async (req, res) => {
  const client = await pool.connect();
  try {
    const { answers } = req.body;
    
    await client.query('BEGIN');
    
    for (const answer of answers) {
      await client.query(
        `INSERT INTO answer_combinations 
         (session_id, card_ids, ai_marked_card_id, is_grouping_correct, is_ai_detection_correct, score) 
         VALUES ($1, $2, $3, $4, $5, $6)`,
        [
          answer.session_id,
          answer.card_ids,
          answer.ai_marked_card_id,
          answer.is_grouping_correct,
          answer.is_ai_detection_correct,
          answer.score
        ]
      );
    }
    
    await client.query('COMMIT');
    res.json({ success: true });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error creating answers:', error);
    res.status(500).json({ error: error.message });
  } finally {
    client.release();
  }
});

// 获取排行榜
app.get('/api/db/leaderboard', async (req, res) => {
  try {
    const limit = parseInt(req.query.limit || '10');
    const offset = parseInt(req.query.offset || '0');
    
    const result = await pool.query(
      'SELECT * FROM leaderboard LIMIT $1 OFFSET $2',
      [limit, offset]
    );
    
    const countResult = await pool.query(
      'SELECT COUNT(*) FROM (SELECT * FROM leaderboard) as lb'
    );
    
    res.json({
      success: true,
      data: result.rows,
      total: parseInt(countResult.rows[0].count),
      limit,
      offset
    });
  } catch (error) {
    console.error('Error getting leaderboard:', error);
    res.status(500).json({ error: error.message });
  }
});

// 获取游戏统计
app.get('/api/db/stats', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM game_stats');
    
    res.json({
      success: true,
      data: result.rows[0] || {
        total_players: 0,
        average_score: 0,
        highest_score: 0,
        completion_rate: 0,
        ai_detection_accuracy: 0
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error getting stats:', error);
    res.status(500).json({ error: error.message });
  }
});

// 健康检查
app.get('/api/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ status: 'ok', database: 'connected' });
  } catch (error) {
    res.status(500).json({ status: 'error', database: 'disconnected', error: error.message });
  }
});

// 启动服务器
app.listen(PORT, () => {
  console.log(`\n🚀 开发服务器启动成功！`);
  console.log(`📍 地址: http://localhost:${PORT}`);
  console.log(`🔗 API端点: http://localhost:${PORT}/api/db`);
  console.log(`🧪 测试页面: http://localhost:${PORT}/test-db-api.html\n`);
});

// 静态文件服务（用于测试页面）
app.use(express.static('.'));
