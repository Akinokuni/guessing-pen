import pg from 'pg';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

const { Client } = pg;
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

dotenv.config({ path: path.join(__dirname, '..', '.env') });

async function checkDatabase() {
  const client = new Client({
    host: process.env.DB_HOST,
    port: parseInt(process.env.DB_PORT || '5432'),
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false
  });

  try {
    console.log('🔌 连接到数据库...');
    await client.connect();
    console.log('✅ 连接成功！\n');

    // 检查可用的数据库
    console.log('📋 检查可用的数据库:');
    const databases = await client.query(`
      SELECT datname FROM pg_database 
      WHERE datistemplate = false 
      ORDER BY datname
    `);
    databases.rows.forEach(row => {
      console.log(`   - ${row.datname}`);
    });

    // 检查当前用户权限
    console.log('\n👤 当前用户信息:');
    const userInfo = await client.query(`
      SELECT 
        current_user as username,
        current_database() as database,
        current_schema() as schema
    `);
    console.log(`   用户: ${userInfo.rows[0].username}`);
    console.log(`   数据库: ${userInfo.rows[0].database}`);
    console.log(`   默认Schema: ${userInfo.rows[0].schema}`);

    // 检查用户拥有的schema
    console.log('\n📁 可用的Schema:');
    const schemas = await client.query(`
      SELECT schema_name 
      FROM information_schema.schemata 
      WHERE schema_name NOT IN ('pg_catalog', 'information_schema', 'pg_toast')
      ORDER BY schema_name
    `);
    schemas.rows.forEach(row => {
      console.log(`   - ${row.schema_name}`);
    });

    // 检查创建schema的权限
    console.log('\n🔐 测试权限:');
    try {
      await client.query('CREATE SCHEMA IF NOT EXISTS test_schema_temp');
      await client.query('DROP SCHEMA test_schema_temp');
      console.log('   ✅ 可以创建Schema');
    } catch (err) {
      console.log(`   ❌ 无法创建Schema: ${err.message}`);
    }

    // 检查是否已有游戏表
    console.log('\n🎮 检查现有游戏表:');
    const tables = await client.query(`
      SELECT schemaname, tablename 
      FROM pg_tables 
      WHERE tablename IN ('players', 'game_sessions', 'answer_combinations')
      ORDER BY schemaname, tablename
    `);
    
    if (tables.rows.length > 0) {
      console.log('   已存在的表:');
      tables.rows.forEach(row => {
        console.log(`   ✓ ${row.schemaname}.${row.tablename}`);
      });
    } else {
      console.log('   ℹ️  未找到游戏表');
    }

  } catch (error) {
    console.error('❌ 错误:', error.message);
    if (error.code) {
      console.error(`   错误代码: ${error.code}`);
    }
  } finally {
    await client.end();
  }
}

checkDatabase();
