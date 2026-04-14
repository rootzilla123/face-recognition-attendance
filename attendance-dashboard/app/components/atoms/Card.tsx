'use client';

import { ReactNode } from 'react';
import { motion } from 'framer-motion';

interface CardProps {
  children: ReactNode;
  variant?: 'default' | 'elevated' | 'outlined';
  padding?: 'sm' | 'md' | 'lg';
  className?: string;
  hover?: boolean;
}

export default function Card({
  children,
  variant = 'default',
  padding = 'md',
  className = '',
  hover = false
}: CardProps) {
  // Padding variants (8px spacing system)
  const paddings = {
    sm: 'p-4',   // 32px
    md: 'p-6',   // 48px
    lg: 'p-8',   // 64px
  };

  // Style variants (design tokens)
  const variants = {
    default: 'bg-white shadow-md',
    elevated: 'bg-white shadow-lg',
    outlined: 'bg-white border-2 border-gray-200',
  };

  const Component = hover ? motion.div : 'div';
  const hoverProps = hover ? {
    whileHover: { scale: 1.02, y: -4 },
    transition: { type: 'spring', stiffness: 300, damping: 20 }
  } : {};

  return (
    <Component
      className={`
        ${variants[variant]}
        ${paddings[padding]}
        rounded-2xl
        transition-all
        duration-200
        ${className}
      `}
      {...hoverProps}
    >
      {children}
    </Component>
  );
}
