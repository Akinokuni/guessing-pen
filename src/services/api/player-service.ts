import { POSTGREST_URL } from './postgrest-config'

// 玩家相关服务
export class PlayerService {
  // 创建或获取玩家
  static async createOrGetPlayer(nickname: string) {
    try {
      // 先尝试查找现有玩家
      const response = await fetch(
        `${POSTGREST_URL}/players?nickname=eq.${encodeURIComponent(nickname)}`,
        {
          method: 'GET',
          headers: {
            'Accept': 'application/json',
            'Prefer': 'return=representation'
          }
        }
      )

      if (!response.ok) {
        throw new Error('Failed to fetch player')
      }

      const players = await response.json()
      
      if (players && players.length > 0) {
        return players[0]
      }

      // 创建新玩家
      const createResponse = await fetch(`${POSTGREST_URL}/players`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Prefer': 'return=representation'
        },
        body: JSON.stringify({ nickname })
      })

      if (!createResponse.ok) {
        throw new Error('Failed to create player')
      }

      const newPlayers = await createResponse.json()
      return newPlayers[0]
    } catch (error) {
      console.error('Error creating/getting player:', error)
      throw new Error('创建玩家失败')
    }
  }

  // 创建游戏会话
  static async createGameSession(playerId: string) {
    try {
      const response = await fetch(`${POSTGREST_URL}/game_sessions`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Prefer': 'return=representation'
        },
        body: JSON.stringify({ player_id: playerId })
      })

      if (!response.ok) {
        throw new Error('Failed to create game session')
      }

      const sessions = await response.json()
      return sessions[0]
    } catch (error) {
      console.error('Error creating game session:', error)
      throw new Error('创建游戏会话失败')
    }
  }
}