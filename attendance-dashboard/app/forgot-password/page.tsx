'use client';
import { useState } from 'react';
import Link from 'next/link';
import { pb } from '@/lib/pocketbase';

export default function ForgotPasswordPage() {
  const [email, setEmail] = useState('');
  const [sent, setSent] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(''); setLoading(true);
    try {
      await pb.collection('users').requestPasswordReset(email);
      setSent(true);
    } catch (err: any) {
      // Always show success to prevent email enumeration
      setSent(true);
    } finally { setLoading(false); }
  };

  if (sent) return (
    <div className="min-h-screen bg-gradient-to-br from-gray-950 via-gray-900 to-blue-950 flex items-center justify-center px-4">
      <div className="text-center max-w-md">
        <div className="text-6xl mb-4">📧</div>
        <h1 className="text-2xl font-bold text-white mb-2">Check your email</h1>
        <p className="text-gray-400 mb-6">If an account exists for <span className="text-white font-medium">{email}</span>, a reset link has been sent.</p>
        <p className="text-gray-500 text-sm mb-6">The link expires in 30 minutes. Check your spam folder if you don't see it.</p>
        <Link href="/login" className="text-blue-400 hover:text-blue-300 text-sm">Back to sign in</Link>
      </div>
    </div>
  );

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-950 via-gray-900 to-blue-950 flex items-center justify-center px-4">
      <div className="w-full max-w-md">
        <div className="text-center mb-8">
          <Link href="/" className="inline-flex items-center gap-2 mb-6">
            <div className="w-10 h-10 bg-gradient-to-br from-blue-500 to-purple-600 rounded-xl flex items-center justify-center"><span className="text-xl">📸</span></div>
            <span className="text-xl font-bold text-white">AttendanceAI</span>
          </Link>
          <h1 className="text-3xl font-bold text-white">Reset password</h1>
          <p className="text-gray-400 mt-2">We'll send a reset link to your email</p>
        </div>
        <div className="bg-white/5 border border-white/10 rounded-2xl p-8">
          {error && <div className="bg-red-500/10 border border-red-500/30 text-red-400 rounded-xl px-4 py-3 mb-5 text-sm">{error}</div>}
          <form onSubmit={handleSubmit} className="space-y-5">
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-1.5">Email</label>
              <input type="email" required value={email} onChange={e => setEmail(e.target.value)}
                className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-white placeholder-gray-500 focus:outline-none focus:border-blue-500 transition"
                placeholder="you@school.com" />
            </div>
            <button type="submit" disabled={loading}
              className="w-full py-3 rounded-xl bg-gradient-to-r from-blue-600 to-purple-600 hover:opacity-90 disabled:opacity-50 transition font-semibold text-white">
              {loading ? 'Sending...' : 'Send Reset Link'}
            </button>
          </form>
          <p className="text-center text-gray-400 text-sm mt-6"><Link href="/login" className="text-blue-400 hover:text-blue-300">Back to sign in</Link></p>
        </div>
      </div>
    </div>
  );
}
