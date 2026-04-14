'use client';

import { ReactNode } from 'react';

interface BadgeProps {
  children: ReactNode;
  variant?: 'primary' | 'secondary' | 'success' | 'error' | 'warning' | 'info';
  size?: 'sm' | 'md';
  className?: string;
}

export default function Badge({
  children,
  variant = 'primary',
  size = 'md',
  className = ''
}: BadgeProps) {
  // Size variants (8px spacing system)
  const sizes = {
    sm: 'px-2 py-1 text-caption',    // 16px × 8px
    md: 'px-3 py-1 text-small',      // 24px × 8px
  };

  // Color variants (design tokens)
  const variants = {
    primary: 'bg-primary-100 text-primary-800',
    secondary: 'bg-secondary-100 text-secondary-800',
    success: 'bg-success-100 text-success-700',
    error: 'bg-error-100 text-error-700',
    warning: 'bg-warning-100 text-warning-700',
    info: 'bg-info-100 text-info-700',
  };

  return (
    <span
      className={`
        inline-flex
        items-center
        ${sizes[size]}
        ${variants[variant]}
        rounded-full
        font-medium
        ${className}
      `}
    >
      {children}
    </span>
  );
}
