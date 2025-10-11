import { Request, Response } from 'express';
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
  connectionTimeoutMillis: 10000,
  query_timeout: 30000,
});

// 健康检查状态接口
interface HealthStatus {
  status: 'ok' | 'degraded' | 'error';
  timestamp: string;
  uptime: number;
  version: string;
  services: {
    database: {
      status: 'connected' | 'disconnected' | 'slow';
      responseTime?: number;
      error?: string;
    };
    memory: {
      used: number;
      total: number;
      percentage: number;
    };
    cpu: {
      usage: number;
    };
  };
  environment: string;
}

// 检查数据库连接
async function checkDatabaseHealth(): Promise<{
  status: 'connected' | 'disconnected' | 'slow';
  responseTime?: number;
  error?: string;
}> {
  const startTime = Date.now();
  
  try {
    await pool.query('SELECT 1');
    const responseTime = Date.now() - startTime;
    
    return {
      status: responseTime > 1000 ? 'slow' : 'connected',
      responseTime
    };
  } catch (error) {
    return {
      status: 'disconnected',
      responseTime: Date.now() - startTime,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

// 获取内存使用情况
function getMemoryUsage() {
  const memUsage = process.memoryUsage();
  const totalMemory = memUsage.heapTotal;
  const usedMemory = memUsage.heapUsed;
  
  return {
    used: Math.round(usedMemory / 1024 / 1024), // MB
    total: Math.round(totalMemory / 1024 / 1024), // MB
    percentage: Math.round((usedMemory / totalMemory) * 100)
  };
}

// 获取CPU使用情况（简化版）
function getCpuUsage() {
  const cpuUsage = process.cpuUsage();
  const totalUsage = cpuUsage.user + cpuUsage.system;
  
  return {
    usage: Math.round(totalUsage / 1000000) // 转换为毫秒
  };
}

// 基础健康检查端点
export async function healthCheck(req: Request, res: Response) {
  try {
    const startTime = Date.now();
    
    // 检查数据库
    const dbHealth = await checkDatabaseHealth();
    
    // 获取系统信息
    const memoryInfo = getMemoryUsage();
    const cpuInfo = getCpuUsage();
    
    // 确定整体状态
    let overallStatus: 'ok' | 'degraded' | 'error' = 'ok';
    
    if (dbHealth.status === 'disconnected') {
      overallStatus = 'error';
    } else if (dbHealth.status === 'slow' || memoryInfo.percentage > 80) {
      overallStatus = 'degraded';
    }
    
    const healthStatus: HealthStatus = {
      status: overallStatus,
      timestamp: new Date().toISOString(),
      uptime: Math.floor(process.uptime()),
      version: process.env.npm_package_version || '1.0.0',
      services: {
        database: dbHealth,
        memory: memoryInfo,
        cpu: cpuInfo
      },
      environment: process.env.NODE_ENV || 'development'
    };
    
    const responseTime = Date.now() - startTime;
    
    // 根据状态设置HTTP状态码
    const httpStatus = overallStatus === 'error' ? 503 : 200;
    
    res.status(httpStatus).json({
      ...healthStatus,
      responseTime
    });
    
  } catch (error) {
    console.error('Health check error:', error);
    
    res.status(503).json({
      status: 'error',
      timestamp: new Date().toISOString(),
      error: error instanceof Error ? error.message : 'Unknown error',
      uptime: Math.floor(process.uptime()),
      environment: process.env.NODE_ENV || 'development'
    });
  }
}

// 数据库专用健康检查
export async function databaseHealthCheck(req: Request, res: Response) {
  try {
    const startTime = Date.now();
    
    // 执行多个数据库查询来全面检查
    const queries = [
      pool.query('SELECT 1 as connection_test'),
      pool.query('SELECT COUNT(*) as table_count FROM information_schema.tables WHERE table_schema = $1', ['public']),
      pool.query('SELECT NOW() as server_time')
    ];
    
    const results = await Promise.all(queries);
    const responseTime = Date.now() - startTime;
    
    // 获取连接池状态
    const poolStatus = {
      totalCount: pool.totalCount,
      idleCount: pool.idleCount,
      waitingCount: pool.waitingCount
    };
    
    res.json({
      connected: true,
      responseTime,
      serverTime: results[2].rows[0].server_time,
      tableCount: parseInt(results[1].rows[0].table_count),
      connectionPool: poolStatus,
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('Database health check error:', error);
    
    res.status(503).json({
      connected: false,
      error: error instanceof Error ? error.message : 'Unknown error',
      timestamp: new Date().toISOString()
    });
  }
}

// 就绪检查（用于Kubernetes等容器编排）
export async function readinessCheck(req: Request, res: Response) {
  try {
    // 检查关键依赖是否就绪
    await pool.query('SELECT 1');
    
    res.json({
      ready: true,
      timestamp: new Date().toISOString(),
      uptime: Math.floor(process.uptime())
    });
    
  } catch (error) {
    res.status(503).json({
      ready: false,
      error: error instanceof Error ? error.message : 'Unknown error',
      timestamp: new Date().toISOString()
    });
  }
}

// 存活检查（用于Kubernetes等容器编排）
export async function livenessCheck(req: Request, res: Response) {
  // 简单的存活检查，只要进程在运行就返回成功
  res.json({
    alive: true,
    timestamp: new Date().toISOString(),
    uptime: Math.floor(process.uptime()),
    pid: process.pid
  });
}

// 详细的系统信息
export async function systemInfo(req: Request, res: Response) {
  try {
    const memoryUsage = process.memoryUsage();
    const cpuUsage = process.cpuUsage();
    
    res.json({
      process: {
        pid: process.pid,
        uptime: process.uptime(),
        version: process.version,
        platform: process.platform,
        arch: process.arch
      },
      memory: {
        rss: Math.round(memoryUsage.rss / 1024 / 1024),
        heapTotal: Math.round(memoryUsage.heapTotal / 1024 / 1024),
        heapUsed: Math.round(memoryUsage.heapUsed / 1024 / 1024),
        external: Math.round(memoryUsage.external / 1024 / 1024)
      },
      cpu: {
        user: cpuUsage.user,
        system: cpuUsage.system
      },
      environment: {
        nodeEnv: process.env.NODE_ENV,
        port: process.env.PORT || 3005,
        dbHost: process.env.DB_HOST ? '***' : 'not set',
        dbName: process.env.DB_NAME || 'not set'
      },
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    res.status(500).json({
      error: error instanceof Error ? error.message : 'Unknown error',
      timestamp: new Date().toISOString()
    });
  }
}