// 设计系统 - 间距令牌

export const spacing = {
  // 基础间距
  xs: '0.25rem',   // 4px
  sm: '0.5rem',    // 8px
  md: '1rem',      // 16px
  lg: '1.5rem',    // 24px
  xl: '2rem',      // 32px
  '2xl': '3rem',   // 48px
  '3xl': '4rem',   // 64px
  
  // 游戏专用间距
  game: {
    cardGap: '0.75rem',      // 卡片间距 12px
    sectionGap: '1.5rem',    // 区域间距 24px
    containerPadding: '1rem', // 容器内边距 16px
  },
  
  // 卡片尺寸 (15:10 横版比例)
  card: {
    width: '150px',
    height: '100px',
    widthLarge: '225px',
    heightLarge: '150px',
  }
} as const

export type SpacingToken = typeof spacing