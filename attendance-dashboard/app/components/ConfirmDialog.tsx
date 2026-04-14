'use client';

import { motion, AnimatePresence } from 'framer-motion';

interface ConfirmDialogProps {
  title: string;
  message: string;
  confirmText?: string;
  cancelText?: string;
  onConfirm: () => void;
  onCancel: () => void;
  type?: 'danger' | 'warning' | 'info';
}

export default function ConfirmDialog({
  title,
  message,
  confirmText = 'Confirm',
  cancelText = 'Cancel',
  onConfirm,
  onCancel,
  type = 'warning'
}: ConfirmDialogProps) {
  const colors = {
    danger: {
      gradient: 'from-red-600 to-red-700',
      hover: 'hover:from-red-700 hover:to-red-800',
      glow: 'rgba(220, 38, 38, 0.4)'
    },
    warning: {
      gradient: 'from-yellow-600 to-orange-600',
      hover: 'hover:from-yellow-700 hover:to-orange-700',
      glow: 'rgba(234, 179, 8, 0.4)'
    },
    info: {
      gradient: 'from-blue-600 to-purple-600',
      hover: 'hover:from-blue-700 hover:to-purple-700',
      glow: 'rgba(59, 130, 246, 0.4)'
    }
  };

  const icons = {
    danger: '🚫',
    warning: '⚠️',
    info: 'ℹ️'
  };

  const colorScheme = colors[type];

  return (
    <AnimatePresence>
      {/* Premium Backdrop with blur */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        transition={{ duration: 0.2 }}
        className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50"
        onClick={onCancel}
      >
        {/* Dialog with spring animation */}
        <motion.div
          initial={{ scale: 0.9, opacity: 0, y: 20 }}
          animate={{ scale: 1, opacity: 1, y: 0 }}
          exit={{ scale: 0.95, opacity: 0, y: 10 }}
          transition={{ 
            type: "spring", 
            damping: 25, 
            stiffness: 300,
            mass: 0.8
          }}
          className="bg-white rounded-2xl shadow-2xl max-w-md w-full mx-4 overflow-hidden"
          onClick={(e) => e.stopPropagation()}
        >
          {/* Content with stagger */}
          <motion.div
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
            className="p-6"
          >
            <div className="flex items-start gap-4">
              <motion.span
                initial={{ scale: 0, rotate: -180 }}
                animate={{ scale: 1, rotate: 0 }}
                transition={{ 
                  type: "spring", 
                  damping: 15, 
                  stiffness: 200,
                  delay: 0.15
                }}
                className="text-5xl"
              >
                {icons[type]}
              </motion.span>
              <div className="flex-1">
                <motion.h3
                  initial={{ opacity: 0, x: -10 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: 0.2 }}
                  className="text-xl font-bold text-gray-900 mb-2"
                >
                  {title}
                </motion.h3>
                <motion.p
                  initial={{ opacity: 0, x: -10 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: 0.25 }}
                  className="text-gray-600 whitespace-pre-line leading-relaxed"
                >
                  {message}
                </motion.p>
              </div>
            </div>
          </motion.div>

          {/* Premium Action Buttons */}
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.3 }}
            className="bg-gray-50 px-6 py-4 flex gap-3 justify-end"
          >
            <motion.button
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
              onClick={onCancel}
              className="px-6 py-2.5 bg-white border-2 border-gray-300 text-gray-700 rounded-xl font-medium hover:bg-gray-50 hover:border-gray-400 transition-all shadow-sm"
            >
              {cancelText}
            </motion.button>
            <motion.button
              whileHover={{ 
                scale: 1.05,
                boxShadow: `0 10px 30px ${colorScheme.glow}`
              }}
              whileTap={{ scale: 0.95 }}
              onClick={onConfirm}
              className={`px-6 py-2.5 bg-gradient-to-r ${colorScheme.gradient} ${colorScheme.hover} text-white rounded-xl font-medium transition-all shadow-lg`}
            >
              {confirmText}
            </motion.button>
          </motion.div>
        </motion.div>
      </motion.div>
    </AnimatePresence>
  );
}
