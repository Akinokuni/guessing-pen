import React, { useEffect, useState } from 'react'
import { Button } from '../design-system'
import { getLeaderboard } from '../services/api'
import { useGameStore } from '../store/gameStore'
import { GameState, UserInfo } from '../types'

interface LeaderboardEntry {
  rank: number
  nickname: string
  total_score: number
  combinations_count: number
  completed_at: string
}

// 工具函数
const getRankIcon = (rank: number) => {
  switch (rank) {
    case 1: return '🥇'
    case 2: return '🥈'
    case 3: return '🥉'
    default: return rank
  }
}

const getScoreColor = (score: number) => {
  if (score >= 240) return 'text-yellow-600'
  if (score >= 200) return 'text-green-600'
  if (score >= 150) return 'text-blue-600'
  if (score >= 100) return 'text-purple-600'
  return 'text-accessible-text-secondary'
}

const formatDate = (dateString: string) => {
  return new Date(dateString).toLocaleDateString('zh-CN', {
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

// 当前玩家成绩组件
const PlayerScore: React.FC<{
  userInfo: UserInfo
  finalScore: number
}> = ({ userInfo, finalScore }) => (
  <div className="bg-wafuu-pure-white rounded-xl shadow-lg p-6 mb-6 border-2 border-game-info">
    <div className="text-center">
      <h3 className="text-lg font-semibold text-accessible-text-on-light mb-2">
        你的成绩
      </h3>
      <div className="flex items-center justify-center gap-4">
        <div className="text-center">
          <div className="text-2xl font-bold text-blue-600">
            {finalScore}
          </div>
          <div className="text-sm text-accessible-text-secondary">总分</div>
        </div>
        <div className="text-center">
          <div className="text-xl font-semibold text-accessible-text-on-light">
            {userInfo.nickname}
          </div>
          <div className="text-sm text-accessible-text-secondary">玩家</div>
        </div>
      </div>
    </div>
  </div>
)

// 排行榜头部组件
const LeaderboardHeader: React.FC<{
  loading: boolean
  onRefresh: () => void
}> = ({ loading, onRefresh }) => (
  <div className="p-6 border-b">
    <div className="flex items-center justify-between">
      <h2 className="text-xl font-semibold text-accessible-text-on-light">
        排行榜
      </h2>
      <Button
        variant="ghost"
        size="sm"
        onClick={onRefresh}
        disabled={loading}
      >
        {loading ? '刷新中...' : '刷新'}
      </Button>
    </div>
  </div>
)

// 加载状态组件
const LoadingState: React.FC = () => (
  <div className="p-8 text-center">
    <div className="animate-spin w-8 h-8 border-4 border-blue-500 border-t-transparent rounded-full mx-auto mb-4"></div>
    <p className="text-accessible-text-secondary">加载排行榜中...</p>
  </div>
)

// 错误状态组件
const ErrorState: React.FC<{
  error: string
  onRetry: () => void
}> = ({ error, onRetry }) => (
  <div className="p-8 text-center">
    <div className="text-4xl mb-4">😕</div>
    <p className="text-accessible-text-secondary mb-4">{error}</p>
    <Button onClick={onRetry}>重试</Button>
  </div>
)

// 空状态组件
const EmptyState: React.FC = () => (
  <div className="p-8 text-center">
    <div className="text-4xl mb-4">🎯</div>
    <p className="text-accessible-text-secondary mb-4">还没有玩家上榜</p>
    <p className="text-sm text-accessible-text-secondary">成为第一个挑战者吧！</p>
  </div>
)

// 排行榜条目组件
const LeaderboardItem: React.FC<{
  entry: LeaderboardEntry
  currentUser?: string
}> = ({ entry, currentUser }) => (
  <div
    className={`p-4 hover:bg-gray-50 transition-colors ${
      entry.nickname === currentUser ? 'bg-blue-50' : ''
    }`}
  >
    <div className="flex items-center justify-between">
      <div className="flex items-center gap-4">
        <div className="text-2xl font-bold w-12 text-center">
          {getRankIcon(entry.rank)}
        </div>
        <div>
          <div className="font-semibold text-accessible-text-on-light">
            {entry.nickname}
            {entry.nickname === currentUser && (
              <span className="ml-2 text-xs bg-blue-100 text-blue-800 px-2 py-1 rounded">
                你
              </span>
            )}
          </div>
          <div className="text-sm text-accessible-text-secondary">
            {entry.combinations_count} 组 • {formatDate(entry.completed_at)}
          </div>
        </div>
      </div>
      <div className="text-right">
        <div className={`text-xl font-bold ${getScoreColor(entry.total_score)}`}>
          {entry.total_score}
        </div>
        <div className="text-sm text-accessible-text-secondary">分</div>
      </div>
    </div>
  </div>
)

export const LeaderboardView: React.FC = () => {
  const [leaderboard, setLeaderboard] = useState<LeaderboardEntry[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const { setGameState, userInfo, finalScore } = useGameStore()

  useEffect(() => {
    loadLeaderboard()
  }, [])

  const loadLeaderboard = async () => {
    try {
      setLoading(true)
      const result = await getLeaderboard(20, 0)
      setLeaderboard(result.data || [])
    } catch (err) {
      setError('获取排行榜失败')
      console.error('Leaderboard error:', err)
    } finally {
      setLoading(false)
    }
  }

  const handleBackToGame = () => {
    setGameState(GameState.ONBOARDING)
  }

  return (
    <div className="min-h-screen page-background p-4">
      <div className="max-w-4xl mx-auto">
        {/* 头部 */}
        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold text-accessible-text-on-dark mb-2">
            排行榜
          </h1>
          <p className="text-accessible-text-on-dark opacity-80">
            看看谁是旮旯领域大神
          </p>
        </div>

        {/* 当前玩家成绩 */}
        {userInfo && finalScore !== null && (
          <PlayerScore userInfo={userInfo} finalScore={finalScore} />
        )}

        {/* 排行榜内容 */}
        <div className="bg-wafuu-pure-white rounded-xl shadow-lg overflow-hidden">
          <LeaderboardHeader loading={loading} onRefresh={loadLeaderboard} />

          {loading ? (
            <LoadingState />
          ) : error ? (
            <ErrorState error={error} onRetry={loadLeaderboard} />
          ) : leaderboard.length === 0 ? (
            <EmptyState />
          ) : (
            <div className="divide-y divide-gray-200">
              {leaderboard.map((entry, index) => (
                <LeaderboardItem
                  key={index}
                  entry={entry}
                  currentUser={userInfo?.nickname}
                />
              ))}
            </div>
          )}
        </div>

        {/* 底部按钮 */}
        <div className="mt-8 text-center">
          <Button
            variant="primary"
            size="lg"
            onClick={handleBackToGame}
          >
            再玩一次
          </Button>
        </div>

        {/* 游戏说明 */}
        <div className="mt-6 text-center text-sm text-accessible-text-secondary">
          <p>💡 提示：可重复游玩，完成更多组合并准确识别AI可以获得更高分数</p>
        </div>
      </div>
    </div>
  )
}