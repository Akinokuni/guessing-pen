import { SubmissionPayload, ApiResponse } from '../../types'
import { POSTGREST_URL } from './postgrest-config'
import { PlayerService } from './player-service'
import { ScoringService } from './scoring-service'

// 答案提交服务
export class SubmissionService {
  // 提交答案并计分
  static async submitAnswers(payload: SubmissionPayload, nickname: string): Promise<ApiResponse> {
    try {
      // 创建或获取玩家
      const player = await PlayerService.createOrGetPlayer(nickname)
      
      // 创建游戏会话
      const session = await PlayerService.createGameSession(player.id)

      // 计算分组得分
      const { score: groupingScore } = ScoringService.calculateGroupingScore(payload)
      
      // 计算AI识别得分
      const { score: aiDetectionScore } = ScoringService.calculateAiDetectionScore(payload)
      
      const totalScore = groupingScore + aiDetectionScore

      // 生成结果
      const results = payload.map(combination => ({
        userCombination: combination,
        ...ScoringService.validateCombination(combination)
      }))

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
}