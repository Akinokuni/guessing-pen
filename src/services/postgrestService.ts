import { SubmissionPayload, ApiResponse, Card } from '../types'
import { PlayerService } from './api/player-service'
import { SubmissionService } from './api/submission-service'
import { DataService } from './api/data-service'

// PostgREST 服务类 - 重构后的简化版本
export class PostgRESTService {
  // 创建或获取玩家
  static async createOrGetPlayer(nickname: string) {
    return PlayerService.createOrGetPlayer(nickname)
  }

  // 创建游戏会话
  static async createGameSession(playerId: string) {
    return PlayerService.createGameSession(playerId)
  }

  // 提交答案并计分
  static async submitAnswers(payload: SubmissionPayload, nickname: string): Promise<ApiResponse> {
    return SubmissionService.submitAnswers(payload, nickname)
  }

  // 获取排行榜
  static async getLeaderboard(limit: number = 10, offset: number = 0) {
    return DataService.getLeaderboard(limit, offset)
  }

  // 获取游戏统计
  static async getGameStats() {
    return DataService.getGameStats()
  }

  // 获取卡片数据（静态数据）
  static async getCards(shuffle: boolean = true): Promise<{ cards: Card[], total: number }> {
    return DataService.getCards(shuffle)
  }
}
