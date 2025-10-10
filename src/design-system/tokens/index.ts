// 设计系统令牌统一导出

export { colors, type ColorToken } from './colors'
export { spacing, type SpacingToken } from './spacing'
export { typography, type TypographyToken } from './typography'

import { colors } from './colors'
import { spacing } from './spacing'
import { typography } from './typography'

// 设计令牌集合
export const designTokens = {
  colors,
  spacing,
  typography,
} as const