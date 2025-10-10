import { Card, Combination } from '../types'

// Fisher-Yates 洗牌算法
export const shuffleCards = (cards: Card[]): Card[] => {
  const shuffled = [...cards] // 创建副本避免修改原数组
  for (let i = shuffled.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1))
    ;[shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]]
  }
  return shuffled
}

// 获取所有已使用的卡片ID（构建区 + 已提交的组合）
export const getUsedCardIds = (
  selectedCards: Card[],
  submittedCombinations: Combination[]
): string[] => {
  const usedIds = new Set<string>()
  
  // 添加构建区中的卡片ID
  selectedCards.forEach(card => {
    usedIds.add(card.id)
  })
  
  // 添加已提交组合中的卡片ID
  submittedCombinations.forEach(combination => {
    combination.cards.forEach(card => {
      usedIds.add(card.id)
    })
  })
  
  return Array.from(usedIds)
}

// 检查卡片是否已被使用
export const isCardUsed = (
  cardId: string,
  selectedCards: Card[],
  submittedCombinations: Combination[]
): boolean => {
  const usedIds = getUsedCardIds(selectedCards, submittedCombinations)
  return usedIds.includes(cardId)
}

// 获取可用的卡片（未被使用的卡片）
export const getAvailableCards = (
  allCards: Card[],
  selectedCards: Card[],
  submittedCombinations: Combination[]
): Card[] => {
  const usedIds = getUsedCardIds(selectedCards, submittedCombinations)
  return allCards.filter(card => !usedIds.includes(card.id))
}

// 验证卡片唯一性（调试用）
export const validateCardUniqueness = (
  availableCards: Card[],
  selectedCards: Card[],
  submittedCombinations: Combination[]
): { isValid: boolean; duplicates: string[] } => {
  const allDisplayedIds = new Set<string>()
  const duplicates: string[] = []
  
  // 检查卡片集中的卡片
  availableCards.forEach(card => {
    if (allDisplayedIds.has(card.id)) {
      duplicates.push(card.id)
    } else {
      allDisplayedIds.add(card.id)
    }
  })
  
  // 检查构建区中的卡片
  selectedCards.forEach(card => {
    if (allDisplayedIds.has(card.id)) {
      duplicates.push(card.id)
    } else {
      allDisplayedIds.add(card.id)
    }
  })
  
  // 检查已提交组合中的卡片
  submittedCombinations.forEach(combination => {
    combination.cards.forEach(card => {
      if (allDisplayedIds.has(card.id)) {
        duplicates.push(card.id)
      } else {
        allDisplayedIds.add(card.id)
      }
    })
  })
  
  return {
    isValid: duplicates.length === 0,
    duplicates: [...new Set(duplicates)] // 去重
  }
}