import { useGameStore } from './store/gameStore'
import { OnboardingView, GameView, CompletedView, LeaderboardView, StatsView } from './views'
import { Navigation } from './components'
import { GameState } from './types'
import './App.css'

function App() {
  const { gameState } = useGameStore()

  // 根据游戏状态渲染不同的视图
  const renderCurrentView = () => {
    switch (gameState) {
      case GameState.ONBOARDING:
        return <OnboardingView />
      case GameState.PLAYING:
        return <GameView />
      case GameState.COMPLETED:
        return <CompletedView />
      case GameState.LEADERBOARD:
        return <LeaderboardView />
      case GameState.STATS:
        return <StatsView />
      default:
        return <OnboardingView />
    }
  }

  return (
    <div className="app-container">
      {/* 导航栏 - 只在非游戏页面显示 */}
      {gameState !== GameState.PLAYING && gameState !== GameState.COMPLETED && (
        <Navigation currentState={gameState} />
      )}
      {renderCurrentView()}
    </div>
  )
}

export default App