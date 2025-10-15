import { POSTGREST_URL } from './postgrest-config'

// 玩家相关服务
export class PlayerService {
  // 创建或获取玩家
  static async createOrGetPlayer(nickname: string) {
    try {
      console.log('👤 创建或获取玩家:', nickname)
      
      // 直接POST创建或获取玩家（API会自动处理）
      const response = await fetch(`${POSTGREST_URL}/players`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: JSON.stringify({ nickname })
      })

      if (!response.ok) {
        const errorText = await response.text()
        console.error('❌ 创建玩家失败:', errorText)
        throw new Error(`Failed to create player: ${response.status}`)
      }

      const player = await response.json()
      console.log('✅ 玩家信息:', player)
      return player
    } catch (error) {
      console.error('❌ Error creating/getting player:', error)
      throw new Error('创建玩家失败')
    }
  }

  // 创建游戏会话
  static async createGameSession(playerId: string) {
    try {
      console.log('🎮 创建游戏会话, player_id:', playerId)
      
      const response = await fetch(`${POSTGREST_URL}/game_sessions`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: JSON.stringify({ player_id: playerId })
      })

      if (!response.ok) {
        const errorText = await response.text()
        console.error('❌ 创建游戏会话失败:', errorText)
        throw new Error(`Failed to create game session: ${response.status}`)
      }

      const session = await response.json()
      console.log('✅ 游戏会话:', session)
      return session
    } catch (error) {
      console.error('❌ Error creating game session:', error)
      throw new Error('创建游戏会话失败')
    }
  }
}