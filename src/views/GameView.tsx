import React, { useEffect, useState } from 'react'
import { CardGallery, StagingArea, AnswerList, CardZoomModal, TextureBackground } from '../components'
import { useGameStore } from '../store/gameStore'
import { mockCards } from '../utils/mockData'
import { shuffleCards } from '../utils/cardUtils'
import { Card } from '../types'

export const GameView: React.FC = () => {
  const { setAvailableCards, submittedCombinations } = useGameStore()
  const [zoomCard, setZoomCard] = useState<Card | null>(null)

  // 初始化卡片数据（每次游戏开始时随机排序）
  useEffect(() => {
    const shuffledCards = shuffleCards(mockCards)
    setAvailableCards(shuffledCards)
  }, [setAvailableCards])

  return (
    <TextureBackground className="min-h-screen page-background">
      {/* 游戏头部 */}
      <div className="bg-wafuu-pure-white shadow-lg border-b border-wafuu-light-gray">
        <div className="max-w-6xl mx-auto px-4 py-6">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-title font-heavy text-wafuu-ink-black">
                旮旯画师之猜猜笔
              </h1>
              <p className="text-sm font-body text-wafuu-ink-black opacity-70 mt-1">
                海带姬松书院出品
              </p>
            </div>
            <div className="text-right">
              <div className="text-sm font-body text-wafuu-ink-black opacity-60">进度</div>
              <div className="text-2xl font-title font-bold text-wafuu-deep-blue">
                {submittedCombinations.length} / 9 组
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* 游戏主体 */}
      <div className="max-w-6xl mx-auto px-2 sm:px-4 py-6 sm:py-8 relative z-10">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 sm:gap-8">
          {/* 左侧：组合构建区 */}
          <div className="lg:col-span-2 space-y-6 sm:space-y-8">
            <StagingArea />
            <CardGallery onCardZoom={setZoomCard} />
          </div>

          {/* 右侧：答案列表 */}
          <div className="lg:col-span-1">
            <AnswerList />
          </div>
        </div>
      </div>

      {/* 卡片放大模态框 */}
      <CardZoomModal
        card={zoomCard}
        isOpen={!!zoomCard}
        onClose={() => setZoomCard(null)}
      />

      {/* 游戏说明（移动端底部固定） */}
      <div className="lg:hidden fixed bottom-0 left-0 right-0 bg-wafuu-pure-white border-t border-wafuu-light-gray p-4 shadow-lg">
        <div className="text-center">
          <p className="text-xs sm:text-sm font-body text-wafuu-ink-black leading-tight">
            💡 根据画风将卡片分为9组，每组3张。标记你认为是AI生成的作品
          </p>
        </div>
      </div>
      
      {/* 移动端底部间距 */}
      <div className="lg:hidden h-20"></div>
    </TextureBackground>
  )
}