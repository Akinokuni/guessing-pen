import { SubmissionPayload } from '../../types'
import { GAME_CONFIG } from '../../config/game-config'

// 计分服务
export class ScoringService {
  // 计算分组得分
  static calculateGroupingScore(payload: SubmissionPayload): { score: number, perfectGroups: number } {
    let perfectGroups = 0
    
    for (const combination of payload) {
      const cardIds = combination.cards.map(card => card.id)
      
      // 验证分组是否正确
      const isGroupingCorrect = GAME_CONFIG.correctGroups.some(group => 
        group.every((id: string) => cardIds.includes(id)) && cardIds.every((id: string) => group.includes(id))
      )
      
      if (isGroupingCorrect) {
        perfectGroups++
      }
    }
    
    // 分组得分
    const score = perfectGroups === 9 ? 70 : perfectGroups * 8
    
    return { score, perfectGroups }
  }

  // 计算AI识别得分
  static calculateAiDetectionScore(payload: SubmissionPayload): { score: number, hits: number, falsePositives: number } {
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
    
    const score = Math.max(0, (hits * 7.5) - (falsePositives * 3))
    
    return { score, hits, falsePositives }
  }

  // 验证单个组合的正确性
  static validateCombination(combination: { cards: Array<{ id: string }>; aiMarkedCardId?: string | null }) {
    const cardIds = combination.cards.map((card: { id: string }) => card.id)
    
    // 检查分组正确性
    const isGroupingCorrect = GAME_CONFIG.correctGroups.some(group => 
      group.every((id: string) => cardIds.includes(id)) && cardIds.every((id: string) => group.includes(id))
    )
    
    // 检查AI识别正确性
    let isAiDetectionCorrect = false
    if (combination.aiMarkedCardId) {
      const markedCardId = combination.aiMarkedCardId
      const aiCardsInGroup = cardIds.filter((id: string) => (GAME_CONFIG.aiCards as readonly string[]).includes(id))
      
      isAiDetectionCorrect = aiCardsInGroup.length === 1 && 
        markedCardId === aiCardsInGroup[0]
    }
    
    return {
      isGroupingCorrect,
      isAiDetectionCorrect
    }
  }
}