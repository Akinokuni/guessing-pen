import pg from 'pg';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import dotenv from 'dotenv';

const { Client } = pg;
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// 从 .env 文件读取配置
dotenv.config({ path: path.join(__dirname, '..', '.env') });

const client = new Client({
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT || '5432'),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false
});

async function initDatabase() {
  try {
    console.log('🔌 连接到数据库...');
    console.log(`   主机: ${process.env.DB_HOST}`);
    console.log(`   数据库: ${process.env.DB_NAME}`);
    console.log(`   用户: ${process.env.DB_USER}`);
    
    await client.connect();
    console.log('✅ 数据库连接成功！\n');

    // 读取 SQL 文件
    const sqlFile = path.join(__dirname, 'init_simple.sql');
    const sql = fs.readFileSync(sqlFile, 'utf8');
    
    console.log('📝 执行初始化脚本...');
    
    // 执行 SQL
    await client.query(sql);
    
    console.log('✅ 数据库初始化完成！\n');
    
    // 验证表是否创建成功
    console.log('🔍 验证数据库结构...');
    const tables = await client.query(`
      SELECT tablename 
      FROM pg_tables 
      WHERE schemaname = 'public' 
      AND tablename IN ('players', 'game_sessions', 'answer_combinations')
      ORDER BY tablename
    `);
    
    console.log('   已创建的表:');
    tables.rows.forEach(row => {
      console.log(`   ✓ ${row.tablename}`);
    });
    
    // 检查视图
    const views = await client.query(`
      SELECT viewname 
      FROM pg_views 
      WHERE schemaname = 'public' 
      AND viewname IN ('leaderboard', 'game_stats')
      ORDER BY viewname
    `);
    
    console.log('\n   已创建的视图:');
    views.rows.forEach(row => {
      console.log(`   ✓ ${row.viewname}`);
    });
    
    // 检查测试数据
    const playerCount = await client.query('SELECT COUNT(*) as count FROM players');
    console.log(`\n   测试数据: ${playerCount.rows[0].count} 个玩家`);
    
    console.log('\n🎉 数据库初始化成功完成！');
    
  } catch (error) {
    console.error('❌ 数据库初始化失败:');
    console.error(error.message);
    if (error.code) {
      console.error(`   错误代码: ${error.code}`);
    }
    process.exit(1);
  } finally {
    await client.end();
  }
}

initDatabase();
