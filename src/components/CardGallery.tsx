import React from 'react'
import { Card } from '../design-system'
import { Card as CardType } from '../types'
import { useGameStore } from '../store/gameStore'
import { getAvailableCards } from '../utils/cardUtils'



// CardGallery 组件属性
interface CardGalleryProps {
  className?: string
  onCardZoom?: (card: CardType) => void
}

export const CardGallery: React.FC<CardGalleryProps> = ({ 
  className = '', 
  onCardZoom 
}) => {
  const { 
    availableCards, 
    selectedCards, 
    submittedCombinations,
    addSelectedCard
  } = useGameStore()

  const handleCardClick = (card: CardType) => {
    // 从画廊点击卡片只能添加，不能移除（因为已选中的卡片不在画廊中显示）
    if (selectedCards.length < 3) {
      addSelectedCard(card)
    }
  }

  // 获取真正可用的卡片（排除构建区和已提交的卡片）
  const displayCards = getAvailableCards(availableCards, selectedCards, submittedCombinations)

  return (
    <div className={`bg-white rounded-lg shadow-sm border p-4 ${className}`}>
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-semibold text-gray-800">
          卡片集
        </h3>
        <span className="text-sm text-gray-500">
          {displayCards.length} 张可选卡片
        </span>
      </div>
      
      {/* 横向滚动的卡片列表 */}
      <div className="overflow-x-auto" style={{ WebkitOverflowScrolling: 'touch' }}>
        <div className="flex gap-3 pb-2 px-1" style={{ minWidth: 'max-content' }}>
          {displayCards.map((card) => (
              <Card
                key={card.id}
                card={card}
                selected={false} // 画廊中的卡片都不显示为选中状态
                onClick={handleCardClick}
                onZoom={onCardZoom}
                className="flex-shrink-0"
              />
            ))}
        </div>
      </div>
      
      {/* 选择提示 */}
      <div className="mt-4 text-center">
        <p className="text-sm text-gray-600">
          已选择 {selectedCards.length}/3 张卡片
        </p>
        {selectedCards.length === 3 && (
          <p className="text-xs text-blue-600 mt-1">
            ✓ 可以构建组合了
          </p>
        )}
      </div>
    </div>
  )
}