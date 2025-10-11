import { create } from 'zustand'
import { subscribeWithSelector } from 'zustand/middleware'
import { Card, Combination, GameState, UserInfo } from '../types'
import { gameStorage } from '../utils/localStorage'

// 游戏状态接口
interface GameStore {
  // 用户信息
  userInfo: UserInfo | null
  setUserInfo: (userInfo: UserInfo) => void
  
  // 游戏状态
  gameState: GameState
  setGameState: (state: GameState) => void
  
  // 卡片数据
  availableCards: Card[]
  setAvailableCards: (cards: Card[]) => void
  
  // 当前选中的卡片（构建区）
  selectedCards: Card[]
  addSelectedCard: (card: Card) => void
  removeSelectedCard: (cardId: string) => void
  clearSelectedCards: () => void
  
  // AI 标记的卡片
  aiMarkedCardId: string | null
  setAiMarkedCard: (cardId: string | null) => void
  
  // 已提交的答案组合
  submittedCombinations: Combination[]
  addCombination: (combination: Combination) => void
  clearCombinations: () => void
  
  // 最终分数
  finalScore: number | null
  setFinalScore: (score: number) => void
  
  // 重置游戏
  resetGame: () => void
}

// 从 localStorage 恢复状态
const getInitialState = (): Partial<GameStore> => {
  const savedUserInfo = gameStorage.getUserInfo()
  const savedGameState = gameStorage.getGameState()
  const savedProgress = gameStorage.getGameProgress()
  
  return {
    userInfo: savedUserInfo,
    gameState: savedGameState as GameState,
    availableCards: [],
    selectedCards: [],
    aiMarkedCardId: null,
    submittedCombinations: (savedProgress.submittedCombinations as Combination[]) || [],
    finalScore: savedProgress.finalScore,
  }
}

// 创建 Zustand store
export const useGameStore = create<GameStore>()(
  subscribeWithSelector((set, get) => ({
    ...getInitialState(),
  
  setUserInfo: (userInfo: UserInfo) => {
    set({ userInfo })
    gameStorage.setUserInfo(userInfo)
  },
  
  setGameState: (gameState) => {
    set({ gameState })
    gameStorage.setGameState(gameState)
  },
  
  setAvailableCards: (availableCards) => set({ availableCards }),
  
  addSelectedCard: (card) => {
    const { selectedCards } = get()
    if (selectedCards.length < 3 && !selectedCards.find(c => c.id === card.id)) {
      set({ selectedCards: [...selectedCards, card] })
    }
  },
  
  removeSelectedCard: (cardId) => {
    const { selectedCards } = get()
    set({ selectedCards: selectedCards.filter(card => card.id !== cardId) })
  },
  
  clearSelectedCards: () => set({ selectedCards: [], aiMarkedCardId: null }),
  
  setAiMarkedCard: (aiMarkedCardId) => set({ aiMarkedCardId }),
  
  addCombination: (combination) => {
    const { submittedCombinations } = get()
    const newCombinations = [...submittedCombinations, combination]
    set({ submittedCombinations: newCombinations })
    gameStorage.setGameProgress({ submittedCombinations: newCombinations, finalScore: get().finalScore })
  },
  
  clearCombinations: () => set({ submittedCombinations: [] }),
  
  setFinalScore: (finalScore) => set({ finalScore }),
  
  resetGame: () => {
    gameStorage.clearAll()
    const initialState = getInitialState()
    set({
      userInfo: initialState.userInfo || null,
      gameState: initialState.gameState || GameState.ONBOARDING,
      availableCards: initialState.availableCards || [],
      selectedCards: initialState.selectedCards || [],
      aiMarkedCardId: initialState.aiMarkedCardId || null,
      submittedCombinations: initialState.submittedCombinations || [],
      finalScore: initialState.finalScore || null,
    })
  },
})))