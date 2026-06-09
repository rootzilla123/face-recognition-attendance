'use client';

import Link from 'next/link';
import { useAuth } from './context/AuthContext';
import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import dynamic from 'next/dynamic';
import { motion, AnimatePresence } from 'framer-motion';

const VideoHero = dynamic(() => import('./components/VideoHero'), { ssr: false });

import Logo from './components/Logo';

export default function LandingPage() {
  const { user, loading } = useAuth();
  const router = useRouter();
  
  const [mousePos, setMousePos] = useState({ x: 0, y: 0 });

  useEffect(() => {
    if (!loading && user) router.replace('/dashboard');
  }, [user, loading, router]);

  const handleMouseMove = (e: React.MouseEvent<HTMLDivElement>) => {
    const x = (e.clientX / (typeof window !== 'undefined' ? window.innerWidth : 1)) * 2 - 1;
    const y = (e.clientY / (typeof window !== 'undefined' ? window.innerHeight : 1)) * 2 - 1;
    setMousePos({ x: x * 20, y: y * 20 });
  };

  return (
    <div 
      className="min-h-screen bg-[#030712] text-white selection:bg-blue-500/30 overflow-hidden relative"
      onMouseMove={handleMouseMove}
    >
      {/* Dynamic Background Elements */}
      <div className="fixed inset-0 bg-grid opacity-20 pointer-events-none" />
      <div 
        className="fixed top-[-10%] left-[-10%] w-[70%] h-[70%] rounded-full bg-blue-600/[0.07] blur-[150px] pointer-events-none" 
        style={{ transform: `translate(${mousePos.x}px, ${mousePos.y}px)` }}
      />
      <div 
        className="fixed bottom-[-10%] right-[-10%] w-[70%] h-[70%] rounded-full bg-purple-600/[0.07] blur-[150px] pointer-events-none"
        style={{ transform: `translate(${-mousePos.x}px, ${-mousePos.y}px)` }}
      />
      
      {/* Nav */}
      <nav className="relative z-50 flex items-center justify-between px-6 lg:px-12 py-8">
        <motion.div 
          initial={{ opacity: 0, x: -20 }}
          animate={{ opacity: 1, x: 0 }}
        >
          <Link href="/">
            <Logo size="md" />
          </Link>
        </motion.div>
        
        <motion.div 
          initial={{ opacity: 0, x: 20 }}
          animate={{ opacity: 1, x: 0 }}
          className="flex items-center gap-8"
        >
          <Link href="/AttendanceAI.apk" download className="hidden sm:flex items-center gap-1.5 px-4 py-2 rounded-full glass-card text-xs font-bold text-blue-400 border-blue-500/20 hover:bg-blue-500/10 transition-all shadow-glow-blue group">
            <span className="text-sm">🤖</span> Download App
          </Link>
          <Link href="/pricing" className="hidden sm:block text-sm font-medium text-gray-400 hover:text-white transition-colors">
            Pricing
          </Link>
          <Link href="/login" className="hidden sm:block text-sm font-medium text-gray-400 hover:text-white transition-colors">
            Sign In
          </Link>
          <Link href="/register" className="relative group px-7 py-3 rounded-full bg-white text-gray-950 hover:bg-gray-100 transition-all transform hover:scale-105 active:scale-95 text-sm font-bold shadow-[0_0_25px_rgba(255,255,255,0.4)] overflow-hidden">
            <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/50 to-transparent -translate-x-full group-hover:animate-[shimmer_1.5s_infinite] pointer-events-none" />
            Get Started
          </Link>
        </motion.div>
      </nav>

      {/* Hero Section */}
      <section className="relative z-10 max-w-[1600px] mx-auto px-6 pt-12 pb-32 lg:pt-20 flex flex-col lg:flex-row items-center gap-16 lg:gap-24">
        <motion.div 
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8 }}
          className="flex-[0.7] text-center lg:text-left relative z-20"
        >
          <div className="inline-flex items-center gap-2 glass-card rounded-full px-4 py-1.5 text-xs text-blue-300 mb-10 border border-blue-500/30 shadow-glow-blue font-medium tracking-wide">
            <div className="relative flex h-2 w-2">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-blue-400 opacity-75"></span>
              <span className="relative inline-flex rounded-full h-2 w-2 bg-blue-500"></span>
            </div>
            Next-Gen AI Face Recognition
          </div>
          
          <h1 className="text-5xl md:text-7xl xl:text-8xl font-black tracking-tighter leading-[1] mb-10 relative">
            The future of <br className="hidden md:block" />
            <span className="bg-gradient-to-r from-blue-400 via-purple-400 to-pink-400 bg-clip-text text-transparent pb-2">
              school attendance.
            </span>
          </h1>
          
          <p className="text-xl md:text-2xl text-gray-400 max-w-xl mx-auto lg:mx-0 mb-14 font-light leading-relaxed">
            Automated face recognition attendance tracking with real-time notifications, 
            powerful dashboards, and complete oversight for modern institutions.
          </p>
          
          <div className="flex flex-col sm:flex-row gap-5 justify-center lg:justify-start items-center">
            <Link href="/register" className="relative group px-10 py-5 rounded-2xl bg-gradient-to-r from-blue-600 to-indigo-600 text-white font-bold text-xl hover:scale-105 active:scale-95 transition-all shadow-[0_0_30px_rgba(59,130,246,0.3)] overflow-hidden">
              <div className="absolute inset-0 bg-white/10 opacity-0 group-hover:opacity-100 transition-opacity" />
              Start Free Trial
            </Link>
            
            <Link href="/AttendanceAI.apk" download className="px-10 py-5 rounded-2xl bg-white/5 border border-white/10 backdrop-blur-md font-bold text-lg hover:bg-white/10 transition-all flex items-center gap-3 group">
              <span className="text-2xl group-hover:scale-110 transition-transform">🤖</span>
              <span>Get Android App</span>
            </Link>
          </div>

          <div className="mt-8 flex justify-center lg:justify-start items-center gap-6 text-sm text-gray-500 font-medium">
            <span className="flex items-center gap-2">
              <span className="w-1.5 h-1.5 rounded-full bg-green-500"></span>
              No credit card required
            </span>
            <span className="flex items-center gap-2">
              <span className="w-1.5 h-1.5 rounded-full bg-blue-500"></span>
              Instant setup
            </span>
          </div>
        </motion.div>

        <motion.div 
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ duration: 1, delay: 0.2 }}
          className="flex-[1.3] relative w-full h-[500px] lg:h-[700px] hidden md:block"
        >
          <div className="absolute -inset-10 bg-blue-600/5 blur-[120px] opacity-40 animate-pulse-slow" />
          <VideoHero />
        </motion.div>
      </section>

      {/* Stats Section */}
      <motion.section 
        initial={{ opacity: 0, y: 40 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true }}
        className="relative z-10 max-w-7xl mx-auto px-6 pb-24"
      >
        <div className="glass-panel rounded-2xl p-1.5 md:p-3 rounded-b-none translate-y-10">
          <div className="bg-gray-900/50 backdrop-blur-3xl rounded-t-xl border border-white/5 p-8 grid grid-cols-1 md:grid-cols-3 gap-12">
            {[
              { icon: '⚡', val: '99.9%', label: 'Recognition Accuracy', color: 'text-blue-400' },
              { icon: '⏱️', val: '<0.5s', label: 'Processing Time', color: 'text-purple-400' },
              { icon: '🔔', val: 'Instant', label: 'Real-time alerts', color: 'text-pink-400' },
            ].map((s, i) => (
              <div key={i} className="text-center group">
                <p className="text-3xl mb-3 transform group-hover:scale-110 transition-transform">{s.icon}</p>
                <h4 className={`text-3xl font-bold text-white mb-1`}>{s.val}</h4>
                <p className="text-xs text-gray-400 font-mono tracking-widest uppercase">{s.label}</p>
              </div>
            ))}
          </div>
        </div>
      </motion.section>

      {/* Role cards */}
      <section className="relative z-10 bg-black/50 py-24 border-t border-white/5">
        <div className="max-w-7xl mx-auto px-6">
          <div className="text-center mb-16">
            <h2 className="text-3xl md:text-4xl font-bold mb-4">Built for everyone.</h2>
            <p className="text-lg text-gray-400">A unified platform that serves the entire school ecosystem.</p>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            {[
              { role: 'Admin', icon: '🛡️', color: 'from-purple-500 to-pink-600', shadow: 'shadow-glow-purple', desc: 'Full system control, comprehensive reporting, and camera fleet oversight.' },
              { role: 'Teacher', icon: '👩‍🏫', color: 'from-blue-500 to-cyan-400', shadow: 'shadow-glow-blue', desc: 'Post announcements, verify automated attendance, and manage classes instantly.' },
              { role: 'Student', icon: '🎓', color: 'from-green-500 to-emerald-400', shadow: 'shadow-glow-green', desc: 'View your attendance history, stay updated with school news securely.' },
              { role: 'Parent', icon: '👨‍👧', color: 'from-orange-500 to-amber-400', shadow: 'shadow-glow-orange', desc: 'Real-time SMS/Email notification when your child arrives safely on campus.' },
            ].map(({ role, icon, color, shadow, desc }, i) => (
              <motion.div 
                key={role}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.1 }}
                className="glass-card rounded-2xl p-7 group relative overflow-hidden"
              >
                <div className={`w-14 h-14 bg-gradient-to-br ${color} rounded-2xl flex items-center justify-center text-3xl mb-6 transform group-hover:scale-110 group-hover:rotate-3 transition-all duration-500 ${shadow}`}>
                  {icon}
                </div>
                <h3 className="text-xl font-bold text-white mb-3">{role}</h3>
                <p className="text-gray-400 leading-relaxed font-light text-sm">{desc}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Footer CTA */}
      <footer className="relative z-10 py-28 border-t border-white/5 bg-[#030712]">
        <div className="max-w-4xl mx-auto px-6 text-center relative z-10">
          <motion.div
            initial={{ opacity: 0, scale: 0.95 }}
            whileInView={{ opacity: 1, scale: 1 }}
            viewport={{ once: true }}
          >
            <h2 className="text-4xl font-bold mb-6">Ready to upgrade your campus?</h2>
            <p className="text-xl text-gray-400 mb-10">Join the schools already using AttendanceAI to secure their premises and automate reporting.</p>
            <Link href="/register" className="inline-block px-12 py-5 rounded-full bg-white text-gray-950 hover:bg-gray-100 transition-all transform hover:scale-105 active:scale-95 text-xl font-bold shadow-[0_0_40px_rgba(255,255,255,0.3)] shimmer-btn">
              Deploy AttendanceAI Today
            </Link>
          </motion.div>
          
          <div className="mt-24 pt-8 border-t border-white/5 text-gray-500 text-xs flex flex-col sm:flex-row justify-between items-center gap-6 font-mono tracking-widest uppercase">
            <div className="flex items-center gap-3">
              <Logo size="sm" />
            </div>
            <p>© {new Date().getFullYear()} All rights reserved.</p>
          </div>
        </div>
      </footer>
    </div>
  );
}
