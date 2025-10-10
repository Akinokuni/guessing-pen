import pg from 'pg';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

const { Client } = pg;
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

dotenv.config({ path: path.join(__dirname, '..', '.env') });

console.log('🧪 测试应用数据库连接\n');
console.log('=' .repeat(60));

async function testConnection() {
  const client = new Client({
    host: process.env.DB_HOST,
    port: parseInt(process.env.DB_PORT || '5432'),
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false
  });

  try {
    // 测试1: 基本连接
    console.log('\n📌 测试 1: 数据库连接');
    await client.connect();
    console.log('   ✅ 连接成功');
    console.log(`   主机: ${process.env.DB_HOST}`);
    console.log(`   数据库: ${process.env.DB_NAME}`);
    console.log(`   用户: ${process.env.DB_USER}`);

    // 测试2: 创建新玩家
    console.log('\n📌 测试 2: 创建新玩家');
    const newPlayer = await client.query(
      'INSERT INTO players (nickname) VALUES ($1) RETURNING *',
      ['测试连接玩家']
    );
    console.log(`   ✅ 玩家创建成功`);
    console.log(`   ID: ${newPlayer.rows[0].id}`);
    console.log(`   昵称: ${newPlayer.rows[0].nickname}`);

    // 测试3: 创建游戏会话
    console.log('\n📌 测试 3: 创建游戏会话');
    const newSession = await client.query(
      'INSERT INTO game_sessions (player_id, total_score, combinations_count) VALUES ($1, $2, $3) RETURNING *',
      [newPlayer.rows[0].id, 0, 0]
    );
    console.log(`   ✅ 会话创建成功`);
    console.log(`   会话ID: ${newSession.rows[0].id}`);

    // 测试4: 添加答案组合
    console.log('\n📌 测试 4: 添加答案组合');
    const newAnswer = await client.query(
      `INSERT INTO answer_combinations 
       (session_id, card_ids, ai_marked_card_id, is_grouping_correct, is_ai_detection_correct, score) 
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
      [newSession.rows[0].id, ['card1', 'card2', 'card3'], 'card2', true, true, 10]
    );
    console.log(`   ✅ 答案组合创建成功`);
    console.log(`   组合ID: ${newAnswer.rows[0].id}`);
    console.log(`   得分: ${newAnswer.rows[0].score}`);

    // 测试5: 更新游戏会话分数
    console.log('\n📌 测试 5: 更新游戏会话');
    await client.query(
      'UPDATE game_sessions SET total_score = $1, combinations_count = $2, completed_at = NOW() WHERE id = $3',
      [10, 1, newSession.rows[0].id]
    );
    console.log(`   ✅ 会话更新成功`);

    // 测试6: 查询排行榜
    console.log('\n📌 测试 6: 查询排行榜');
    const leaderboard = await client.query('SELECT * FROM leaderboard LIMIT 3');
    console.log(`   ✅ 排行榜查询成功`);
    console.log(`   前3名:`);
    leaderboard.rows.forEach(row => {
      console.log(`      ${row.rank}. ${row.nickname} - ${row.total_score}分`);
    });

    // 测试7: 查询游戏统计
    console.log('\n📌 测试 7: 查询游戏统计');
    const stats = await client.query('SELECT * FROM game_stats');
    console.log(`   ✅ 统计查询成功`);
    const s = stats.rows[0];
    console.log(`   总玩家: ${s.total_players}`);
    console.log(`   平均分: ${s.average_score}`);
    console.log(`   最高分: ${s.highest_score}`);

    // 测试8: 查询玩家的游戏历史
    console.log('\n📌 测试 8: 查询玩家游戏历史');
    const history = await client.query(
      `SELECT gs.*, 
              (SELECT COUNT(*) FROM answer_combinations WHERE session_id = gs.id) as answer_count
       FROM game_sessions gs 
       WHERE player_id = $1 
       ORDER BY created_at DESC`,
      [newPlayer.rows[0].id]
    );
    console.log(`   ✅ 历史查询成功`);
    console.log(`   游戏次数: ${history.rows.length}`);

    // 测试9: 测试事务
    console.log('\n📌 测试 9: 事务处理');
    await client.query('BEGIN');
    try {
      await client.query(
        'INSERT INTO players (nickname) VALUES ($1)',
        ['事务测试玩家']
      );
      await client.query('ROLLBACK');
      console.log(`   ✅ 事务回滚成功`);
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    }

    // 测试10: 清理测试数据
    console.log('\n📌 测试 10: 清理测试数据');
    await client.query('DELETE FROM players WHERE id = $1', [newPlayer.rows[0].id]);
    console.log(`   ✅ 测试数据清理成功`);

    // 最终报告
    console.log('\n' + '='.repeat(60));
    console.log('🎉 所有测试通过！');
    console.log('='.repeat(60));
    console.log('\n✅ 应用可以正常连接和操作数据库');
    console.log('✅ 所有CRUD操作正常');
    console.log('✅ 视图查询正常');
    console.log('✅ 事务处理正常');
    console.log('\n💡 下一步: 启动应用进行完整测试');

  } catch (error) {
    console.error('\n❌ 测试失败:', error.message);
    console.error('错误详情:', error);
    process.exit(1);
  } finally {
    await client.end();
  }
}

testConnection();
