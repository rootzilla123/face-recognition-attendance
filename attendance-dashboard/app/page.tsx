'use client';
import Link from 'next/link';
import { useAuth } from './context/AuthContext';
import { useEffect } from 'react';
import { useRouter } from 'next/navigation';

export default function LandingPage() {
  const { user, loading } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (!loading && user) router.replace('/dashboard');
  }, [user, loading, router]);

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-950 via-gray-900 to-blue-950 text-white">
      {/* Nav */}
      <nav className="flex items-center justify-between px-8 py-5 border-b border-white/10">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-gradient-to-br from-blue-500 to-purple-600 rounded-xl flex items-center justify-center">
            <span className="text-xl">📸</span>
          </div>
          <span className="text-xl font-bold">AttendanceAI</span>
        </div>
        <div className="flex gap-3">
          <Link href="/login" className="px-5 py-2 rounded-xl border border-white/20 hover:bg-white/10 transition text-sm font-medium">
            Sign In
          </Link>
          <Link href="/register" className="px-5 py-2 rounded-xl bg-gradient-to-r from-blue-600 to-purple-600 hover:opacity-90 transition text-sm font-medium">
            Get Started
          </Link>
        </div>
      </nav>

      {/* Hero */}
      <section className="max-w-5xl mx-auto px-8 pt-24 pb-16 text-center">
        <div className="inline-flex items-center gap-2 bg-blue-500/10 border border-blue-500/30 rounded-full px-4 py-1.5 text-sm text-blue-300 mb-8">
          <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse" />
          AI-Powered Face Recognition
        </div>
        <h1 className="text-5xl md:text-6xl font-bold leading-tight mb-6">
          Smart Attendance<br />
          <span className="bg-gradient-to-r from-blue-400 to-purple-400 bg-clip-text text-transparent">
            for Modern Schools
          </span>
        </h1>
        <p className="text-lg text-gray-400 max-w-2xl mx-auto mb-10">
          Automated face recognition attendance tracking with real-time notifications for parents, 
          powerful dashboards for teachers, and complete oversight for administrators.
        </p>
        <div className="flex flex-col sm:flex-row gap-4 justify-center">
          <Link href="/register" className="px-8 py-3.5 rounded-xl bg-gradient-to-r from-blue-600 to-purple-600 hover:opacity-90 transition font-semibold text-lg">
            Create Account
          </Link>
          <Link href="/login" className="px-8 py-3.5 rounded-xl border border-white/20 hover:bg-white/10 transition font-semibold text-lg">
            Sign In
          </Link>
        </div>
      </section>

      {/* Role cards */}
      <section className="max-w-5xl mx-auto px-8 pb-24">
        <p className="text-center text-gray-400 mb-10 text-sm uppercase tracking-widest">Built for everyone in your school</p>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          {[
            { role: 'Admin', icon: '🛡️', color: 'from-purple-500 to-pink-600', desc: 'Full system control, user management, camera oversight' },
            { role: 'Teacher', icon: '👩‍🏫', color: 'from-blue-500 to-cyan-600', desc: 'Post announcements, view attendance, manage students' },
            { role: 'Student', icon: '🎓', color: 'from-green-500 to-teal-600', desc: 'View your own attendance history and school announcements' },
            { role: 'Parent', icon: '👨‍👧', color: 'from-orange-500 to-amber-600', desc: 'Get notified when your child arrives, track attendance' },
          ].map(({ role, icon, color, desc }) => (
            <div key={role} className="bg-white/5 border border-white/10 rounded-2xl p-6 hover:bg-white/10 transition">
              <div className={`w-12 h-12 bg-gradient-to-br ${color} rounded-xl flex items-center justify-center text-2xl mb-4`}>
                {icon}
              </div>
              <h3 className="font-bold text-lg mb-2">{role}</h3>
              <p className="text-sm text-gray-400">{desc}</p>
            </div>
          ))}
        </div>
      </section>
    </div>
  );
}
