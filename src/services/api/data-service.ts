import { POSTGREST_URL } from './postgrest-config'
import { Card } from '../../types'

// 数据服务
export class DataService {
  // 获取排行榜
  static async getLeaderboard(limit: number = 10, offset: number = 0) {
    try {
      const response = await fetch(
        `${POSTGREST_URL}/leaderboard?limit=${limit}&offset=${offset}&order=rank.asc`,
        {
          method: 'GET',
          headers: {
            'Accept': 'application/json'
          }
        }
      )

      if (!response.ok) {
        throw new Error('Failed to fetch leaderboard')
      }

      const result = await response.json()
      
      return {
        success: result.success || true,
        data: result.data || [],
        total: result.total || 0,
        limit,
        offset
      }
    } catch (error) {
      console.error('Error getting leaderboard:', error)
      throw new Error('获取排行榜失败')
    }
  }

  // 获取游戏统计
  static async getGameStats() {
    try {
      const response = await fetch(`${POSTGREST_URL}/stats`, {
        method: 'GET',
        headers: {
          'Accept': 'application/json'
        }
      })

      if (!response.ok) {
        throw new Error('Failed to fetch game stats')
      }

      const result = await response.json()
      
      // API返回的格式是 { success: true, data: {...} }
      const rawStats = result.data || {
        total_players: 0,
        average_score: 0,
        highest_score: 0,
        completion_rate: 0,
        ai_detection_accuracy: 0
      }
      
      // 确保数据类型正确（数据库可能返回字符串）
      const stats = {
        total_players: parseInt(rawStats.total_players) || 0,
        average_score: parseFloat(rawStats.average_score) || 0,
        highest_score: parseInt(rawStats.highest_score) || 0,
        completion_rate: parseFloat(rawStats.completion_rate) || 0,
        ai_detection_accuracy: parseFloat(rawStats.ai_detection_accuracy) || 0
      }
      
      return {
        success: result.success || true,
        data: stats,
        timestamp: result.timestamp || new Date().toISOString()
      }
    } catch (error) {
      console.error('Error getting game stats:', error)
      throw new Error('获取统计数据失败')
    }
  }

  // 获取卡片数据（静态数据）
  static async getCards(shuffle: boolean = true): Promise<{ cards: Card[], total: number }> {
    const cards: Card[] = Array.from({ length: 27 }, (_, i) => {
      const id = (662 + i).toString()
      return {
        id,
        imageUrl: `/cards/${id}.png`,
        name: `CG ${id}`
      }
    })

    if (shuffle) {
      for (let i = cards.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [cards[i], cards[j]] = [cards[j], cards[i]]
      }
    }

    return {
      cards,
      total: cards.length
    }
  }
}