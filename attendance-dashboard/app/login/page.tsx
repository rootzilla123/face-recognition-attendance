'use client';
import { useState, Suspense } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import Link from 'next/link';
import { useAuth } from '../context/AuthContext';
import { pb } from '@/lib/pocketbase';
import { motion } from 'framer-motion';
import Logo from '../components/Logo';

function LoginForm() {
  const { login, demoLogin } = useAuth();
  const router = useRouter();
  const params = useSearchParams();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [googleLoading, setGoogleLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(''); setLoading(true);
    try {
      await login(email, password);
      router.replace('/dashboard');
    } catch (err: any) {
      setError(err.message || 'Invalid email or password');
    } finally { setLoading(false); }
  };

  const handleDemoLogin = async (role: 'admin' | 'teacher' | 'student' | 'parent') => {
    setError('');
    setLoading(true);
    try {
      await demoLogin(role);
      const dashboardMap: Record<string, string> = {
        admin: '/admin',
        teacher: '/teacher',
        student: '/student',
        parent: '/children'
      };
      router.replace(dashboardMap[role] || '/dashboard');
    } catch (err: any) {
      setError(err.message || 'Demo login failed');
    } finally { setLoading(false); }
  };

  const handleGoogle = async () => {
    setError(''); setGoogleLoading(true);
    try {
      const authData = await pb.collection('users').authWithOAuth2({
        provider: 'google',
        createData: { role: 'student' },
      });
      if (!authData.record.role) {
        router.replace('/complete-profile');
      } else {
        router.replace('/dashboard');
      }
    } catch (err: any) {
      setError(err.message || 'Google sign-in failed');
    } finally { setGoogleLoading(false); }
  };

  const inputCls = "w-full bg-white/[0.03] border border-white/5 rounded-2xl px-5 py-3 text-white placeholder-gray-500 focus:outline-none focus:border-blue-500/40 focus:bg-white/[0.06] transition-all duration-300";

  return (
    <div className="min-h-screen bg-[#030712] flex items-center justify-center px-4 relative overflow-hidden">
      {/* Soft Background Elements */}
      <div className="fixed inset-0 bg-grid opacity-[0.1] pointer-events-none" />
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-blue-600/5 blur-[150px] pointer-events-none" />

      <motion.div 
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="w-full max-w-[420px] relative z-10"
      >
        <div className="text-center mb-10">
          <Link href="/" className="inline-flex items-center gap-3 mb-6 group">
            <Logo size="lg" />
          </Link>
          <h1 className="text-3xl font-extrabold tracking-tight text-white">Welcome back</h1>
          <p className="text-gray-400 mt-2 font-medium">Log in to your account</p>
        </div>

        <div className="glass-panel rounded-[2.5rem] p-8 md:p-10 relative overflow-hidden border-white/[0.08] shadow-2xl">
          {error && (
            <div className="bg-red-500/10 border border-red-500/20 text-red-400 rounded-2xl px-4 py-3 mb-6 text-sm text-center">
              {error}
            </div>
          )}
          {params.get('registered') && (
            <div className="bg-green-500/10 border border-green-500/20 text-green-400 rounded-2xl px-4 py-3 mb-6 text-sm text-center">
              Your account is ready! Please log in.
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-6">
            <div className="space-y-5">
              <div>
                <label className="text-sm font-semibold text-gray-300 mb-2 ml-1 block">Email Address</label>
                <input type="email" required value={email} onChange={e => setEmail(e.target.value)}
                  className={inputCls} placeholder="name@school.com" />
              </div>
              
              <div>
                <div className="flex items-center justify-between mb-2 px-1">
                  <label className="text-sm font-semibold text-gray-300 block">Password</label>
                  <Link href="/forgot-password" className="text-xs font-bold text-blue-400 hover:text-blue-300 transition-colors">Forgot?</Link>
                </div>
                <input type="password" required value={password} onChange={e => setPassword(e.target.value)}
                  className={inputCls} placeholder="••••••••" />
              </div>
            </div>

            <button type="submit" disabled={loading}
              className="w-full py-4 rounded-2xl bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-500 hover:to-purple-500 disabled:opacity-50 transition-all font-bold text-white shadow-glow-blue transform hover:scale-[1.02] active:scale-95 shimmer-btn">
              {loading ? 'Logging in...' : 'Sign In'}
            </button>
          </form>

          <div className="flex items-center gap-4 my-8">
            <div className="flex-1 h-px bg-white/10" />
            <span className="text-gray-500 text-xs font-bold uppercase tracking-widest">or</span>
            <div className="flex-1 h-px bg-white/10" />
          </div>

          <button onClick={handleGoogle} disabled={googleLoading}
            className="w-full flex items-center justify-center gap-3 py-3.5 rounded-2xl bg-white text-gray-950 hover:bg-gray-200 disabled:opacity-50 transition-all font-bold text-sm shadow-[0_0_20px_rgba(255,255,255,0.1)]">
            {googleLoading ? (
              <div className="w-5 h-5 border-2 border-gray-400 border-t-transparent rounded-full animate-spin" />
            ) : (
              <svg className="w-5 h-5" viewBox="0 0 24 24">
                <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
                <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
                <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
                <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
              </svg>
            )}
            Sign in with Google
          </button>

          {/* Development Bypass Buttons */}
          <div className="mt-8 pt-6 border-t border-white/10">
            <p className="text-xs text-gray-500 mb-3 text-center font-semibold uppercase">Quick Access (Dev)</p>
            <div className="grid grid-cols-2 gap-2">
              <button onClick={() => handleDemoLogin('admin')} disabled={loading}
                className="py-2 px-3 rounded-xl bg-blue-600/20 hover:bg-blue-600/30 border border-blue-500/30 text-xs font-bold text-blue-300 transition-all disabled:opacity-50">
                → Admin
              </button>
              <button onClick={() => handleDemoLogin('teacher')} disabled={loading}
                className="py-2 px-3 rounded-xl bg-purple-600/20 hover:bg-purple-600/30 border border-purple-500/30 text-xs font-bold text-purple-300 transition-all disabled:opacity-50">
                → Teacher
              </button>
              <button onClick={() => handleDemoLogin('student')} disabled={loading}
                className="py-2 px-3 rounded-xl bg-green-600/20 hover:bg-green-600/30 border border-green-500/30 text-xs font-bold text-green-300 transition-all disabled:opacity-50">
                → Student
              </button>
              <button onClick={() => handleDemoLogin('parent')} disabled={loading}
                className="py-2 px-3 rounded-xl bg-amber-600/20 hover:bg-amber-600/30 border border-amber-500/30 text-xs font-bold text-amber-300 transition-all disabled:opacity-50">
                → Parent
              </button>
            </div>
          </div>
        </div>
        
        <p className="text-center text-gray-500 text-sm mt-10">
          Don't have an account? <Link href="/register" className="text-blue-500 hover:text-blue-400 font-bold hover:underline underline-offset-4 decoration-blue-400/30">Create one</Link>
        </p>
      </motion.div>
    </div>
  );
}

export default function LoginPage() {
  return (
    <Suspense>
      <LoginForm />
    </Suspense>
  );
}
