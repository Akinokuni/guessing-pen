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