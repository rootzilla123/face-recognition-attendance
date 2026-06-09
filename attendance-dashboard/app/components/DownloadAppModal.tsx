'use client';
import { motion, AnimatePresence } from 'framer-motion';
import { useState, useEffect } from 'react';

export default function DownloadAppModal() {
  const [isOpen, setIsOpen] = useState(false);

  useEffect(() => {
    // Show modal if user hasn't seen it in this session
    const hasSeen = localStorage.getItem('hasSeenAppDownload');
    if (!hasSeen) {
      const timer = setTimeout(() => {
        setIsOpen(true);
      }, 2000); // Delay for better UX
      return () => clearTimeout(timer);
    }
  }, []);

  const closePortal = () => {
    setIsOpen(false);
    localStorage.setItem('hasSeenAppDownload', 'true');
  };

  return (
    <AnimatePresence>
      {isOpen && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center p-4">
          <motion.div 
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={closePortal}
            className="absolute inset-0 bg-[#030712]/80 backdrop-blur-md"
          />
          
          <motion.div 
            initial={{ opacity: 0, scale: 0.9, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.9, y: 20 }}
            className="relative w-full max-w-md glass-panel rounded-[2.5rem] p-8 md:p-10 border-blue-500/20 shadow-[0_0_50px_rgba(59,130,246,0.2)]"
          >
            {/* Decoration */}
            <div className="absolute -top-12 left-1/2 -translate-x-1/2 w-24 h-24 bg-gradient-to-br from-blue-500 to-purple-600 rounded-3xl flex items-center justify-center text-5xl shadow-glow-blue animate-float">
              🤖
            </div>

            <div className="text-center mt-8">
              <h2 className="text-2xl font-extrabold tracking-tight text-white mb-3">Install AttendanceAI</h2>
              <p className="text-gray-400 text-sm leading-relaxed mb-8">
                Get the best experience with our Android application. 
                Receive instant push notifications and manage attendance on the go.
              </p>

              <div className="space-y-4">
                <a 
                  href="/AttendanceAI.apk" 
                  download
                  onClick={closePortal}
                  className="block w-full py-4 rounded-2xl bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-500 hover:to-purple-500 transition-all font-bold text-white shadow-glow-blue shimmer-btn text-center"
                >
                  Download APK Now
                </a>
                <button 
                  onClick={closePortal}
                  className="block w-full py-4 rounded-2xl bg-white/5 hover:bg-white/10 border border-white/10 text-gray-400 hover:text-white transition-all font-bold text-sm"
                >
                  Maybe Later
                </button>
              </div>

              <p className="mt-8 text-[10px] text-gray-600 uppercase tracking-widest font-mono">
                Verified Secure • V1.0.2 Stable
              </p>
            </div>

            {/* Close icon */}
            <button 
              onClick={closePortal}
              className="absolute top-6 right-6 text-gray-500 hover:text-white transition-colors"
            >
              <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
            </button>
          </motion.div>
        </div>
      )}
    </AnimatePresence>
  );
}
