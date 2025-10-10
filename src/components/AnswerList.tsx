import React, { useState } from 'react'
import { Card, Button } from '../design-system'
import { useGameStore } from '../store/gameStore'
import { submitAnswers } from '../services/api'
import { GameState } from '../types'

// AnswerList 组件属性
interface AnswerListProps {
  className?: string
}

export const AnswerList: React.FC<AnswerListProps> = ({ className = '' }) => {
  const { 
    submittedCombinations, 
    clearCombinations, 
    setFinalScore, 
    setGameState,
    userInfo
  } = useGameStore()
  const [isSubmitting, setIsSubmitting] = useState(false)

  const handleSubmitAll = async () => {
    if (submittedCombinations.length === 0) return
    
    setIsSubmitting(true)
    try {
      const nickname = userInfo?.nickname || '匿名玩家'
      const result = await submitAnswers(submittedCombinations, nickname)
      setFinalScore(result.totalScore)
      setGameState(GameState.COMPLETED)
    } catch (error) {
      console.error('提交失败:', error)
      alert('提交失败，请稍后重试')
    } finally {
      setIsSubmitting(false)
    }
  }

  if (submittedCombinations.length === 0) {
    return (
      <div className={`bg-white rounded-lg shadow-sm border p-4 ${className}`}>
        <h3 className="text-lg font-semibold text-gray-800 mb-4">
          已提交答案
        </h3>
        <div className="text-center py-8 text-gray-500">
          <div className="text-4xl mb-2">📝</div>
          <p>还没有提交任何答案</p>
          <p className="text-sm mt-1">在上方构建区完成组合后点击"锁定答案"</p>
        </div>
      </div>
    )
  }

  return (
    <div className={`bg-white rounded-lg shadow-sm border p-4 ${className}`}>
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-semibold text-gray-800">
          已提交答案
        </h3>
        <div className="flex items-center gap-2">
          <span className="text-sm text-gray-500">
            {submittedCombinations.length} 组答案
          </span>
          <Button
            variant="ghost"
            size="sm"
            onClick={clearCombinations}
          >
            清空全部
          </Button>
        </div>
      </div>

      {/* 答案列表 */}
      <div className="space-y-4">
        {submittedCombinations.map((combination, index) => (
          <div
            key={index}
            className="p-3 bg-gray-50 rounded-lg border"
          >
            <div className="flex items-center justify-between mb-3">
              <span className="text-sm font-medium text-gray-700">
                组合 {index + 1}
              </span>
              {combination.aiMarkedCardId && (
                <span className="text-xs bg-yellow-100 text-yellow-800 px-2 py-1 rounded">
                  AI: {combination.aiMarkedCardId}
                </span>
              )}
            </div>
            
            {/* 组合中的卡片 */}
            <div className="flex gap-2 justify-center">
              {combination.cards.map((card, cardIndex) => (
                <Card
                  key={`${index}-${cardIndex}`}
                  card={card}
                  size="normal"
                  aiMarked={combination.aiMarkedCardId === card.id}
                  className="transform scale-75"
                />
              ))}
            </div>
          </div>
        ))}
      </div>

      {/* 提交按钮 */}
      {submittedCombinations.length > 0 && (
        <div className="mt-6 text-center">
          <Button 
            variant="primary" 
            size="lg"
            loading={isSubmitting}
            onClick={handleSubmitAll}
          >
            {isSubmitting ? '提交中...' : `提交所有答案 (${submittedCombinations.length} 组)`}
          </Button>
          <p className="text-xs text-gray-500 mt-2">
            提交后将计算最终分数
          </p>
        </div>
      )}
    </div>
  )
}