import React from 'react'
import { Card as CardType } from '../types'
import { Button } from '../design-system'

// CardZoomModal 组件属性
interface CardZoomModalProps {
  card: CardType | null
  isOpen: boolean
  onClose: () => void
}

export const CardZoomModal: React.FC<CardZoomModalProps> = ({
  card,
  isOpen,
  onClose
}) => {
  if (!isOpen || !card) return null

  const handleBackdropClick = (e: React.MouseEvent) => {
    if (e.target === e.currentTarget) {
      onClose()
    }
  }

  return (
    <div
      className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-2 sm:p-4"
      onClick={handleBackdropClick}
    >
      <div className="bg-white rounded-lg shadow-xl max-w-sm sm:max-w-lg w-full max-h-[90vh] overflow-hidden">
        {/* 模态框头部 */}
        <div className="flex items-center justify-between p-3 sm:p-4 border-b">
          <h3 className="text-lg font-semibold text-gray-800">
            {card.name || `卡片 ${card.id}`}
          </h3>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600 transition-colors"
          >
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        {/* 卡片图片 */}
        <div className="p-3 sm:p-4">
          <div className="w-full aspect-[15/10] bg-gray-100 rounded-lg overflow-hidden mb-4">
            {card.imageUrl ? (
              <img
                src={card.imageUrl}
                alt={card.name || `Card ${card.id}`}
                className="w-full h-full object-cover"
              />
            ) : (
              <div className="w-full h-full flex items-center justify-center text-gray-400">
                <div className="text-center">
                  <div className="text-lg">{card.id}</div>
                </div>
              </div>
            )}
          </div>

          {/* 卡片信息 */}
          <div className="space-y-2 mb-4">
            <div className="flex justify-between text-sm">
              <span className="text-gray-600">卡片ID:</span>
              <span className="font-mono">{card.id}</span>
            </div>
            {card.name && (
              <div className="flex justify-between text-sm">
                <span className="text-gray-600">名称:</span>
                <span>{card.name}</span>
              </div>
            )}
          </div>

          {/* 操作按钮 */}
          <div className="flex gap-2">
            <Button
              variant="outline"
              className="flex-1"
              onClick={onClose}
            >
              关闭
            </Button>
            <Button
              variant="primary"
              className="flex-1"
              onClick={() => {
                // 这里可以添加选择卡片的逻辑
                console.log('选择卡片:', card)
                onClose()
              }}
            >
              选择此卡片
            </Button>
          </div>
        </div>
      </div>
    </div>
  )
}