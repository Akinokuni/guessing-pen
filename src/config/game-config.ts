// 统一的游戏配置
export const GAME_CONFIG = {
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
    ['670', '675', '680']  // 第9组: 差对(5,5)
  ] as readonly string[][],
  // AI生成的卡片ID列表
  aiCards: ['683', '686', '684', '680'] as readonly string[]
}

// 游戏计分规则
export const SCORING_RULES = {
  // 分组得分
  PERFECT_GROUPS_BONUS: 70,    // 全部9组正确的奖励分
  SINGLE_GROUP_SCORE: 8,       // 单个正确组的分数
  
  // AI识别得分
  AI_HIT_SCORE: 7.5,          // 正确识别AI的分数
  AI_FALSE_POSITIVE_PENALTY: 3, // 误判人类作品的扣分
  
  // 总分限制
  MAX_TOTAL_SCORE: 100,        // 理论最高分
  MIN_SCORE: 0                 // 最低分限制
} as const

// 卡片配置
export const CARD_CONFIG = {
  TOTAL_CARDS: 27,             // 总卡片数
  CARDS_PER_GROUP: 3,          // 每组卡片数
  TOTAL_GROUPS: 9,             // 总组数
  CARD_ID_START: 662,          // 起始卡片ID
  CARD_ID_END: 688             // 结束卡片ID
} as const