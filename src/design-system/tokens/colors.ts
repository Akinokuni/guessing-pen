// 设计系统 - 和风数字卡片集颜色令牌
// 严格按照美学设计方案和无障碍设计原则

export const colors = {
  // 和风主题核心色彩 - 严格按照美学设计方案
  wafuu: {
    // 主背景色 - 静谧深蓝
    deepBlue: '#002B6D',
    // 主功能区背景 - 纯白
    pureWhite: '#FFFFFF',
    // 辅助色/纹样色 - 浅灰
    lightGray: '#EFEFEF',
    // 主文本色 - 墨黑
    inkBlack: '#333333',
  },
  
  // 无障碍设计扩展色彩
  accessible: {
    // 高对比度文本色
    textOnDark: '#FFFFFF',      // 深蓝背景上的文本
    textOnLight: '#1A1A1A',     // 白色背景上的文本（确保4.5:1对比度）
    textSecondary: '#4A4A4A',   // 次要文本色
    
    // 交互状态色
    hover: '#F5F5F5',           // 悬停状态
    active: '#E8E8E8',          // 激活状态
    disabled: '#CCCCCC',        // 禁用状态
    
    // 边框和分割线
    border: '#D0D0D0',          // 主要边框
    borderLight: '#E8E8E8',     // 浅色边框
    divider: '#F0F0F0',         // 分割线
  },
  
  // 游戏专用颜色 - 保持高对比度
  game: {
    // 卡片相关
    cardBackground: '#FFFFFF',
    cardBorder: '#D0D0D0',
    cardSelected: '#E8F4FD',    // 选中状态 - 浅蓝背景
    cardHover: '#F8F9FA',       // 悬停状态
    
    // AI 标记相关 - 使用高对比度橙色
    aiMarker: '#E67E22',        // 深橙色，确保可读性
    aiBackground: '#FDF2E9',    // 浅橙色背景
    aiBorder: '#D35400',        // 深橙色边框
    
    // 状态颜色 - 确保无障碍对比度
    success: '#27AE60',         // 深绿色
    error: '#E74C3C',           // 深红色
    warning: '#F39C12',         // 深橙色
    info: '#3498DB',            // 深蓝色
  },
  
  // 语义化颜色系统
  semantic: {
    // 主要操作
    primary: '#FFFFFF',         // 主要按钮背景
    primaryText: '#1A1A1A',     // 主要按钮文字
    primaryHover: '#F5F5F5',    // 主要按钮悬停
    
    // 次要操作
    secondary: '#F5F5F5',       // 次要按钮背景
    secondaryText: '#1A1A1A',   // 次要按钮文字
    secondaryHover: '#E8E8E8',  // 次要按钮悬停
    
    // 危险操作
    danger: '#E74C3C',          // 危险按钮背景
    dangerText: '#FFFFFF',      // 危险按钮文字
    dangerHover: '#C0392B',     // 危险按钮悬停
  }
} as const

export type ColorToken = typeof colors