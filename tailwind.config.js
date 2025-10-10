/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      // 移动端优先的断点
      screens: {
        'xs': '375px',
        'sm': '640px',
        'md': '768px',
        'lg': '1024px',
        'xl': '1280px',
      },
      
      // 和风数字卡片集主题颜色 - 严格按照美学设计方案和无障碍设计原则
      colors: {
        // 和风主题核心色彩
        wafuu: {
          'deep-blue': '#002B6D',      // 静谧深蓝 - 主背景色
          'pure-white': '#FFFFFF',     // 纯白 - 主功能区背景
          'light-gray': '#EFEFEF',     // 浅灰 - 辅助色/纹样色
          'ink-black': '#333333',      // 墨黑 - 主文本色
        },
        
        // 无障碍设计扩展色彩
        accessible: {
          'text-on-dark': '#FFFFFF',   // 深蓝背景上的文本
          'text-on-light': '#1A1A1A',  // 白色背景上的文本（确保4.5:1对比度）
          'text-secondary': '#4A4A4A', // 次要文本色
          'hover': '#F5F5F5',          // 悬停状态
          'active': '#E8E8E8',         // 激活状态
          'disabled': '#CCCCCC',       // 禁用状态
          'border': '#D0D0D0',         // 主要边框
          'border-light': '#E8E8E8',   // 浅色边框
          'divider': '#F0F0F0',        // 分割线
        },
        
        // 游戏专用颜色 - 保持高对比度
        game: {
          'card-background': '#FFFFFF',
          'card-border': '#D0D0D0',
          'card-selected': '#E8F4FD',  // 选中状态 - 浅蓝背景
          'card-hover': '#F8F9FA',     // 悬停状态
          'ai-marker': '#E67E22',      // 深橙色，确保可读性
          'ai-background': '#FDF2E9',  // 浅橙色背景
          'ai-border': '#D35400',      // 深橙色边框
          'success': '#27AE60',        // 深绿色
          'error': '#E74C3C',          // 深红色
          'warning': '#F39C12',        // 深橙色
          'info': '#3498DB',           // 深蓝色
        },
        
        // 语义化颜色系统
        semantic: {
          'primary': '#FFFFFF',        // 主要按钮背景
          'primary-text': '#1A1A1A',   // 主要按钮文字
          'primary-hover': '#F5F5F5',  // 主要按钮悬停
          'secondary': '#F5F5F5',      // 次要按钮背景
          'secondary-text': '#1A1A1A', // 次要按钮文字
          'secondary-hover': '#E8E8E8', // 次要按钮悬停
          'danger': '#E74C3C',         // 危险按钮背景
          'danger-text': '#FFFFFF',    // 危险按钮文字
          'danger-hover': '#C0392B',   // 危险按钮悬停
        }
      },
      
      // 和风字体系统
      fontFamily: {
        'title': ['SmileySans', 'PingFang SC', 'Microsoft YaHei', 'sans-serif'],
        'card-id': ['AlibabaSans', 'Monaco', 'Consolas', 'monospace'],
        'body': ['SourceHanSerif', 'Source Han Serif CN', 'Noto Serif CJK SC', 'serif'],
        'sans': ['Inter', 'system-ui', 'sans-serif'],
      },
      
      // 卡片相关尺寸 (15:10 横版)
      spacing: {
        'card-w': '150px',
        'card-h': '100px',
        'card-w-lg': '225px',
        'card-h-lg': '150px',
      },
      
      // 动画效果
      animation: {
        'seigaiha': 'seigaiha 3s ease-in-out infinite',
      },
      
      keyframes: {
        seigaiha: {
          '0%, 100%': { opacity: '0.1' },
          '50%': { opacity: '0.2' }
        }
      }
    },
  },
  plugins: [],
}