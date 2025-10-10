import React from 'react'
import { Button } from '../design-system'
import { useGameStore } from '../store/gameStore'
import { GameState } from '../types'

export const CompletedView: React.FC = () => {
  const { 
    finalScore, 
    submittedCombinations, 
    resetGame,
    setGameState 
  } = useGameStore()

  const handlePlayAgain = () => {
    resetGame()
    setGameState(GameState.ONBOARDING)
  }

  const handleViewResults = () => {
    setGameState(GameState.PLAYING)
  }

  // 计算成绩等级（基于100分制）
  const getScoreGrade = (score: number) => {
    if (score >= 90) return { grade: 'S', color: 'text-yellow-600', bg: 'bg-yellow-50' }
    if (score >= 80) return { grade: 'A', color: 'text-green-600', bg: 'bg-green-50' }
    if (score >= 70) return { grade: 'B', color: 'text-blue-600', bg: 'bg-blue-50' }
    if (score >= 60) return { grade: 'C', color: 'text-purple-600', bg: 'bg-purple-50' }
    return { grade: 'D', color: 'text-accessible-text-secondary', bg: 'bg-gray-50' }
  }

  const scoreInfo = getScoreGrade(finalScore || 0)
  const maxPossibleScore = 100 // 游戏最高分100分

  return (
    <div className="min-h-screen page-background flex items-center justify-center p-4">
      <div className="bg-wafuu-pure-white rounded-xl shadow-lg max-w-md w-full p-8">
        {/* 完成标题 */}
        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold text-accessible-text-on-light mb-2">
            挑战完成！
          </h1>
        </div>

        {/* 分数展示 */}
        <div className="mb-8">
          <div className={`${scoreInfo.bg} rounded-lg p-6 text-center mb-4`}>
            <div className={`text-4xl font-bold ${scoreInfo.color} mb-2`}>
              {finalScore || 0}
            </div>
            <div className="text-sm text-accessible-text-secondary mb-2">
              总分 / {maxPossibleScore}
            </div>
            <div className={`inline-block px-3 py-1 rounded-full text-sm font-semibold ${scoreInfo.color} ${scoreInfo.bg} border`}>
              等级 {scoreInfo.grade}
            </div>
          </div>

          {/* 详细统计 */}
          <div className="grid grid-cols-2 gap-4 text-center">
            <div className="bg-gray-50 rounded-lg p-3">
              <div className="text-lg font-semibold text-accessible-text-on-light">
                {submittedCombinations.length}
              </div>
              <div className="text-sm text-accessible-text-secondary">完成组合</div>
            </div>
            <div className="bg-gray-50 rounded-lg p-3">
              <div className="text-lg font-semibold text-accessible-text-on-light">
                {Math.round(((finalScore || 0) / maxPossibleScore) * 100)}%
              </div>
              <div className="text-sm text-accessible-text-secondary">准确率</div>
            </div>
          </div>
        </div>


        {/* 操作按钮 */}
        <div className="space-y-3">
          <Button
            variant="primary"
            size="lg"
            className="w-full"
            onClick={handlePlayAgain}
          >
            再玩一次
          </Button>
          <div className="grid grid-cols-2 gap-3">
            <Button
              variant="secondary"
              onClick={() => setGameState('leaderboard' as GameState)}
            >
              排行榜
            </Button>
            <Button
              variant="secondary"
              onClick={() => setGameState('stats' as GameState)}
            >
              统计数据
            </Button>
          </div>
          <Button
            variant="ghost"
            className="w-full"
            onClick={handleViewResults}
          >
            查看详细结果
          </Button>
        </div>

        {/* 分享提示 */}
        <div className="mt-6 text-center">
          <p className="text-xs text-accessible-text-secondary">
            感谢参与游戏！
          </p>
        </div>
      </div>
    </div>
  )
}