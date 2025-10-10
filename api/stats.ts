import { VercelRequest, VercelResponse } from '@vercel/node'

// 游戏统计数据结构
interface GameStats {
  totalPlayers: number
  averageScore: number
  highestScore: number
  completionRate: number
  popularCombinations: string[][]
  aiDetectionAccuracy: number
}

// 模拟统计数据（实际项目中应该从数据库获取）
const MOCK_STATS: GameStats = {
  totalPlayers: 1247,
  averageScore: 156.8,
  highestScore: 270,
  completionRate: 0.73,
  popularCombinations: [
    ['662', '676', '687'],
    ['670', '675', '680'],
    ['666', '671', '688']
  ],
  aiDetectionAccuracy: 0.64
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  // 设置CORS头
  res.setHeader('Access-Control-Allow-Origin', '*')
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS')
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type')
  
  // 处理预检请求
  if (req.method === 'OPTIONS') {
    res.status(200).end()
    return
  }
  
  // 只允许GET请求
  if (req.method !== 'GET') {
    res.status(405).json({ error: 'Method not allowed' })
    return
  }
  
  try {
    // 返回统计数据
    res.status(200).json({
      success: true,
      data: MOCK_STATS,
      timestamp: new Date().toISOString()
    })
    
  } catch (error) {
    console.error('Stats API Error:', error)
    res.status(500).json({ error: 'Internal server error' })
  }
}