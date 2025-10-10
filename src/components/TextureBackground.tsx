import React from 'react'

interface TextureBackgroundProps {
  children: React.ReactNode
  className?: string
}

export const TextureBackground: React.FC<TextureBackgroundProps> = ({
  children,
  className = ''
}) => {
  return (
    <div className={`relative ${className}`}>
      {/* 内容 */}
      <div className="relative z-10">
        {children}
      </div>
    </div>
  )
}