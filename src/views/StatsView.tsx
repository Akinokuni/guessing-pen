import React, { useEffect, useState } from 'react'
import { Button } from '../design-system'
import { getStats } from '../services/api'
import { useGameStore } from '../store/gameStore'
import { GameState } from '../types'

interface GameStats {
  total_players: number
  average_score: number
  highest_score: number
  completion_rate: number
  ai_detection_accuracy: number
}

// 工具函数
const formatPercentage = (value: number) => {
  return `${Math.round(value * 100)}%`
}

const getAccuracyColor = (accuracy: number) => {
  if (accuracy >= 0.8) return 'text-green-600'
  if (accuracy >= 0.6) return 'text-yellow-600'
  return 'text-red-600'
}

// 统计卡片组件
const StatCard: React.FC<{
  title: string
  value: string | number
  subtitle?: string
  icon: string
  color?: string
}> = ({ title, value, subtitle, icon, color = 'text-blue-600' }) => (
  <div className="bg-wafuu-pure-white rounded-lg shadow-sm border border-accessible-border p-6 text-center">
    <div className="text-3xl mb-2">{icon}</div>
    <div className={`text-2xl font-bold ${color} mb-1`}>
      {value}
    </div>
    <div className="text-sm font-medium text-accessible-text-on-light mb-1">
      {title}
    </div>
    {subtitle && (
      <div className="text-xs text-accessible-text-secondary">
        {subtitle}
      </div>
    )}
  </div>
)

// 加载状态组件
const LoadingState: React.FC = () => (
  <div className="bg-wafuu-pure-white rounded-xl shadow-lg p-8 text-center">
    <div className="animate-spin w-8 h-8 border-4 border-blue-500 border-t-transparent rounded-full mx-auto mb-4"></div>
    <p className="text-accessible-text-secondary">加载统计数据中...</p>
  </div>
)

// 错误状态组件
const ErrorState: React.FC<{
  error: string
  onRetry: () => void
}> = ({ error, onRetry }) => (
  <div className="bg-wafuu-pure-white rounded-xl shadow-lg p-8 text-center">
    <div className="text-4xl mb-4">😕</div>
    <p className="text-accessible-text-secondary mb-4">{error}</p>
    <Button onClick={onRetry}>重试</Button>
  </div>
)

// 统计卡片网格组件
const StatsGrid: React.FC<{ stats: GameStats }> = ({ stats }) => (
  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
    <StatCard
      title="总玩家数"
      value={stats.total_players?.toLocaleString() || '0'}
      subtitle="已参与挑战"
      icon="👥"
      color="text-blue-600"
    />
    
    <StatCard
      title="平均分数"
      value={stats.average_score?.toFixed(1) || '0.0'}
      subtitle="平均水平"
      icon="📈"
      color="text-green-600"
    />
    
    <StatCard
      title="最高分数"
      value={stats.highest_score || '0'}
      subtitle="当前记录保持者"
      icon="🏆"
      color="text-yellow-600"
    />
    
    <StatCard
      title="完成率"
      value={formatPercentage(stats.completion_rate || 0)}
      subtitle="完成全部挑战"
      icon="✅"
      color="text-purple-600"
    />
    
    <StatCard
      title="AI识别准确率"
      value={formatPercentage(stats.ai_detection_accuracy || 0)}
      subtitle="平均识别水平"
      icon="🤖"
      color={getAccuracyColor(stats.ai_detection_accuracy || 0)}
    />
    
    <StatCard
      title="挑战难度"
      value="困难"
      subtitle="基于数据分析"
      icon="🎯"
      color="text-red-600"
    />
  </div>
)

// 详细分析组件
const DetailedAnalysis: React.FC<{ stats: GameStats }> = ({ stats }) => (
  <div className="bg-wafuu-pure-white rounded-xl shadow-lg p-6 mb-8">
    <h3 className="text-xl font-semibold text-accessible-text-on-light mb-4">
      📈 数据分析
    </h3>
    
    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
      <div>
        <h4 className="font-medium text-accessible-text-on-light mb-2">游戏难度分析</h4>
        <div className="space-y-2 text-sm">
          <div className="flex justify-between">
            <span>完成率:</span>
            <span className={(stats.completion_rate || 0) >= 0.7 ? 'text-green-600' : 'text-red-600'}>
              {formatPercentage(stats.completion_rate || 0)}
            </span>
          </div>
          <div className="flex justify-between">
            <span>AI识别难度:</span>
            <span className={getAccuracyColor(stats.ai_detection_accuracy || 0)}>
              {(stats.ai_detection_accuracy || 0) >= 0.7 ? '中等' : '困难'}
            </span>
          </div>
        </div>
      </div>
      
      <div>
        <h4 className="font-medium text-accessible-text-on-light mb-2">分数分布</h4>
        <div className="space-y-2 text-sm">
          <div className="flex justify-between">
            <span>平均分:</span>
            <span className="text-blue-600">{stats.average_score?.toFixed(1) || '0.0'}</span>
          </div>
          <div className="flex justify-between">
            <span>最高分:</span>
            <span className="text-yellow-600">{stats.highest_score || 0}</span>
          </div>
          <div className="flex justify-between">
            <span>理论最高分:</span>
            <span className="text-accessible-text-secondary">100</span>
          </div>
        </div>
      </div>
    </div>
  </div>
)

export const StatsView: React.FC = () => {
  const [stats, setStats] = useState<GameStats | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const { setGameState } = useGameStore()

  useEffect(() => {
    loadStats()
  }, [])

  const loadStats = async () => {
    try {
      setLoading(true)
      const result = await getStats()
      setStats(result.data)
    } catch (err) {
      setError('获取统计数据失败')
      console.error('Stats error:', err)
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
            游戏统计
          </h1>
          <p className="text-accessible-text-on-dark opacity-80">
            玩家的游戏数据分析
          </p>
        </div>

        {loading ? (
          <LoadingState />
        ) : error ? (
          <ErrorState error={error} onRetry={loadStats} />
        ) : stats ? (
          <>
            <StatsGrid stats={stats} />
            <DetailedAnalysis stats={stats} />
          </>
        ) : null}

        {/* 底部按钮 */}
        <div className="text-center">
          <Button
            variant="primary"
            size="lg"
            onClick={handleBackToGame}
          >
            开始挑战
          </Button>
        </div>
      </div>
    </div>
  )
}