'use client';
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { pb } from '@/lib/pocketbase';
import { useAuth } from '../context/AuthContext';

export default function CompleteProfilePage() {
  const { user, refreshUser } = useAuth();
  const router = useRouter();
  const [role, setRole] = useState<'student' | 'parent'>('student');
  const [form, setForm] = useState({ student_id: '', grade_level: '', section: '', phone: '' });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const set = (k: string, v: string) => setForm(f => ({ ...f, [k]: v }));

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(''); setLoading(true);
    try {
      if (!user) throw new Error('Not logged in');
      await pb.collection('users').update(user.id, {
        role,
        phone: form.phone,
        profile_id: role === 'student' ? form.student_id : '',
      });
      await refreshUser();
      router.replace('/dashboard');
    } catch (err: any) {
      setError(err.message);
    } finally { setLoading(false); }
  };

  const inputCls = "w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-white placeholder-gray-500 focus:outline-none focus:border-blue-500 transition";
  const labelCls = "block text-sm font-medium text-gray-300 mb-1.5";

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-950 via-gray-900 to-blue-950 flex items-center justify-center px-4">
      <div className="w-full max-w-md">
        <div className="text-center mb-8">
          <div className="w-16 h-16 bg-gradient-to-br from-blue-500 to-purple-600 rounded-2xl flex items-center justify-center text-3xl mx-auto mb-4">👋</div>
          <h1 className="text-3xl font-bold text-white">Complete your profile</h1>
          <p className="text-gray-400 mt-2">Tell us a bit more to get started</p>
        </div>

        <div className="bg-white/5 border border-white/10 rounded-2xl p-8">
          {error && <div className="bg-red-500/10 border border-red-500/30 text-red-400 rounded-xl px-4 py-3 mb-5 text-sm">{error}</div>}

          <div className="flex rounded-xl bg-white/5 p-1 mb-6">
            {(['student', 'parent'] as const).map(r => (
              <button key={r} type="button" onClick={() => setRole(r)}
                className={`flex-1 py-2 rounded-lg text-sm font-semibold capitalize transition ${role === r ? 'bg-gradient-to-r from-blue-600 to-purple-600 text-white' : 'text-gray-400 hover:text-white'}`}>
                {r === 'student' ? '🎓 Student' : '👨‍👧 Parent'}
              </button>
            ))}
          </div>

          <form onSubmit={handleSubmit} className="space-y-4">
            {role === 'student' && (<>
              <div><label className={labelCls}>Student ID</label><input required value={form.student_id} onChange={e => set('student_id', e.target.value)} className={inputCls} placeholder="STU2024001" /></div>
              <div className="grid grid-cols-2 gap-3">
                <div><label className={labelCls}>Grade Level</label><input required value={form.grade_level} onChange={e => set('grade_level', e.target.value)} className={inputCls} placeholder="Grade 10" /></div>
                <div><label className={labelCls}>Section</label><input value={form.section} onChange={e => set('section', e.target.value)} className={inputCls} placeholder="A" /></div>
              </div>
            </>)}
            {role === 'parent' && (
              <div><label className={labelCls}>Phone Number</label><input type="tel" value={form.phone} onChange={e => set('phone', e.target.value)} className={inputCls} placeholder="+1 234 567 8900" /></div>
            )}
            <button type="submit" disabled={loading}
              className="w-full py-3 rounded-xl bg-gradient-to-r from-blue-600 to-purple-600 hover:opacity-90 disabled:opacity-50 transition font-semibold text-white">
              {loading ? 'Saving...' : 'Complete Setup'}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}
