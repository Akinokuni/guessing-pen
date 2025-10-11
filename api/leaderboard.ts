import { VercelRequest, VercelResponse } from '@vercel/node'

// 排行榜条目
interface LeaderboardEntry {
  rank: number
  nickname: string
  score: number
  completedAt: string
  combinations: number
}

// 模拟排行榜数据（实际项目中应该从数据库获取）
const MOCK_LEADERBOARD: LeaderboardEntry[] = [
  { rank: 1, nickname: '画师猎人', score: 270, completedAt: '2024-12-01T10:30:00Z', combinations: 9 },
  { rank: 2, nickname: 'AI侦探', score: 265, completedAt: '2024-12-01T11:15:00Z', combinations: 9 },
  { rank: 3, nickname: '艺术鉴赏家', score: 250, completedAt: '2024-12-01T09:45:00Z', combinations: 9 },
  { rank: 4, nickname: '像素大师', score: 235, completedAt: '2024-12-01T14:20:00Z', combinations: 8 },
  { rank: 5, nickname: '色彩专家', score: 220, completedAt: '2024-12-01T16:10:00Z', combinations: 8 },
  { rank: 6, nickname: '风格识别者', score: 210, completedAt: '2024-12-01T12:30:00Z', combinations: 7 },
  { rank: 7, nickname: '画风分析师', score: 195, completedAt: '2024-12-01T15:45:00Z', combinations: 7 },
  { rank: 8, nickname: '视觉达人', score: 180, completedAt: '2024-12-01T13:20:00Z', combinations: 6 },
  { rank: 9, nickname: '美术爱好者', score: 165, completedAt: '2024-12-01T17:00:00Z', combinations: 6 },
  { rank: 10, nickname: '创意观察家', score: 150, completedAt: '2024-12-01T18:15:00Z', combinations: 5 }
]

export default async function handler(req: VercelRequest, res: VercelResponse) {
  // 设置CORS头
  res.setHeader('Access-Control-Allow-Origin', '*')
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type')
  
  // 处理预检请求
  if (req.method === 'OPTIONS') {
    res.status(200).end()
    return
  }
  
  try {
    if (req.method === 'GET') {
      // 获取排行榜
      const { limit = '10', offset = '0' } = req.query
      const limitNum = parseInt(limit as string)
      const offsetNum = parseInt(offset as string)
      
      const paginatedData = MOCK_LEADERBOARD.slice(offsetNum, offsetNum + limitNum)
      
      res.status(200).json({
        success: true,
        data: paginatedData,
        total: MOCK_LEADERBOARD.length,
        limit: limitNum,
        offset: offsetNum
      })
      
    } else if (req.method === 'POST') {
      // 提交新的分数到排行榜
      const { nickname, score, combinations } = req.body
      
      if (!nickname || typeof score !== 'number') {
        res.status(400).json({ error: 'Invalid data' })
        return
      }
      
      // 在实际项目中，这里应该保存到数据库
      console.log(`New leaderboard entry: ${nickname} - ${score} points (${combinations} combinations)`)
      
      // 计算排名（简单实现）
      const rank = MOCK_LEADERBOARD.filter(entry => entry.score > score).length + 1
      
      res.status(200).json({
        success: true,
        rank,
        message: 'Score submitted successfully'
      })
      
    } else {
      res.status(405).json({ error: 'Method not allowed' })
    }
    
  } catch (error) {
    console.error('Leaderboard API Error:', error)
    res.status(500).json({ error: 'Internal server error' })
  }
}