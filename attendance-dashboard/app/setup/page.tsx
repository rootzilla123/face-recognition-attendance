'use client';
import { useState } from 'react';
import Link from 'next/link';
import { pb } from '@/lib/pocketbase';

export default function SetupPage() {
  const [form, setForm] = useState({ email: '', password: '', name: '' });
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [done, setDone] = useState(false);

  const set = (k: string, v: string) => setForm(f => ({ ...f, [k]: v }));

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(''); setLoading(true);
    try {
      // Create admin user in PocketBase
      await pb.collection('users').create({
        email: form.email,
        password: form.password,
        passwordConfirm: form.password,
        name: form.name,
        role: 'admin',
        emailVisibility: true,
      });
      setDone(true);
    } catch (err: any) {
      const msg = err?.response?.data?.email?.message || err.message || 'Failed';
      if (msg.includes('unique') || msg.includes('exists')) {
        setError('An admin account already exists. Go to login.');
      } else {
        setError(msg);
      }
    } finally { setLoading(false); }
  };

  const inputCls = "w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-white placeholder-gray-500 focus:outline-none focus:border-purple-500 transition";

  if (done) return (
    <div className="min-h-screen bg-gradient-to-br from-gray-950 via-gray-900 to-purple-950 flex items-center justify-center px-4">
      <div className="text-center">
        <div className="text-6xl mb-4">✅</div>
        <h1 className="text-3xl font-bold text-white mb-2">Admin account created</h1>
        <p className="text-gray-400 mb-8">Sign in with your credentials to get started.</p>
        <Link href="/login" className="px-8 py-3 rounded-xl bg-gradient-to-r from-purple-600 to-pink-600 text-white font-semibold hover:opacity-90 transition">
          Go to Login
        </Link>
      </div>
    </div>
  );

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-950 via-gray-900 to-purple-950 flex items-center justify-center px-4">
      <div className="w-full max-w-md">
        <div className="text-center mb-8">
          <div className="w-16 h-16 bg-gradient-to-br from-purple-500 to-pink-600 rounded-2xl flex items-center justify-center text-3xl mx-auto mb-4">🛡️</div>
          <h1 className="text-3xl font-bold text-white">System Setup</h1>
          <p className="text-gray-400 mt-2">Create the first administrator account</p>
        </div>
        <div className="bg-white/5 border border-white/10 rounded-2xl p-8">
          <div className="bg-yellow-500/10 border border-yellow-500/30 text-yellow-300 rounded-xl px-4 py-3 mb-6 text-sm">
            ⚠️ Only needed once. After setup, use the login page.
          </div>
          {error && <div className="bg-red-500/10 border border-red-500/30 text-red-400 rounded-xl px-4 py-3 mb-5 text-sm">{error}</div>}
          <form onSubmit={handleSubmit} className="space-y-4">
            <div><label className="block text-sm font-medium text-gray-300 mb-1.5">Full Name</label><input required value={form.name} onChange={e => set('name', e.target.value)} className={inputCls} placeholder="System Administrator" /></div>
            <div><label className="block text-sm font-medium text-gray-300 mb-1.5">Email</label><input type="email" required value={form.email} onChange={e => set('email', e.target.value)} className={inputCls} placeholder="admin@school.com" /></div>
            <div><label className="block text-sm font-medium text-gray-300 mb-1.5">Password</label><input type="password" required minLength={8} value={form.password} onChange={e => set('password', e.target.value)} className={inputCls} placeholder="••••••••" /></div>
            <button type="submit" disabled={loading}
              className="w-full py-3 rounded-xl bg-gradient-to-r from-purple-600 to-pink-600 hover:opacity-90 disabled:opacity-50 transition font-semibold text-white">
              {loading ? 'Creating...' : 'Create Admin Account'}
            </button>
          </form>
          <p className="text-center text-gray-500 text-sm mt-6">Already set up? <Link href="/login" className="text-purple-400 hover:text-purple-300">Sign in</Link></p>
        </div>
      </div>
    </div>
  );
}
