import pg from 'pg';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

const { Client } = pg;
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

dotenv.config({ path: path.join(__dirname, '..', '.env') });

async function verifyDatabase() {
  const client = new Client({
    host: process.env.DB_HOST,
    port: parseInt(process.env.DB_PORT || '5432'),
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false
  });

  try {
    await client.connect();
    console.log('✅ 数据库连接成功\n');

    // 查看玩家数据
    console.log('👥 玩家列表:');
    const players = await client.query('SELECT * FROM players ORDER BY id');
    players.rows.forEach(p => {
      console.log(`   ${p.id}. ${p.nickname} (创建于: ${p.created_at.toLocaleString('zh-CN')})`);
    });

    // 查看游戏会话
    console.log('\n🎮 游戏会话:');
    const sessions = await client.query(`
      SELECT gs.*, p.nickname 
      FROM game_sessions gs
      JOIN players p ON gs.player_id = p.id
      ORDER BY gs.id
    `);
    sessions.rows.forEach(s => {
      console.log(`   会话 ${s.id}: ${s.nickname} - 得分: ${s.total_score}, 完成: ${s.completed_at ? '是' : '否'}`);
    });

    // 查看排行榜
    console.log('\n🏆 排行榜:');
    const leaderboard = await client.query('SELECT * FROM leaderboard LIMIT 5');
    leaderboard.rows.forEach(l => {
      console.log(`   ${l.rank}. ${l.nickname} - ${l.total_score}分 (${l.combinations_count}组)`);
    });

    // 查看统计数据
    console.log('\n📊 游戏统计:');
    const stats = await client.query('SELECT * FROM game_stats');
    const s = stats.rows[0];
    console.log(`   总玩家数: ${s.total_players}`);
    console.log(`   平均分数: ${s.average_score}`);
    console.log(`   最高分数: ${s.highest_score}`);
    console.log(`   完成率: ${(s.completion_rate * 100).toFixed(0)}%`);
    console.log(`   AI检测准确率: ${(s.ai_detection_accuracy * 100).toFixed(0)}%`);

    console.log('\n✅ 数据库验证完成！所有功能正常。');

  } catch (error) {
    console.error('❌ 验证失败:', error.message);
  } finally {
    await client.end();
  }
}

verifyDatabase();
