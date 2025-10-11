import React from 'react'
import { Card as DesignCard, Button } from '../design-system'
import { Combination, Card } from '../types'
import { useGameStore } from '../store/gameStore'

// StagingArea 组件属性
interface StagingAreaProps {
  className?: string
}

export const StagingArea: React.FC<StagingAreaProps> = ({ className = '' }) => {
  const { 
    selectedCards, 
    aiMarkedCardId, 
    setAiMarkedCard,
    addCombination,
    clearSelectedCards,
    removeSelectedCard
  } = useGameStore()

  const handleAiToggle = (cardId: string) => {
    if (aiMarkedCardId === cardId) {
      setAiMarkedCard(null)
    } else {
      setAiMarkedCard(cardId)
    }
  }

  const handleCardClick = (card: Card) => {
    // 在构建区点击卡片可以移除它
    removeSelectedCard(card.id)
  }

  const handleSubmitCombination = () => {
    if (selectedCards.length === 3) {
      const combination: Combination = {
        cards: selectedCards as [Card, Card, Card],
        aiMarkedCardId
      }
      addCombination(combination)
      clearSelectedCards()
    }
  }

  const canSubmit = selectedCards.length === 3

  return (
    <div className={`bg-white rounded-lg shadow-sm border p-4 ${className}`}>
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-semibold text-gray-800">
          组合构建区
        </h3>
        <span className="text-sm text-gray-500">
          {selectedCards.length}/3
        </span>
      </div>

      {/* 构建区卡片槽位 */}
      <div className="flex justify-center gap-2 sm:gap-4 mb-4 sm:mb-6 overflow-x-auto pb-2">
        {[0, 1, 2].map((index) => {
          const card = selectedCards[index]
          
          return (
            <div
              key={index}
              className={`w-[120px] sm:w-[150px] h-[80px] sm:h-[100px] rounded-lg border-2 border-dashed flex items-center justify-center flex-shrink-0 ${
                card 
                  ? 'border-transparent' 
                  : 'border-gray-300 bg-gray-50'
              }`}
            >
              {card ? (
                <DesignCard
                  card={card}
                  selected={true}
                  aiMarked={aiMarkedCardId === card.id}
                  onAiToggle={handleAiToggle}
                  onClick={handleCardClick}
                />
              ) : (
                <div className="text-gray-400 text-center">
                  <div className="text-2xl mb-1">📋</div>
                  <div className="text-xs">槽位 {index + 1}</div>
                </div>
              )}
            </div>
          )
        })}
      </div>

      {/* AI 标记说明 */}
      {selectedCards.length > 0 && (
        <div className="mb-4 p-3 bg-yellow-50 rounded-lg border border-yellow-200">
          <p className="text-sm text-yellow-800">
            💡 点击卡片右上角的 "AI" 按钮来标记你认为是 AI 生成的卡片
          </p>
          {aiMarkedCardId && (
            <p className="text-xs text-yellow-700 mt-1">
              已标记: {selectedCards.find(c => c.id === aiMarkedCardId)?.name || aiMarkedCardId}
            </p>
          )}
        </div>
      )}

      {/* 操作按钮 */}
      <div className="flex gap-3 justify-center">
        <Button
          variant="outline"
          onClick={clearSelectedCards}
          disabled={selectedCards.length === 0}
        >
          清空
        </Button>
        <Button
          variant="primary"
          onClick={handleSubmitCombination}
          disabled={!canSubmit}
        >
          锁定答案
        </Button>
      </div>

      {/* 提示信息 */}
      {!canSubmit && (
        <p className="text-center text-sm text-gray-500 mt-3">
          请从下方卡片集选择 3 张卡片，点击构建区中的卡片可以移除
        </p>
      )}
    </div>
  )
}