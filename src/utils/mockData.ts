import { Card } from '../types'

// 卡片数据 - 使用正确的编号 662-688
export const mockCards: Card[] = [
  { id: '662', imageUrl: '/cards/662.png', name: 'CG 662' },
  { id: '663', imageUrl: '/cards/663.png', name: 'CG 663' },
  { id: '664', imageUrl: '/cards/664.png', name: 'CG 664' },
  { id: '665', imageUrl: '/cards/665.png', name: 'CG 665' },
  { id: '666', imageUrl: '/cards/666.png', name: 'CG 666' },
  { id: '667', imageUrl: '/cards/667.png', name: 'CG 667' },
  { id: '668', imageUrl: '/cards/668.png', name: 'CG 668' },
  { id: '669', imageUrl: '/cards/669.png', name: 'CG 669' },
  { id: '670', imageUrl: '/cards/670.png', name: 'CG 670' },
  { id: '671', imageUrl: '/cards/671.png', name: 'CG 671' },
  { id: '672', imageUrl: '/cards/672.png', name: 'CG 672' },
  { id: '673', imageUrl: '/cards/673.png', name: 'CG 673' },
  { id: '674', imageUrl: '/cards/674.png', name: 'CG 674' },
  { id: '675', imageUrl: '/cards/675.png', name: 'CG 675' },
  { id: '676', imageUrl: '/cards/676.png', name: 'CG 676' },
  { id: '677', imageUrl: '/cards/677.png', name: 'CG 677' },
  { id: '678', imageUrl: '/cards/678.png', name: 'CG 678' },
  { id: '679', imageUrl: '/cards/679.png', name: 'CG 679' },
  { id: '680', imageUrl: '/cards/680.png', name: 'CG 680' },
  { id: '681', imageUrl: '/cards/681.png', name: 'CG 681' },
  { id: '682', imageUrl: '/cards/682.png', name: 'CG 682' },
  { id: '683', imageUrl: '/cards/683.png', name: 'CG 683' },
  { id: '684', imageUrl: '/cards/684.png', name: 'CG 684' },
  { id: '685', imageUrl: '/cards/685.png', name: 'CG 685' },
  { id: '686', imageUrl: '/cards/686.png', name: 'CG 686' },
  { id: '687', imageUrl: '/cards/687.png', name: 'CG 687' },
  { id: '688', imageUrl: '/cards/688.png', name: 'CG 688' }
]

// 游戏配置 - 根据说明文档的正确分组
export const gameConfig = {
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

// 验证函数 - 检查三元组是否符合规则
export const validateTriple = (a: number, b: number, c: number): boolean => {
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