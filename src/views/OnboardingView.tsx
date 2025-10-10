import React, { useState } from 'react'
import { Button } from '../design-system'
import { useGameStore } from '../store/gameStore'
import { GameState } from '../types'

export const OnboardingView: React.FC = () => {
  const [nickname, setNickname] = useState('')
  const { setUserInfo, setGameState } = useGameStore()

  const handleStartGame = () => {
    if (nickname.trim()) {
      setUserInfo({
        nickname: nickname.trim(),
        createdAt: new Date()
      })
      setGameState(GameState.PLAYING)
    }
  }

  const isValidNickname = nickname.trim().length >= 2

  return (
    <div className="min-h-screen page-background flex items-center justify-center p-3 sm:p-4">
      <div className="bg-wafuu-pure-white rounded-xl shadow-lg max-w-md w-full p-6 sm:p-8">
        {/* 游戏标题 */}
        <div className="text-center mb-8">
          <h1 className="text-3xl font-title font-heavy text-wafuu-ink-black mb-2">
            旮旯画师之猜猜笔
          </h1>
          <p className="text-sm font-body text-wafuu-ink-black opacity-70">
          百团招新小活动 - 测试你的画风识别能力
          </p>
        </div>

        {/* 游戏说明 */}
        <div className="mb-8 space-y-4">
          <div className="bg-blue-50 rounded-lg p-4">
            <h3 className="font-semibold text-blue-900 mb-2">游戏规则</h3>
            <ul className="text-sm text-blue-800 space-y-1">
              <li>在这27张印有游戏CG的卡片中，每三张出自同一位画师，你需要做出如下操作</li>
              <li> 1.分组：该27张卡片为打乱状态，根据游玩经验，人物特征，作画风格等将每三张卡片分为一组。</li>
              <li>2.鉴别：在这9组卡片中，每组有概率出现一张为AI模仿该画师画风创作的CG，请你从中鉴别出来。(总共含有4-6张AI卡片)</li>
              <li>3.验证：提交并验证你的答案，分数超过60分即可获得神秘小礼品。</li>
            </ul>
          </div>
          
          <div className="bg-yellow-50 rounded-lg p-4">
            <h3 className="font-semibold text-yellow-900 mb-2">评分标准</h3>
            <ul className="text-sm text-yellow-800 space-y-1">
              <li>• 分组部分：每正确分组一组得8分，满分70分</li>
              <li>• AI鉴别部分：正确找出AI得7.5分，误判扣3分，满分30分</li>
              <li>• 总分：100分</li>
            </ul>
          </div>
        </div>

        {/* 昵称输入 */}
        <div className="mb-6">
          <label className="block text-sm font-medium text-accessible-text-on-light mb-2">
            输入你的昵称
          </label>
          <input
            type="text"
            value={nickname}
            onChange={(e) => setNickname(e.target.value)}
            placeholder="至少 2 个字符"
            className="w-full px-4 py-3 border border-accessible-border rounded-lg focus:ring-2 focus:ring-game-info focus:border-transparent transition-colors text-accessible-text-on-light bg-wafuu-pure-white"
            maxLength={20}
          />
          <p className="text-xs text-accessible-text-secondary mt-1">
            昵称将显示在最终成绩中
          </p>
        </div>

        {/* 开始按钮 */}
        <Button
          variant="primary"
          size="lg"
          className="w-full"
          onClick={handleStartGame}
          disabled={!isValidNickname}
        >
          开始挑战
        </Button>


        {/* 底部提示 */}
        <div className="mt-4 text-center">
          <p className="text-xs text-accessible-text-secondary">
            游戏数据仅保存在本地浏览器中
          </p>
        </div>
      </div>

    </div>
  )
}