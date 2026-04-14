'use client';

import { InputHTMLAttributes } from 'react';

interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
  helperText?: string;
}

export default function Input({
  label,
  error,
  helperText,
  className = '',
  ...props
}: InputProps) {
  return (
    <div className="space-y-1">
      {label && (
        <label className="block text-small font-medium text-gray-700">
          {label}
        </label>
      )}
      
      <input
        className={`
          w-full
          px-4 py-3
          border border-gray-300
          rounded-lg
          text-body
          focus:ring-2 focus:ring-primary-500 focus:border-transparent
          transition-all
          duration-200
          disabled:bg-gray-100 disabled:cursor-not-allowed
          ${error ? 'border-error-500 focus:ring-error-500' : ''}
          ${className}
        `}
        {...props}
      />
      
      {error && (
        <p className="text-caption text-error-600">{error}</p>
      )}
      
      {helperText && !error && (
        <p className="text-caption text-gray-500">{helperText}</p>
      )}
    </div>
  );
}
