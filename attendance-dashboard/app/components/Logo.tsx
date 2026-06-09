'use client';

import { motion } from 'framer-motion';

interface LogoProps {
  className?: string;
  showText?: boolean;
  size?: 'sm' | 'md' | 'lg' | 'xl';
}

export default function Logo({ className = "", showText = true, size = 'md' }: LogoProps) {
  const sizes = {
    sm: { icon: 24, font: 'text-lg', slogan: 'text-[6px]' },
    md: { icon: 40, font: 'text-2xl', slogan: 'text-[8px]' },
    lg: { icon: 64, font: 'text-4xl', slogan: 'text-[12px]' },
    xl: { icon: 120, font: 'text-7xl', slogan: 'text-base' },
  };

  const { icon: iconSize, font: fontSize, slogan: sloganSize } = sizes[size];

  return (
    <div className={`flex items-center gap-3 ${className}`}>
      <div 
        style={{ width: iconSize, height: iconSize }}
        className="relative flex-shrink-0"
      >
        <svg viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg" className="w-full h-full">
          {/* Connecting Lines */}
          <line x1="50" y1="45" x2="25" y2="25" stroke="currentColor" strokeWidth="1.5" />
          <line x1="50" y1="45" x2="80" y2="20" stroke="currentColor" strokeWidth="1.5" />
          <line x1="50" y1="45" x2="85" y2="60" stroke="currentColor" strokeWidth="1.5" />
          <line x1="50" y1="45" x2="40" y2="85" stroke="currentColor" strokeWidth="1.5" />
          <line x1="50" y1="45" x2="15" y2="75" stroke="currentColor" strokeWidth="1.5" />

          {/* Central Hub */}
          <circle cx="50" cy="45" r="10" fill="currentColor" />

          {/* Nodes */}
          <circle cx="25" cy="25" r="5" fill="currentColor" />   {/* NW */}
          <circle cx="80" cy="20" r="8" fill="currentColor" />   {/* NE */}
          <circle cx="85" cy="60" r="6" fill="currentColor" />   {/* ESE */}
          <circle cx="40" cy="85" r="6" fill="currentColor" />   {/* S */}
          <circle cx="15" cy="75" r="9" fill="currentColor" />   {/* SW */}
        </svg>
      </div>
      
      {showText && (
        <div className="flex flex-col leading-none border-b border-white/40 pb-1">
          <span className={`${fontSize} font-black tracking-tighter text-white`}>
            ShadomFacePro
          </span>
          <span className={`${sloganSize} tracking-[0.2em] font-bold text-blue-400 uppercase mt-1`}>
            Smart Attendance Redefined
          </span>
        </div>
      )}
    </div>
  );
}
