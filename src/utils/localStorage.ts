// localStorage 工具函数

const STORAGE_KEYS = {
  USER_INFO: 'guessing-pen-user-info',
  GAME_STATE: 'guessing-pen-game-state',
  GAME_PROGRESS: 'guessing-pen-game-progress'
} as const

// 安全的 localStorage 操作
export const storage = {
  // 获取数据
  get<T>(key: string, defaultValue: T): T {
    try {
      const item = localStorage.getItem(key)
      return item ? JSON.parse(item) : defaultValue
    } catch (error) {
      console.warn('localStorage get error:', error)
      return defaultValue
    }
  },

  // 设置数据
  set<T>(key: string, value: T): void {
    try {
      localStorage.setItem(key, JSON.stringify(value))
    } catch (error) {
      console.warn('localStorage set error:', error)
    }
  },

  // 删除数据
  remove(key: string): void {
    try {
      localStorage.removeItem(key)
    } catch (error) {
      console.warn('localStorage remove error:', error)
    }
  },

  // 清空所有游戏数据
  clear(): void {
    Object.values(STORAGE_KEYS).forEach(key => {
      this.remove(key)
    })
  }
}

// 游戏专用的 localStorage 操作
export const gameStorage = {
  // 用户信息
  getUserInfo() {
    return storage.get(STORAGE_KEYS.USER_INFO, null)
  },
  
  setUserInfo(userInfo: any) {
    storage.set(STORAGE_KEYS.USER_INFO, userInfo)
  },

  // 游戏状态
  getGameState() {
    return storage.get(STORAGE_KEYS.GAME_STATE, 'onboarding')
  },
  
  setGameState(state: string) {
    storage.set(STORAGE_KEYS.GAME_STATE, state)
  },

  // 游戏进度
  getGameProgress() {
    return storage.get(STORAGE_KEYS.GAME_PROGRESS, {
      submittedCombinations: [],
      finalScore: null
    })
  },
  
  setGameProgress(progress: any) {
    storage.set(STORAGE_KEYS.GAME_PROGRESS, progress)
  },

  // 清空所有数据
  clearAll() {
    storage.clear()
  }
}