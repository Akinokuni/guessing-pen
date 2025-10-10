import { VercelRequest, VercelResponse } from '@vercel/node'
import { SubmissionPayload, ApiResponse, ResultDetail } from '../src/types'

// 游戏配置 - 正确答案
const GAME_CONFIG = {
  // 正确的分组（每组3张卡片，每组和为2025）
  correctGroups: [
    ['662', '676', '687'], // 第1组: 差对(14,11)
    ['663', '677', '685'], // 第2组: 差对(14,8)
    ['664', '678', '683'], // 第3组: 差对(14,5)
    ['665', '679', '681'], // 第4组: 差对(14,2)
    ['666', '671', '688'], // 第5组: 差对(5,17)
    ['667', '672', '686'], // 第6组: 差对(5,14)
    ['668', '673', '684'], // 第7组: 差对(5,11)
    ['669', '674', '682'], // 第8组: 差对(5,8)
    ['670', '675', '680'], // 第9组: 差对(5,5)
  ],
  
  // AI生成的卡片 - 根据最新要求，只有4张AI卡片
  aiCards: [
    '683', // 第3组中的AI卡片
    '686', // 第6组中的AI卡片
    '684', // 第7组中的AI卡片
    '680', // 第9组中的AI卡片
  ]
}

// 验证三元组是否符合规则
const validateTriple = (a: number, b: number, c: number): boolean => {
  const TARGET = 2025
  const LOW = 662
  const HIGH = 688
  
  // 检查范围
  if (a < LOW || a > HIGH || b < LOW || b > HIGH || c < LOW || c > HIGH) {
    return false
  }
  
  // 检查和是否为2025
  return a + b + c === TARGET
}

// 计分算法 - 根据新的计分规则
const calculateScore = (submission: SubmissionPayload, userNickname: string): ApiResponse => {
  let groupingScore = 0
  let aiDetectionScore = 0
  const results: ResultDetail[] = []
  
  // 第一部分：分组正确性 (满分70分)
  let perfectGroups = 0
  submission.forEach(combination => {
    const cardIds = combination.cards.map(card => card.id)
    
    // 检查分组是否正确（在正确分组列表中）
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
  })
  
  // 分组得分：每成功组成一个"完美小组"，获得8分
  // 满分特殊规则：全部9个完美小组时直接获得70分
  if (perfectGroups === 9) {
    groupingScore = 70
  } else {
    groupingScore = perfectGroups * 8
  }
  
  // 第二部分：AI鉴别正确性 (满分30分)
  let hits = 0 // 正确命中
  let falsePositives = 0 // 错误标记
  
  // 统计所有标记为AI的卡片
  submission.forEach(combination => {
    if (combination.aiMarkedCardId) {
      const markedCardId = combination.aiMarkedCardId
      
      if (GAME_CONFIG.aiCards.includes(markedCardId)) {
        hits++ // 正确命中真正的AI卡片
      } else {
        falsePositives++ // 错误标记人类作品为AI
      }
    }
  })
  
  // AI鉴别得分 = (命中数 × 7.5) - (误判数 × 3)
  // 最低分限制为0分
  aiDetectionScore = Math.max(0, (hits * 7.5) - (falsePositives * 3))
  
  // 更新结果中的AI识别信息
  results.forEach((result, index) => {
    const combination = submission[index]
    if (combination.aiMarkedCardId) {
      const markedCardId = combination.aiMarkedCardId
      const cardIds = combination.cards.map(card => card.id)
      const aiCardsInGroup = cardIds.filter(id => GAME_CONFIG.aiCards.includes(id))
      
      // 检查AI识别是否正确（标记的卡片确实是该组中的AI卡片）
      result.isAiDetectionCorrect = aiCardsInGroup.length === 1 && 
        markedCardId === aiCardsInGroup[0]
    }
  })
  
  const totalScore = groupingScore + aiDetectionScore
  
  return {
    nickname: userNickname,
    totalScore,
    results
  }
}

// 主要的API处理函数
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
  
  // 只允许POST请求
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' })
    return
  }
  
  try {
    // 验证请求体
    if (!req.body || !Array.isArray(req.body)) {
      res.status(400).json({ error: 'Invalid request body' })
      return
    }
    
    const submission: SubmissionPayload = req.body
    const userNickname = req.headers['x-user-nickname'] as string || '匿名玩家'
    
    // 验证提交数据
    if (submission.length === 0) {
      res.status(400).json({ error: 'No combinations submitted' })
      return
    }
    
    // 验证每个组合
    for (const combination of submission) {
      if (!combination.cards || combination.cards.length !== 3) {
        res.status(400).json({ error: 'Each combination must have exactly 3 cards' })
        return
      }
    }
    
    // 计算分数
    const result = calculateScore(submission, userNickname)
    
    // 记录提交（可以添加到数据库）
    console.log(`User ${userNickname} submitted ${submission.length} combinations, score: ${result.totalScore}`)
    
    // 返回结果
    res.status(200).json(result)
    
  } catch (error) {
    console.error('API Error:', error)
    res.status(500).json({ error: 'Internal server error' })
  }
}