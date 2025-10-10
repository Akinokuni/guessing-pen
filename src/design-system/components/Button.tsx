import React from 'react'

// Button 组件属性接口
interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'outline' | 'ghost'
  size?: 'sm' | 'md' | 'lg'
  loading?: boolean
  children: React.ReactNode
}

// 样式变体映射 - 和风主题 + 无障碍设计
const variantStyles = {
  primary: 'bg-semantic-primary hover:bg-semantic-primary-hover text-semantic-primary-text border-transparent shadow-md',
  secondary: 'bg-semantic-secondary hover:bg-semantic-secondary-hover text-semantic-secondary-text border-accessible-border',
  outline: 'bg-transparent hover:bg-accessible-hover text-accessible-text-on-light hover:text-accessible-text-on-light border-accessible-border disabled:border-accessible-disabled disabled:text-accessible-disabled',
  ghost: 'bg-transparent hover:bg-accessible-hover text-accessible-text-on-light border-transparent disabled:text-accessible-disabled',
}

const sizeStyles = {
  sm: 'px-3 py-1.5 text-sm',
  md: 'px-4 py-2 text-base',
  lg: 'px-6 py-3 text-lg',
}

export const Button: React.FC<ButtonProps> = ({
  variant = 'primary',
  size = 'md',
  loading = false,
  disabled,
  children,
  className = '',
  ...props
}) => {
  const baseStyles = 'inline-flex items-center justify-center font-body font-medium rounded-lg border transition-all duration-150 focus:outline-none focus:ring-2 focus:ring-wafuu-pure-white focus:ring-offset-2 focus:ring-offset-wafuu-deep-blue disabled:opacity-50 disabled:cursor-not-allowed touch-manipulation select-none active:scale-95'
  
  const combinedClassName = [
    baseStyles,
    variantStyles[variant],
    sizeStyles[size],
    className,
  ].join(' ')

  return (
    <button
      className={combinedClassName}
      disabled={disabled || loading}
      {...props}
    >
      {loading && (
        <svg
          className="animate-spin -ml-1 mr-2 h-4 w-4"
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
        >
          <circle
            className="opacity-25"
            cx="12"
            cy="12"
            r="10"
            stroke="currentColor"
            strokeWidth="4"
          />
          <path
            className="opacity-75"
            fill="currentColor"
            d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
          />
        </svg>
      )}
      {children}
    </button>
  )
}