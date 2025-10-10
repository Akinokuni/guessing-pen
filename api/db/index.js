import pg from 'pg';

const { Pool } = pg;

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

// 处理请求
export default async function handler(req, res) {
  // 设置CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PATCH, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  const { path } = req.query;
  const route = path ? path.join('/') : '';

  try {
    // 路由处理
    if (route === 'players' && req.method === 'POST') {
      return await handleCreatePlayer(req, res);
    }
    
    if (route === 'sessions' && req.method === 'POST') {
      return await handleCreateSession(req, res);
    }
    
    if (route.startsWith('sessions/') && req.method === 'PATCH') {
      const sessionId = route.split('/')[1];
      return await handleUpdateSession(req, res, sessionId);
    }
    
    if (route === 'answers' && req.method === 'POST') {
      return await handleCreateAnswers(req, res);
    }
    
    if (route === 'leaderboard' && req.method === 'GET') {
      return await handleGetLeaderboard(req, res);
    }
    
    if (route === 'stats' && req.method === 'GET') {
      return await handleGetStats(req, res);
    }

    return res.status(404).json({ error: 'Not found' });
  } catch (error) {
    console.error('API Error:', error);
    return res.status(500).json({ error: error.message });
  }
}

// 创建或获取玩家
async function handleCreatePlayer(req, res) {
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
  
  return res.json(result.rows[0]);
}

// 创建游戏会话
async function handleCreateSession(req, res) {
  const { player_id } = req.body;
  
  const result = await pool.query(
    'INSERT INTO game_sessions (player_id) VALUES ($1) RETURNING *',
    [player_id]
  );
  
  return res.json(result.rows[0]);
}

// 更新游戏会话
async function handleUpdateSession(req, res, sessionId) {
  const { total_score, combinations_count, completed_at } = req.body;
  
  const result = await pool.query(
    `UPDATE game_sessions 
     SET total_score = $1, combinations_count = $2, completed_at = $3 
     WHERE id = $4 
     RETURNING *`,
    [total_score, combinations_count, completed_at, sessionId]
  );
  
  return res.json(result.rows[0]);
}

// 创建答案组合
async function handleCreateAnswers(req, res) {
  const { answers } = req.body;
  
  const client = await pool.connect();
  try {
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
    return res.json({ success: true });
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

// 获取排行榜
async function handleGetLeaderboard(req, res) {
  const limit = parseInt(req.query.limit || '10');
  const offset = parseInt(req.query.offset || '0');
  
  const result = await pool.query(
    'SELECT * FROM leaderboard LIMIT $1 OFFSET $2',
    [limit, offset]
  );
  
  const countResult = await pool.query(
    'SELECT COUNT(*) FROM leaderboard'
  );
  
  return res.json({
    success: true,
    data: result.rows,
    total: parseInt(countResult.rows[0].count),
    limit,
    offset
  });
}

// 获取游戏统计
async function handleGetStats(req, res) {
  const result = await pool.query('SELECT * FROM game_stats');
  
  return res.json({
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
}
