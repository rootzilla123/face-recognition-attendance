import type { Config } from "tailwindcss";

const config: Config = {
  darkMode: 'media',
  content: [
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      // COLOR SYSTEM - Monochromatic + Complementary
      colors: {
        // Primary: Blue (Main brand color)
        primary: {
          50: '#eff6ff',
          100: '#dbeafe',
          200: '#bfdbfe',
          300: '#93c5fd',
          400: '#60a5fa',
          500: '#3b82f6',  // Base
          600: '#2563eb',
          700: '#1d4ed8',
          800: '#1e40af',
          900: '#1e3a8a',
        },
        // Secondary: Purple (Complementary)
        secondary: {
          50: '#faf5ff',
          100: '#f3e8ff',
          200: '#e9d5ff',
          300: '#d8b4fe',
          400: '#c084fc',
          500: '#a855f7',  // Base
          600: '#9333ea',
          700: '#7e22ce',
          800: '#6b21a8',
          900: '#581c87',
        },
        // Cyan (for premium gradients)
        cyan: {
          50: '#ecfeff',
          100: '#cffafe',
          200: '#a5f3fc',
          300: '#67e8f9',
          400: '#22d3ee',
          500: '#06b6d4',
          600: '#0891b2',
          700: '#0e7490',
          800: '#155e75',
          900: '#164e63',
        },
        // Indigo (for gradient transitions)
        indigo: {
          50: '#eef2ff',
          100: '#e0e7ff',
          200: '#c7d2fe',
          300: '#a5b4fc',
          400: '#818cf8',
          500: '#6366f1',
          600: '#4f46e5',
          700: '#4338ca',
          800: '#3730a3',
          900: '#312e81',
        },
        // Semantic Colors
        success: {
          50: '#f0fdf4',
          100: '#dcfce7',
          500: '#22c55e',
          600: '#16a34a',
          700: '#15803d',
        },
        error: {
          50: '#fef2f2',
          100: '#fee2e2',
          500: '#ef4444',
          600: '#dc2626',
          700: '#b91c1c',
        },
        warning: {
          50: '#fffbeb',
          100: '#fef3c7',
          500: '#eab308',
          600: '#ca8a04',
          700: '#a16207',
        },
        info: {
          50: '#eff6ff',
          100: '#dbeafe',
          500: '#3b82f6',
          600: '#2563eb',
          700: '#1d4ed8',
        },
      },

      // TYPOGRAPHY SCALE - Compact for dashboard use
      fontSize: {
        'display': ['1.75rem', { lineHeight: '1.2', letterSpacing: '-0.02em', fontWeight: '700' }],    // 28px
        'h1': ['1.5rem', { lineHeight: '1.3', letterSpacing: '-0.01em', fontWeight: '700' }],         // 24px
        'h2': ['1.25rem', { lineHeight: '1.4', letterSpacing: '-0.01em', fontWeight: '600' }],        // 20px
        'h3': ['1.125rem', { lineHeight: '1.5', fontWeight: '600' }],                                 // 18px
        'body': ['0.875rem', { lineHeight: '1.6', fontWeight: '400' }],                               // 14px
        'small': ['0.8125rem', { lineHeight: '1.5', fontWeight: '400' }],                             // 13px
        'caption': ['0.75rem', { lineHeight: '1.4', fontWeight: '500' }],                             // 12px
      },

      // SPACING SYSTEM - 8px base unit
      spacing: {
        '0': '0px',
        '1': '8px',      // 8 * 1
        '2': '16px',     // 8 * 2
        '3': '24px',     // 8 * 3
        '4': '32px',     // 8 * 4
        '5': '40px',     // 8 * 5
        '6': '48px',     // 8 * 6
        '7': '56px',     // 8 * 7
        '8': '64px',     // 8 * 8
        '10': '80px',    // 8 * 10
        '12': '96px',    // 8 * 12
        '16': '128px',   // 8 * 16
        '20': '160px',   // 8 * 20
        '24': '192px',   // 8 * 24
      },

      // MAX-WIDTH - Content constraints
      maxWidth: {
        'xs': '320px',
        'sm': '384px',
        'md': '448px',
        'lg': '512px',
        'xl': '576px',
        '2xl': '672px',
        '3xl': '768px',
        '4xl': '896px',
        '5xl': '1024px',
        '6xl': '1152px',
        '7xl': '1280px',   // Main content max-width
        'full': '100%',
      },

      // BORDER RADIUS - Consistent curves
      borderRadius: {
        'none': '0',
        'sm': '8px',
        'md': '12px',
        'lg': '16px',
        'xl': '20px',
        '2xl': '24px',
        '3xl': '32px',
        'full': '9999px',
      },

      // SHADOWS - Depth system with brand-colored glows
      boxShadow: {
        'sm': '0 1px 2px 0 rgba(0, 0, 0, 0.05)',
        'DEFAULT': '0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06)',
        'md': '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)',
        'lg': '0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)',
        'xl': '0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)',
        '2xl': '0 25px 50px -12px rgba(0, 0, 0, 0.25)',
        'inner': 'inset 0 2px 4px 0 rgba(0, 0, 0, 0.06)',
        'none': 'none',
        // Premium brand-colored glows
        'glow-blue': '0 8px 16px -4px rgba(59, 130, 246, 0.3), 0 4px 8px -2px rgba(0, 0, 0, 0.1)',
        'glow-purple': '0 8px 16px -4px rgba(168, 85, 247, 0.3), 0 4px 8px -2px rgba(0, 0, 0, 0.1)',
        'glow-green': '0 8px 16px -4px rgba(34, 197, 94, 0.3), 0 4px 8px -2px rgba(0, 0, 0, 0.1)',
        'glow-orange': '0 8px 16px -4px rgba(234, 179, 8, 0.3), 0 4px 8px -2px rgba(0, 0, 0, 0.1)',
        'glow-red': '0 8px 16px -4px rgba(239, 68, 68, 0.3), 0 4px 8px -2px rgba(0, 0, 0, 0.1)',
      },

      // ANIMATION - Smooth transitions
      transitionDuration: {
        '150': '150ms',
        '200': '200ms',
        '300': '300ms',
        '500': '500ms',
      },

      // Z-INDEX - Layering system
      zIndex: {
        '0': '0',
        '10': '10',
        '20': '20',
        '30': '30',
        '40': '40',
        '50': '50',
        'modal': '100',
        'toast': '200',
      },

      // PREMIUM GRADIENTS - 135° direction, 3-color mesh
      backgroundImage: {
        'gradient-premium-blue': 'linear-gradient(135deg, #1d4ed8 0%, #3b82f6 50%, #06b6d4 100%)',
        'gradient-premium-purple': 'linear-gradient(135deg, #7e22ce 0%, #a855f7 50%, #ec4899 100%)',
        'gradient-premium-green': 'linear-gradient(135deg, #15803d 0%, #22c55e 50%, #10b981 100%)',
        'gradient-premium-orange': 'linear-gradient(135deg, #c2410c 0%, #f97316 50%, #fb923c 100%)',
        'gradient-premium-indigo': 'linear-gradient(135deg, #4338ca 0%, #6366f1 50%, #818cf8 100%)',
      },
    },
  },
  plugins: [],
};
export default config;
