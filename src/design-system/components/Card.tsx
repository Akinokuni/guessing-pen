import React from 'react'
import { Card as CardType } from '../../types'

// Card 组件属性接口
interface CardProps {
  card: CardType
  selected?: boolean
  aiMarked?: boolean
  size?: 'normal' | 'large'
  onClick?: (card: CardType) => void
  onAiToggle?: (cardId: string) => void
  onZoom?: (card: CardType) => void
  className?: string
}

export const Card: React.FC<CardProps> = ({
  card,
  selected = false,
  aiMarked = false,
  size = 'normal',
  onClick,
  onAiToggle,
  onZoom,
  className = '',
}) => {
  const sizeStyles = {
    normal: 'w-[120px] sm:w-[150px] h-[80px] sm:h-[100px]', // 15:10 横版比例，移动端更小
    large: 'w-[180px] sm:w-[225px] h-[120px] sm:h-[150px]',  // 15:10 横版比例 (大尺寸)
  }

  const baseStyles = 'relative bg-wafuu-pure-white rounded-lg border-2 shadow-sm card-hover-glow cursor-pointer overflow-hidden touch-manipulation select-none'
  
  const stateStyles = [
    selected ? 'border-wafuu-pure-white bg-wafuu-pure-white shadow-lg scale-105' : 'border-wafuu-light-gray hover:border-wafuu-pure-white active:scale-95',
    aiMarked ? 'ring-2 ring-game-ai-border' : '',
  ].join(' ')

  const combinedClassName = [
    baseStyles,
    sizeStyles[size],
    stateStyles,
    className,
  ].join(' ')

  const handleClick = () => {
    onClick?.(card)
  }

  const handleAiToggle = (e: React.MouseEvent) => {
    e.stopPropagation()
    onAiToggle?.(card.id)
  }

  const handleZoom = (e: React.MouseEvent) => {
    e.stopPropagation()
    onZoom?.(card)
  }

  return (
    <div className={combinedClassName} onClick={handleClick}>
      {/* 卡片图片 */}
      <div className="w-full h-full flex items-center justify-center bg-gray-100">
        {card.imageUrl ? (
          <img
            src={card.imageUrl}
            alt={card.name || `Card ${card.id}`}
            className="w-full h-full object-cover"
            loading="lazy"
          />
        ) : (
          <div className="text-gray-400 text-center">
            <div className="text-xs">{card.id}</div>
          </div>
        )}
      </div>

      {/* 放大按钮 */}
      {onZoom && (
        <button
          onClick={handleZoom}
          className="absolute top-2 left-2 w-7 h-7 bg-wafuu-deep-blue bg-opacity-70 hover:bg-opacity-90 rounded-full flex items-center justify-center transition-all"
          title="放大查看"
        >
          <svg className="w-4 h-4 text-accessible-text-on-dark" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0zM10 7v3m0 0v3m0-3h3m-3 0H7" />
          </svg>
        </button>
      )}

      {/* AI 标记按钮 */}
      {onAiToggle && (
        <button
          onClick={handleAiToggle}
          className={`absolute top-2 right-2 w-8 h-8 rounded-lg border-2 transition-all ai-marker-artistic ${
            aiMarked
              ? 'bg-game-ai border-game-ai-border text-wafuu-ink-black shadow-md'
              : 'bg-wafuu-pure-white border-wafuu-light-gray text-wafuu-ink-black opacity-60 hover:border-game-ai-border hover:opacity-100'
          }`}
          title={aiMarked ? '取消 AI 标记' : '标记为 AI'}
        >
          <span className="text-xs font-heavy">AI</span>
        </button>
      )}

      {/* 选中状态指示器 */}
      {selected && (
        <div className="absolute top-2 left-2 w-5 h-5 bg-blue-500 rounded-full flex items-center justify-center">
          <svg className="w-3 h-3 text-accessible-text-on-dark" fill="currentColor" viewBox="0 0 20 20">
            <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
          </svg>
        </div>
      )}
    </div>
  )
}