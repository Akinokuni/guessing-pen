import { SubmissionPayload, ApiResponse, Card } from '../types'
import { GAME_CONFIG } from '../config/game-config'

// 直接数据库服务类（通过API端点）
export class DirectDbService {
  private static apiBase = '/api/db'

  // 创建或获取玩家
  static async createOrGetPlayer(nickname: string) {
    const response = await fetch(`${this.apiBase}/players`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ nickname })
    })
    if (!response.ok) throw new Error('创建玩家失败')
    return response.json()
  }

  // 创建游戏会话
  static async createGameSession(playerId: number) {
    const response = await fetch(`${this.apiBase}/sessions`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ player_id: playerId })
    })
    if (!response.ok) throw new Error('创建游戏会话失败')
    return response.json()
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
          group.every((id: string) => cardIds.includes(id)) && cardIds.every((id: string) => group.includes(id))
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
          
          if ((GAME_CONFIG.aiCards as readonly string[]).includes(markedCardId)) {
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
          const aiCardsInGroup = cardIds.filter((id: string) => (GAME_CONFIG.aiCards as readonly string[]).includes(id))
          
          result.isAiDetectionCorrect = aiCardsInGroup.length === 1 && 
            markedCardId === aiCardsInGroup[0]
        }
      }
      
      totalScore = groupingScore + aiDetectionScore

      // 保存答案组合
      const answerData = results.map((result, i) => ({
        session_id: session.id,
        card_ids: payload[i].cards.map(card => card.id),
        ai_marked_card_id: payload[i].aiMarkedCardId || null,
        is_grouping_correct: result.isGroupingCorrect,
        is_ai_detection_correct: result.isAiDetectionCorrect,
        score: 0
      }))

      await fetch(`${this.apiBase}/answers`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ answers: answerData })
      })

      // 更新游戏会话
      await fetch(`${this.apiBase}/sessions/${session.id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
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
        `${this.apiBase}/leaderboard?limit=${limit}&offset=${offset}`
      )
      if (!response.ok) throw new Error('获取排行榜失败')
      return response.json()
    } catch (error) {
      console.error('Error getting leaderboard:', error)
      throw new Error('获取排行榜失败')
    }
  }

  // 获取游戏统计
  static async getGameStats() {
    try {
      const response = await fetch(`${this.apiBase}/stats`)
      if (!response.ok) throw new Error('获取统计数据失败')
      return response.json()
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
