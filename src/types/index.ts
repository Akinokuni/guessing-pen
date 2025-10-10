// 核心数据类型定义

// 单张卡片的数据结构
export interface Card {
  id: string; // 卡片的唯一标识符, e.g., "card_01"
  imageUrl: string;
  name?: string; // 可选的卡片名称
}

// 单个组合的数据结构
export interface Combination {
  cards: [Card, Card, Card]; // 包含三张卡片的数组
  aiMarkedCardId: string | null; // 被标记为AI的卡片ID，若无则为null
}

// 发送给后端的最终数据结构
export type SubmissionPayload = Combination[]; // 由多个组合构成的数组

// 后端返回的结果详情
export interface ResultDetail {
  userCombination: Combination; // 用户提交的原始组合
  isGroupingCorrect: boolean;   // 这三张卡片是否本就属于一组
  isAiDetectionCorrect: boolean; // AI卡片的判断是否正确
}

// 后端 API 响应结构
export interface ApiResponse {
  nickname: string;
  totalScore: number; // 计算出的总分
  results: ResultDetail[]; // 每组答案的详细对错情况
}

// 游戏状态枚举
export enum GameState {
  ONBOARDING = 'onboarding',
  PLAYING = 'playing',
  COMPLETED = 'completed',
  LEADERBOARD = 'leaderboard',
  STATS = 'stats'
}

// 用户信息
export interface UserInfo {
  nickname: string;
  createdAt: Date;
}