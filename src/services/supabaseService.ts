import { supabase } from '../lib/supabase'
import { SubmissionPayload, ApiResponse, Card } from '../types'

// 游戏配置 - 正确答案
const GAME_CONFIG = {
  correctGroups: [
    ['662', '676', '687'], ['663', '677', '685'], ['664', '678', '683'],
    ['665', '679', '681'], ['666', '671', '688'], ['667', '672', '686'],
    ['668', '673', '684'], ['669', '674', '682'], ['670', '675', '680']
  ],
  aiCards: ['687', '685', '683', '681', '688', '686', '684', '682', '680']
}

// 验证三元组是否符合规则（暂时未使用，保留以备后用）
// const validateTriple = (a: number, b: number, c: number): boolean => {
//   const TARGET = 2025
//   const LOW = 662
//   const HIGH = 688
  
//   if (a < LOW || a > HIGH || b < LOW || b > HIGH || c < LOW || c > HIGH) {
//     return false
//   }
  
//   return a + b + c === TARGET
// }

// Supabase 服务类
export class SupabaseService {
  // 创建或获取玩家
  static async createOrGetPlayer(nickname: string) {
    try {
      // 先尝试查找现有玩家
      const { data: existingPlayer } = await supabase
        .from('players')
        .select('*')
        .eq('nickname', nickname)
        .single()

      if (existingPlayer) {
        return existingPlayer
      }

      // 创建新玩家
      const { data: newPlayer, error } = await supabase
        .from('players')
        .insert({ nickname })
        .select()
        .single()

      if (error) throw error
      return newPlayer
    } catch (error) {
      console.error('Error creating/getting player:', error)
      throw new Error('创建玩家失败')
    }
  }

  // 创建游戏会话
  static async createGameSession(playerId: string) {
    try {
      const { data, error } = await supabase
        .from('game_sessions')
        .insert({ player_id: playerId })
        .select()
        .single()

      if (error) throw error
      return data
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
          isAiDetectionCorrect: false // 将在下面计算
        })
      }
      
      // 分组得分：每成功组成一个"完美小组"，获得8分
      // 满分特殊规则：全部9个完美小组时直接获得70分
      let groupingScore = 0
      if (perfectGroups === 9) {
        groupingScore = 70
      } else {
        groupingScore = perfectGroups * 8
      }
      
      // 第二部分：AI鉴别正确性 (满分30分)
      let hits = 0 // 正确命中
      let falsePositives = 0 // 错误标记
      
      // 统计所有标记为AI的卡片
      for (const combination of payload) {
        if (combination.aiMarkedCardId) {
          const markedCardId = combination.aiMarkedCardId
          
          if (GAME_CONFIG.aiCards.includes(markedCardId)) {
            hits++ // 正确命中真正的AI卡片
          } else {
            falsePositives++ // 错误标记人类作品为AI
          }
        }
      }
      
      // AI鉴别得分 = (命中数 × 7.5) - (误判数 × 3)
      // 最低分限制为0分
      const aiDetectionScore = Math.max(0, (hits * 7.5) - (falsePositives * 3))
      
      // 更新结果中的AI识别信息
      for (let i = 0; i < results.length; i++) {
        const combination = payload[i]
        const result = results[i]
        if (combination.aiMarkedCardId) {
          const markedCardId = combination.aiMarkedCardId
          const cardIds = combination.cards.map(card => card.id)
          const aiCardsInGroup = cardIds.filter(id => GAME_CONFIG.aiCards.includes(id))
          
          // 检查AI识别是否正确（标记的卡片确实是该组中的AI卡片）
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
        
        await supabase.from('answer_combinations').insert({
          session_id: session.id,
          card_ids: cardIds,
          ai_marked_card_id: combination.aiMarkedCardId,
          is_grouping_correct: result.isGroupingCorrect,
          is_ai_detection_correct: result.isAiDetectionCorrect,
          score: 0 // 新计分系统不再为单个组合计算分数
        })
      }

      // 更新游戏会话
      await supabase
        .from('game_sessions')
        .update({
          total_score: totalScore,
          combinations_count: payload.length,
          completed_at: new Date().toISOString()
        })
        .eq('id', session.id)

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
      const { data, error } = await supabase
        .from('leaderboard')
        .select('*')
        .range(offset, offset + limit - 1)

      if (error) throw error
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
      const { data, error } = await supabase
        .from('game_stats')
        .select('*')
        .single()

      if (error) throw error
      return {
        success: true,
        data: data || {
          total_players: 0,
          average_score: 0,
          highest_score: 0,
          completion_rate: 0,
          ai_detection_accuracy: 0
        },
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
      // Fisher-Yates shuffle
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