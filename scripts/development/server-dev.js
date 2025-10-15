import express from 'express';
import cors from 'cors';
import pg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const { Pool } = pg;
const app = express();
const PORT = 3005;

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
  connectionTimeoutMillis: 10000,
  query_timeout: 30000,
});

// 数据库连接测试函数
async function testDatabaseConnection() {
  let retries = 3;
  while (retries > 0) {
    try {
      console.log(`🔄 尝试连接数据库... (剩余重试次数: ${retries})`);
      const result = await pool.query('SELECT NOW() as current_time');
      console.log('✅ 数据库连接成功');
      console.log(`📅 数据库时间: ${result.rows[0].current_time}`);
      return true;
    } catch (err) {
      retries--;
      console.error(`❌ 数据库连接失败: ${err.message}`);
      if (retries > 0) {
        console.log(`⏳ 等待3秒后重试...`);
        await new Promise(resolve => setTimeout(resolve, 3000));
      }
    }
  }
  console.error('💥 数据库连接完全失败，请检查配置和网络');
  return false;
}

// API路由
app.get('/api/db/stats', async (req, res) => {
  try {
    console.log('📊 收到统计数据请求');
    const result = await pool.query('SELECT * FROM game_stats');
    
    const stats = result.rows.length > 0 ? result.rows[0] : {
      total_players: 0,
      average_score: 0,
      highest_score: 0,
      completion_rate: 0,
      ai_detection_accuracy: 0
    };
    
    res.json({
      success: true,
      data: stats,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error getting stats:', error);
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/db/leaderboard', async (req, res) => {
  try {
    console.log('🏆 收到排行榜请求');
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

app.get('/api/health', async (req, res) => {
  try {
    console.log('🔍 收到健康检查请求');
    await pool.query('SELECT 1');
    res.json({ 
      status: 'ok', 
      database: 'connected',
      timestamp: new Date().toISOString(),
      port: PORT
    });
  } catch (error) {
    res.status(500).json({ 
      status: 'error', 
      database: 'disconnected', 
      error: error.message 
    });
  }
});

// 提交答案API
app.post('/api/db/players', async (req, res) => {
  try {
    console.log('👤 收到创建玩家请求:', req.body);
    const { nickname } = req.body;
    
    // 检查玩家是否存在
    const existingPlayer = await pool.query(
      'SELECT * FROM players WHERE nickname = $1',
      [nickname]
    );
    
    if (existingPlayer.rows.length > 0) {
      console.log('✅ 玩家已存在:', existingPlayer.rows[0]);
      return res.json(existingPlayer.rows[0]);
    }
    
    // 创建新玩家
    const result = await pool.query(
      'INSERT INTO players (nickname) VALUES ($1) RETURNING *',
      [nickname]
    );
    
    console.log('✅ 创建新玩家:', result.rows[0]);
    res.json(result.rows[0]);
  } catch (error) {
    console.error('❌ Error creating player:', error);
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/db/game_sessions', async (req, res) => {
  try {
    console.log('🎮 收到创建游戏会话请求:', req.body);
    const { player_id } = req.body;
    
    const result = await pool.query(
      'INSERT INTO game_sessions (player_id) VALUES ($1) RETURNING *',
      [player_id]
    );
    
    console.log('✅ 创建游戏会话:', result.rows[0]);
    res.json(result.rows[0]);
  } catch (error) {
    console.error('❌ Error creating game session:', error);
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/db/answer_combinations', async (req, res) => {
  try {
    console.log('📝 收到保存答案组合请求:', req.body);
    const {
      session_id,
      card_ids,
      ai_marked_card_id,
      is_grouping_correct,
      is_ai_detection_correct,
      score
    } = req.body;
    
    const result = await pool.query(
      `INSERT INTO answer_combinations 
       (session_id, card_ids, ai_marked_card_id, is_grouping_correct, is_ai_detection_correct, score) 
       VALUES ($1, $2, $3, $4, $5, $6) 
       RETURNING *`,
      [session_id, card_ids, ai_marked_card_id, is_grouping_correct, is_ai_detection_correct, score]
    );
    
    console.log('✅ 保存答案组合:', result.rows[0]);
    res.json(result.rows[0]);
  } catch (error) {
    console.error('❌ Error saving answer combination:', error);
    res.status(500).json({ error: error.message });
  }
});

app.patch('/api/db/game_sessions', async (req, res) => {
  try {
    console.log('🔄 收到更新游戏会话请求');
    console.log('Query:', req.query);
    console.log('Body:', req.body);
    
    const { id } = req.query;
    const sessionId = id.replace('eq.', '');
    const { total_score, combinations_count, completed_at } = req.body;
    
    const result = await pool.query(
      `UPDATE game_sessions 
       SET total_score = $1, combinations_count = $2, completed_at = $3 
       WHERE id = $4 
       RETURNING *`,
      [total_score, combinations_count, completed_at, sessionId]
    );
    
    console.log('✅ 更新游戏会话:', result.rows[0]);
    res.json(result.rows[0]);
  } catch (error) {
    console.error('❌ Error updating game session:', error);
    res.status(500).json({ error: error.message });
  }
});

// 启动服务器
async function startServer() {
  console.log('\n🚀 启动开发服务器...');
  
  // 测试数据库连接
  const dbConnected = await testDatabaseConnection();
  
  app.listen(PORT, () => {
    console.log(`\n✅ 开发服务器启动成功！`);
    console.log(`📍 地址: http://localhost:${PORT}`);
    console.log(`🔗 API端点: http://localhost:${PORT}/api/db`);
    console.log(`🧪 健康检查: http://localhost:${PORT}/api/health`);
    console.log(`💾 数据库状态: ${dbConnected ? '✅ 已连接' : '❌ 未连接'}\n`);
  });
}

// 优雅关闭
process.on('SIGINT', () => {
  console.log('\n👋 正在关闭服务器...');
  pool.end(() => {
    console.log('💾 数据库连接池已关闭');
    process.exit(0);
  });
});

// 启动服务器
startServer().catch(console.error);