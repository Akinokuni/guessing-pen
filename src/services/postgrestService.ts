import { SubmissionPayload, ApiResponse, Card } from '../types'

// PostgREST API 配置
// 在生产环境中，通过nginx代理访问 /api/
// 在开发环境中，直接访问 PostgREST 服务
const POSTGREST_URL = import.meta.env.VITE_POSTGREST_URL || 
  (import.meta.env.PROD ? '/api' : 'http://localhost:3001')

// 游戏配置 - 正确答案
const GAME_CONFIG = {
  correctGroups: [
    ['662', '676', '687'], ['663', '677', '685'], ['664', '678', '683'],
    ['665', '679', '681'], ['666', '671', '688'], ['667', '672', '686'],
    ['668', '673', '684'], ['669', '674', '682'], ['670', '675', '680']
  ],
  aiCards: ['683', '686', '684', '680']
}

// PostgREST 服务类
export class PostgRESTService {
  // 创建或获取玩家
  static async createOrGetPlayer(nickname: string) {
    try {
      // 先尝试查找现有玩家
      const response = await fetch(
        `${POSTGREST_URL}/players?nickname=eq.${encodeURIComponent(nickname)}`,
        {
          method: 'GET',
          headers: {
            'Accept': 'application/json',
            'Prefer': 'return=representation'
          }
        }
      )

      if (!response.ok) {
        throw new Error('Failed to fetch player')
      }

      const players = await response.json()
      
      if (players && players.length > 0) {
        return players[0]
      }

      // 创建新玩家
      const createResponse = await fetch(`${POSTGREST_URL}/players`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Prefer': 'return=representation'
        },
        body: JSON.stringify({ nickname })
      })

      if (!createResponse.ok) {
        throw new Error('Failed to create player')
      }

      const newPlayers = await createResponse.json()
      return newPlayers[0]
    } catch (error) {
      console.error('Error creating/getting player:', error)
      throw new Error('创建玩家失败')
    }
  }

  // 创建游戏会话
  static async createGameSession(playerId: string) {
    try {
      const response = await fetch(`${POSTGREST_URL}/game_sessions`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Prefer': 'return=representation'
        },
        body: JSON.stringify({ player_id: playerId })
      })

      if (!response.ok) {
        throw new Error('Failed to create game session')
      }

      const sessions = await response.json()
      return sessions[0]
    } catch (error) {
      console.error('Error creating game session:', error)
      throw new Error('创建游戏会话失败')
    }
  }

  // 提交答案并计分
  static async submitAnswers(payload: SubmissionPayload, nickname: string): Promise<ApiResponse> {
    try {
      // 创建或获取玩家
      const player = await this.createOrGetPlayer(nickname)
      
      // 创建游戏会话
      const session = await this.createGameSession(player.id)

      let totalScore = 0
      
      // 第一部分：分组正确性 (满分70分)
      let perfectGroups = 0
      const results = []
      
      for (const combination of payload) {
        const cardIds = combination.cards.map(card => card.id)
        
        // 验证分组是否正确
        const isGroupingCorrect = GAME_CONFIG.correctGroups.some(group => 
          group.every(id => cardIds.includes(id)) && cardIds.every(id => group.includes(id))
        )
        
        if (isGroupingCorrect) {
          perfectGroups++
        }
        
        results.push({
          userCombination: combination,
          isGroupingCorrect,
          isAiDetectionCorrect: false
        })
      }
      
      // 分组得分
      let groupingScore = 0
      if (perfectGroups === 9) {
        groupingScore = 70
      } else {
        groupingScore = perfectGroups * 8
      }
      
      // 第二部分：AI鉴别正确性 (满分30分)
      let hits = 0
      let falsePositives = 0
      
      for (const combination of payload) {
        if (combination.aiMarkedCardId) {
          const markedCardId = combination.aiMarkedCardId
          
          if (GAME_CONFIG.aiCards.includes(markedCardId)) {
            hits++
          } else {
            falsePositives++
          }
        }
      }
      
      const aiDetectionScore = Math.max(0, (hits * 7.5) - (falsePositives * 3))
      
      // 更新结果中的AI识别信息
      for (let i = 0; i < results.length; i++) {
        const combination = payload[i]
        const result = results[i]
        if (combination.aiMarkedCardId) {
          const markedCardId = combination.aiMarkedCardId
          const cardIds = combination.cards.map(card => card.id)
          const aiCardsInGroup = cardIds.filter(id => GAME_CONFIG.aiCards.includes(id))
          
          result.isAiDetectionCorrect = aiCardsInGroup.length === 1 && 
            markedCardId === aiCardsInGroup[0]
        }
      }
      
      totalScore = groupingScore + aiDetectionScore

      // 保存答案组合到数据库
      for (let i = 0; i < results.length; i++) {
        const combination = payload[i]
        const result = results[i]
        const cardIds = combination.cards.map(card => card.id)
        
        await fetch(`${POSTGREST_URL}/answer_combinations`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
          },
          body: JSON.stringify({
            session_id: session.id,
            card_ids: cardIds,
            ai_marked_card_id: combination.aiMarkedCardId,
            is_grouping_correct: result.isGroupingCorrect,
            is_ai_detection_correct: result.isAiDetectionCorrect,
            score: 0
          })
        })
      }

      // 更新游戏会话
      await fetch(`${POSTGREST_URL}/game_sessions?id=eq.${session.id}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: JSON.stringify({
          total_score: totalScore,
          combinations_count: payload.length,
          completed_at: new Date().toISOString()
        })
      })

      return {
        nickname,
        totalScore,
        results
      }
    } catch (error) {
      console.error('Error submitting answers:', error)
      throw new Error('提交答案失败')
    }
  }

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

      const data = await response.json()
      
      return {
        success: true,
        data: data || [],
        total: data?.length || 0,
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
      const response = await fetch(`${POSTGREST_URL}/game_stats`, {
        method: 'GET',
        headers: {
          'Accept': 'application/json'
        }
      })

      if (!response.ok) {
        throw new Error('Failed to fetch game stats')
      }

      const data = await response.json()
      const stats = data && data.length > 0 ? data[0] : {
        total_players: 0,
        average_score: 0,
        highest_score: 0,
        completion_rate: 0,
        ai_detection_accuracy: 0
      }
      
      return {
        success: true,
        data: stats,
        timestamp: new Date().toISOString()
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
