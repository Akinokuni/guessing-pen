// 设计系统 - 字体令牌 (和风数字卡片集主题)

export const typography = {
  // 字体族 - 按照美学设计方案
  fontFamily: {
    // 主标题字体 - SmileySans (Logo / Main Title)
    title: ['SmileySans', 'PingFang SC', 'Microsoft YaHei', 'sans-serif'],
    
    // 卡片编号字体 - AlibabaSans (Card ID)
    cardId: ['AlibabaSans', 'Monaco', 'Consolas', 'monospace'],
    
    // 正文与UI字体 - SourceHanSerif (Body & Interface)
    body: ['SourceHanSerif', 'Source Han Serif CN', 'Noto Serif CJK SC', 'serif'],
    
    // 备用无衬线字体
    sans: ['Inter', 'system-ui', 'sans-serif'],
    mono: ['Fira Code', 'monospace'],
  },
  
  // 字体大小
  fontSize: {
    xs: '0.75rem',    // 12px
    sm: '0.875rem',   // 14px
    base: '1rem',     // 16px
    lg: '1.125rem',   // 18px
    xl: '1.25rem',    // 20px
    '2xl': '1.5rem',  // 24px
    '3xl': '1.875rem', // 30px
    '4xl': '2.25rem', // 36px
    '5xl': '3rem',    // 48px - 主标题
  },
  
  // 字重
  fontWeight: {
    normal: '400',
    medium: '500',
    semibold: '600',
    bold: '700',
    heavy: '800',     // 主标题用
  },
  
  // 行高
  lineHeight: {
    tight: '1.25',
    normal: '1.5',
    relaxed: '1.75',
  }
} as const

export type TypographyToken = typeof typography