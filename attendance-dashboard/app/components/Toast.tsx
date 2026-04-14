'use client';

import { useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';

interface ToastProps {
  message: string;
  type: 'success' | 'error' | 'info' | 'warning';
  onClose: () => void;
  duration?: number;
}

export default function Toast({ message, type, onClose, duration = 3000 }: ToastProps) {
  useEffect(() => {
    const timer = setTimeout(() => {
      onClose();
    }, duration);

    return () => clearTimeout(timer);
  }, [duration, onClose]);

  const icons = {
    success: '✅',
    error: '❌',
    info: 'ℹ️',
    warning: '⚠️'
  };

  const colors = {
    success: {
      gradient: 'from-green-500 to-emerald-600',
      glow: 'rgba(34, 197, 94, 0.3)'
    },
    error: {
      gradient: 'from-red-500 to-rose-600',
      glow: 'rgba(239, 68, 68, 0.3)'
    },
    info: {
      gradient: 'from-blue-500 to-cyan-600',
      glow: 'rgba(59, 130, 246, 0.3)'
    },
    warning: {
      gradient: 'from-yellow-500 to-orange-600',
      glow: 'rgba(234, 179, 8, 0.3)'
    }
  };

  const colorScheme = colors[type];

  return (
    <AnimatePresence>
      <div className="fixed top-4 right-4 z-50">
        <motion.div
          initial={{ x: 400, opacity: 0, scale: 0.8 }}
          animate={{ x: 0, opacity: 1, scale: 1 }}
          exit={{ x: 400, opacity: 0, scale: 0.8 }}
          transition={{ 
            type: "spring", 
            damping: 20, 
            stiffness: 300 
          }}
          className={`bg-gradient-to-r ${colorScheme.gradient} text-white px-6 py-4 rounded-2xl shadow-2xl flex items-center gap-3 min-w-[300px] max-w-[500px] backdrop-blur-sm`}
          style={{
            boxShadow: `0 10px 40px ${colorScheme.glow}, 0 0 0 1px rgba(255,255,255,0.1)`
          }}
        >
          <motion.span
            initial={{ scale: 0, rotate: -180 }}
            animate={{ scale: 1, rotate: 0 }}
            transition={{ 
              type: "spring", 
              damping: 15, 
              stiffness: 200,
              delay: 0.1
            }}
            className="text-2xl"
          >
            {icons[type]}
          </motion.span>
          
          <motion.p
            initial={{ opacity: 0, x: -10 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.15 }}
            className="flex-1 font-medium"
          >
            {message}
          </motion.p>
          
          <motion.button
            whileHover={{ scale: 1.2, rotate: 90 }}
            whileTap={{ scale: 0.9 }}
            onClick={onClose}
            className="w-8 h-8 rounded-full bg-white/20 hover:bg-white/30 flex items-center justify-center text-white font-bold transition-colors"
          >
            ×
          </motion.button>
        </motion.div>

        {/* Progress bar */}
        <motion.div
          initial={{ scaleX: 1 }}
          animate={{ scaleX: 0 }}
          transition={{ duration: duration / 1000, ease: "linear" }}
          className="h-1 bg-white/30 rounded-full mt-1"
          style={{ transformOrigin: "left" }}
        />
      </div>
    </AnimatePresence>
  );
}
