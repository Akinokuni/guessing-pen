import React from 'react'
import { Button } from '../design-system'
import { useGameStore } from '../store/gameStore'
import { GameState } from '../types'

interface NavigationProps {
  currentState: GameState
  className?: string
}

// 导航项配置
const getNavItems = (userInfo: any) => [
  {
    state: GameState.ONBOARDING,
    label: '开始',
    icon: '🏠',
    show: true
  },
  {
    state: GameState.PLAYING,
    label: '游戏',
    icon: '🎮',
    show: !!userInfo
  },
  {
    state: GameState.LEADERBOARD,
    label: '排行榜',
    icon: '🏆',
    show: true
  },
  {
    state: GameState.STATS,
    label: '统计',
    icon: '📊',
    show: true
  }
]

// 桌面端导航菜单
const DesktopNavMenu: React.FC<{
  navItems: any[]
  currentState: GameState
  onNavigation: (state: GameState) => void
}> = ({ navItems, currentState, onNavigation }) => (
  <div className="flex items-center gap-2">
    {navItems
      .filter(item => item.show)
      .map(item => (
        <Button
          key={item.state}
          variant={currentState === item.state ? 'primary' : 'secondary'}
          size="sm"
          onClick={() => onNavigation(item.state)}
          className="hidden sm:flex"
        >
          <span className="mr-1">{item.icon}</span>
          {item.label}
        </Button>
      ))}
  </div>
)

// 移动端导航菜单
const MobileNavMenu: React.FC<{
  navItems: any[]
  currentState: GameState
  onNavigation: (state: GameState) => void
}> = ({ navItems, currentState, onNavigation }) => (
  <div className="sm:hidden flex gap-1">
    {navItems
      .filter(item => item.show)
      .map(item => (
        <button
          key={item.state}
          onClick={() => onNavigation(item.state)}
          className={`p-2 rounded-lg transition-colors ${
            currentState === item.state
              ? 'bg-blue-100 text-blue-600'
              : 'text-gray-600 hover:bg-gray-100'
          }`}
          title={item.label}
        >
          <span className="text-lg">{item.icon}</span>
        </button>
      ))}
  </div>
)

// 用户信息显示
const UserInfo: React.FC<{
  userInfo: any
  finalScore: number | null
}> = ({ userInfo, finalScore }) => {
  if (!userInfo) return null
  
  return (
    <div className="hidden md:flex items-center gap-3">
      <div className="text-right">
        <div className="text-sm font-medium text-accessible-text-on-light">
          {userInfo.nickname}
        </div>
        {finalScore !== null && (
          <div className="text-xs text-accessible-text-secondary">
            最高分: {finalScore}
          </div>
        )}
      </div>
      <div className="w-8 h-8 bg-game-info rounded-full flex items-center justify-center">
        <span className="text-accessible-text-on-dark font-semibold text-sm">
          {userInfo.nickname.charAt(0)}
        </span>
      </div>
    </div>
  )
}

export const Navigation: React.FC<NavigationProps> = ({ 
  currentState, 
  className = '' 
}) => {
  const { setGameState, userInfo, finalScore } = useGameStore()
  const navItems = getNavItems(userInfo)

  const handleNavigation = (state: GameState) => {
    setGameState(state)
  }

  return (
    <nav className={`bg-wafuu-pure-white shadow-sm border-b border-accessible-border ${className}`}>
      <div className="max-w-6xl mx-auto px-4">
        <div className="flex items-center justify-between h-16">
          {/* Logo */}
          <div className="flex items-center gap-3">
            <div>
              <h1 className="text-lg font-title font-heavy text-wafuu-ink-black">
                旮旯画师之猜猜笔
              </h1>
              <p className="text-xs font-body text-wafuu-ink-black opacity-70 hidden sm:block">
                海带姬松书院出品
              </p>
            </div>
          </div>

          {/* 导航菜单 */}
          <div className="flex items-center gap-2">
            <DesktopNavMenu 
              navItems={navItems}
              currentState={currentState}
              onNavigation={handleNavigation}
            />
            <MobileNavMenu 
              navItems={navItems}
              currentState={currentState}
              onNavigation={handleNavigation}
            />
          </div>

          {/* 用户信息 */}
          <UserInfo userInfo={userInfo} finalScore={finalScore} />
        </div>
      </div>
    </nav>
  )
}