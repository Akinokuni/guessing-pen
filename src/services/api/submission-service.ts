import { SubmissionPayload, ApiResponse } from '../../types'
import { POSTGREST_URL } from './postgrest-config'
import { PlayerService } from './player-service'
import { ScoringService } from './scoring-service'

// 答案提交服务
export class SubmissionService {
  // 提交答案并计分
  static async submitAnswers(payload: SubmissionPayload, nickname: string): Promise<ApiResponse> {
    try {
      console.log('📤 开始提交答案...', { nickname, combinationsCount: payload.length })
      
      // 创建或获取玩家
      console.log('👤 创建或获取玩家...')
      const player = await PlayerService.createOrGetPlayer(nickname)
      console.log('✅ 玩家信息:', player)
      
      // 创建游戏会话
      console.log('🎮 创建游戏会话...')
      const session = await PlayerService.createGameSession(player.id)
      console.log('✅ 游戏会话:', session)

      // 计算分组得分
      const { score: groupingScore } = ScoringService.calculateGroupingScore(payload)
      console.log('📊 分组得分:', groupingScore)
      
      // 计算AI识别得分
      const { score: aiDetectionScore } = ScoringService.calculateAiDetectionScore(payload)
      console.log('🤖 AI识别得分:', aiDetectionScore)
      
      const totalScore = groupingScore + aiDetectionScore
      console.log('🎯 总分:', totalScore)

      // 生成结果
      const results = payload.map(combination => ({
        userCombination: combination,
        ...ScoringService.validateCombination(combination)
      }))

      // 保存答案组合到数据库
      console.log('💾 保存答案组合到数据库...')
      for (let i = 0; i < results.length; i++) {
        const combination = payload[i]
        const result = results[i]
        const cardIds = combination.cards.map(card => card.id)
        
        const response = await fetch(`${POSTGREST_URL}/answer_combinations`, {
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
        
        if (!response.ok) {
          const errorText = await response.text()
          console.error(`❌ 保存答案组合 ${i + 1} 失败:`, errorText)
          throw new Error(`保存答案组合失败: ${response.status}`)
        }
        
        console.log(`✅ 答案组合 ${i + 1} 已保存`)
      }

      // 更新游戏会话
      console.log('🔄 更新游戏会话...')
      const updateResponse = await fetch(`${POSTGREST_URL}/game_sessions?id=eq.${session.id}`, {
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
      
      if (!updateResponse.ok) {
        const errorText = await updateResponse.text()
        console.error('❌ 更新游戏会话失败:', errorText)
        throw new Error(`更新游戏会话失败: ${updateResponse.status}`)
      }
      
      console.log('✅ 游戏会话已更新')
      console.log('🎉 答案提交完成！')

      return {
        nickname,
        totalScore,
        results
      }
    } catch (error) {
      console.error('❌ 提交答案失败:', error)
      if (error instanceof Error) {
        throw new Error(`提交答案失败: ${error.message}`)
      }
      throw new Error('提交答案失败')
    }
  }
}