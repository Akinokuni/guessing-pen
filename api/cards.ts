import { VercelRequest, VercelResponse } from '@vercel/node'
import { Card } from '../src/types'

// 卡片数据 - 使用正确的编号 662-688
const CARDS_DATA: Card[] = [
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

// 洗牌算法 - Fisher-Yates shuffle
const shuffleArray = <T>(array: T[]): T[] => {
  const shuffled = [...array]
  for (let i = shuffled.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]]
  }
  return shuffled
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  // 设置CORS头
  res.setHeader('Access-Control-Allow-Origin', '*')
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS')
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type')
  
  // 处理预检请求
  if (req.method === 'OPTIONS') {
    res.status(200).end()
    return
  }
  
  // 只允许GET请求
  if (req.method !== 'GET') {
    res.status(405).json({ error: 'Method not allowed' })
    return
  }
  
  try {
    // 获取查询参数
    const { shuffle = 'true' } = req.query
    
    let cards = CARDS_DATA
    
    // 如果需要洗牌
    if (shuffle === 'true') {
      cards = shuffleArray(CARDS_DATA)
    }
    
    // 返回卡片数据
    res.status(200).json({
      cards,
      total: cards.length,
      shuffled: shuffle === 'true'
    })
    
  } catch (error) {
    console.error('Cards API Error:', error)
    res.status(500).json({ error: 'Internal server error' })
  }
}