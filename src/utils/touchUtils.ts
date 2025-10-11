// 移动端触摸工具函数

// 检测是否为移动设备
export const isMobileDevice = (): boolean => {
  return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)
}

// 检测是否支持触摸
export const isTouchDevice = (): boolean => {
  return 'ontouchstart' in window || navigator.maxTouchPoints > 0
}

// 防止双击缩放
export const preventDoubleClickZoom = (element: HTMLElement): void => {
  let lastTouchEnd = 0
  element.addEventListener('touchend', (event) => {
    const now = new Date().getTime()
    if (now - lastTouchEnd <= 300) {
      event.preventDefault()
    }
    lastTouchEnd = now
  }, false)
}

// 触摸反馈动画
export const addTouchFeedback = (element: HTMLElement): void => {
  element.addEventListener('touchstart', () => {
    element.style.transform = 'scale(0.98)'
    element.style.transition = 'transform 0.1s ease'
  })
  
  element.addEventListener('touchend', () => {
    element.style.transform = 'scale(1)'
  })
  
  element.addEventListener('touchcancel', () => {
    element.style.transform = 'scale(1)'
  })
}

// 优化滚动性能
export const optimizeScrolling = (element: HTMLElement): void => {
  // 使用类型断言来处理webkit特定属性
  const elementStyle = element.style as CSSStyleDeclaration & {
    webkitOverflowScrolling?: string
  }
  elementStyle.webkitOverflowScrolling = 'touch'
  element.style.setProperty('-webkit-overflow-scrolling', 'touch')
}

// 禁用文本选择
export const disableTextSelection = (element: HTMLElement): void => {
  // 使用类型断言来处理webkit特定属性
  const elementStyle = element.style as CSSStyleDeclaration & {
    webkitUserSelect?: string
  }
  elementStyle.webkitUserSelect = 'none'
  element.style.userSelect = 'none'
  element.style.setProperty('-webkit-touch-callout', 'none')
}