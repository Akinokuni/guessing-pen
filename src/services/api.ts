import { SubmissionPayload, ApiResponse, Card } from '../types'
import { PostgRESTService } from './postgrestService'

// API 基础配置
const API_BASE_URL = '/api'

// 强制使用 PostgREST
const usePostgREST = true

// API 服务类
export class ApiService {
  // 提交答案
  static async submitAnswers(payload: SubmissionPayload, nickname: string = '匿名玩家'): Promise<ApiResponse> {
    try {
      // 使用 PostgREST 后端
      return await PostgRESTService.submitAnswers(payload, nickname)
    } catch (error) {
      console.error('API submission error:', error)
      throw new Error('提交答案失败，请稍后重试')
    }
  }
  
  // 获取卡片数据
  static async getCards(shuffle: boolean = true): Promise<{ cards: Card[], total: number }> {
    try {
      return await PostgRESTService.getCards(shuffle)
    } catch (error) {
      console.error('API get cards error:', error)
      throw new Error('获取卡片数据失败')
    }
  }
  
  // 获取游戏统计
  static async getStats() {
    try {
      return await PostgRESTService.getGameStats()
    } catch (error) {
      console.error('API get stats error:', error)
      throw new Error('获取统计数据失败')
    }
  }
  
  // 获取排行榜
  static async getLeaderboard(limit: number = 10, offset: number = 0) {
    try {
      return await PostgRESTService.getLeaderboard(limit, offset)
    } catch (error) {
      console.error('API get leaderboard error:', error)
      throw new Error('获取排行榜失败')
    }
  }
  
  // 提交分数到排行榜
  static async submitScore(nickname: string, score: number, combinations: number) {
    try {
      // 模拟提交
      console.log(`Mock submitting score for ${nickname}: ${score} points, ${combinations} combinations`)
      await new Promise(resolve => setTimeout(resolve, 150))
      return { success: true, message: '分数已提交' }
    } catch (error) {
      console.error('API submit score error:', error)
      throw new Error('提交分数失败')
    }
  }
}

// 导出便捷函数
export const submitAnswers = ApiService.submitAnswers
export const getCards = ApiService.getCards
export const getStats = ApiService.getStats
export const getLeaderboard = ApiService.getLeaderboard
export const submitScore = ApiService.submitScore