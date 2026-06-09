'use client';
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { pb } from '@/lib/pocketbase';

const STEPS = ['School Info', 'Add Camera', 'Add Student', 'Done'];

export default function OnboardingPage() {
  const router = useRouter();
  const [step, setStep] = useState(0);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const [school, setSchool] = useState({ name: '', email: '', password: '' });
  const [camera, setCamera] = useState({ name: '', url: '' });
  const [student, setStudent] = useState({ name: '', email: '' });

  const inputCls = "w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-white placeholder-gray-500 focus:outline-none focus:border-purple-500 transition";
  const btnCls = "w-full py-3 rounded-xl bg-gradient-to-r from-purple-600 to-pink-600 hover:opacity-90 disabled:opacity-50 transition font-semibold text-white";

  async function handleSchool(e: React.FormEvent) {
    e.preventDefault();
    setError(''); setLoading(true);
    try {
      await pb.collection('users').create({
        email: school.email,
        password: school.password,
        passwordConfirm: school.password,
        name: school.name,
        role: 'admin',
        emailVisibility: true,
      });
      await pb.collection('users').authWithPassword(school.email, school.password);
      setStep(1);
    } catch (err: any) {
      const msg = err?.response?.data?.email?.message || err.message || 'Failed';
      setError(msg.includes('unique') ? 'Email already exists. Go to login.' : msg);
    } finally { setLoading(false); }
  }

  async function handleCamera(e: React.FormEvent) {
    e.preventDefault();
    setError(''); setLoading(true);
    try {
      await pb.collection('cameras').create({ name: camera.name, url: camera.url, status: 'active' });
      setStep(2);
    } catch (err: any) {
      setError(err.message || 'Failed to add camera');
    } finally { setLoading(false); }
  }

  async function handleStudent(e: React.FormEvent) {
    e.preventDefault();
    setError(''); setLoading(true);
    try {
      await pb.collection('users').create({
        email: student.email,
        password: 'Temp1234!',
        passwordConfirm: 'Temp1234!',
        name: student.name,
        role: 'student',
        emailVisibility: true,
      });
      setStep(3);
    } catch (err: any) {
      setError(err.message || 'Failed to add student');
    } finally { setLoading(false); }
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-950 via-gray-900 to-purple-950 flex items-center justify-center px-4">
      <div className="w-full max-w-md">
        {/* Progress */}
        <div className="flex items-center justify-between mb-8">
          {STEPS.map((s, i) => (
            <div key={s} className="flex items-center">
              <div className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold transition-all ${i <= step ? 'bg-purple-600 text-white' : 'bg-white/10 text-gray-500'}`}>
                {i < step ? '✓' : i + 1}
              </div>
              {i < STEPS.length - 1 && <div className={`h-0.5 w-10 mx-1 transition-all ${i < step ? 'bg-purple-600' : 'bg-white/10'}`} />}
            </div>
          ))}
        </div>

        <div className="bg-white/5 border border-white/10 rounded-2xl p-8">
          {error && <div className="bg-red-500/10 border border-red-500/30 text-red-400 rounded-xl px-4 py-3 mb-5 text-sm">{error}</div>}

          {/* Step 0: School / Admin */}
          {step === 0 && (
            <form onSubmit={handleSchool} className="space-y-4">
              <h2 className="text-2xl font-bold text-white mb-1">Welcome to AttendanceAI</h2>
              <p className="text-gray-400 text-sm mb-4">Let's set up your school account.</p>
              <div><label className="block text-sm text-gray-300 mb-1.5">School / Admin Name</label>
                <input required value={school.name} onChange={e => setSchool(s => ({ ...s, name: e.target.value }))} className={inputCls} placeholder="Greenfield Academy" /></div>
              <div><label className="block text-sm text-gray-300 mb-1.5">Admin Email</label>
                <input type="email" required value={school.email} onChange={e => setSchool(s => ({ ...s, email: e.target.value }))} className={inputCls} placeholder="admin@school.com" /></div>
              <div><label className="block text-sm text-gray-300 mb-1.5">Password</label>
                <input type="password" required minLength={8} value={school.password} onChange={e => setSchool(s => ({ ...s, password: e.target.value }))} className={inputCls} placeholder="••••••••" /></div>
              <button type="submit" disabled={loading} className={btnCls}>{loading ? 'Creating...' : 'Get Started →'}</button>
            </form>
          )}

          {/* Step 1: Camera */}
          {step === 1 && (
            <form onSubmit={handleCamera} className="space-y-4">
              <h2 className="text-2xl font-bold text-white mb-1">Add Your First Camera</h2>
              <p className="text-gray-400 text-sm mb-4">Connect a camera to start tracking attendance.</p>
              <div><label className="block text-sm text-gray-300 mb-1.5">Camera Name</label>
                <input required value={camera.name} onChange={e => setCamera(c => ({ ...c, name: e.target.value }))} className={inputCls} placeholder="Main Entrance" /></div>
              <div><label className="block text-sm text-gray-300 mb-1.5">Camera URL (RTSP or IP)</label>
                <input required value={camera.url} onChange={e => setCamera(c => ({ ...c, url: e.target.value }))} className={inputCls} placeholder="rtsp://192.168.1.100/stream" /></div>
              <button type="submit" disabled={loading} className={btnCls}>{loading ? 'Adding...' : 'Add Camera →'}</button>
              <button type="button" onClick={() => setStep(2)} className="w-full py-2 text-gray-500 hover:text-gray-300 text-sm transition">Skip for now</button>
            </form>
          )}

          {/* Step 2: Student */}
          {step === 2 && (
            <form onSubmit={handleStudent} className="space-y-4">
              <h2 className="text-2xl font-bold text-white mb-1">Add Your First Student</h2>
              <p className="text-gray-400 text-sm mb-4">You can add more students from the dashboard later.</p>
              <div><label className="block text-sm text-gray-300 mb-1.5">Student Name</label>
                <input required value={student.name} onChange={e => setStudent(s => ({ ...s, name: e.target.value }))} className={inputCls} placeholder="John Doe" /></div>
              <div><label className="block text-sm text-gray-300 mb-1.5">Student Email</label>
                <input type="email" required value={student.email} onChange={e => setStudent(s => ({ ...s, email: e.target.value }))} className={inputCls} placeholder="john@school.com" /></div>
              <p className="text-xs text-gray-500">A temporary password <span className="text-gray-400 font-mono">Temp1234!</span> will be assigned.</p>
              <button type="submit" disabled={loading} className={btnCls}>{loading ? 'Adding...' : 'Add Student →'}</button>
              <button type="button" onClick={() => setStep(3)} className="w-full py-2 text-gray-500 hover:text-gray-300 text-sm transition">Skip for now</button>
            </form>
          )}

          {/* Step 3: Done */}
          {step === 3 && (
            <div className="text-center space-y-4">
              <div className="text-6xl">🎉</div>
              <h2 className="text-2xl font-bold text-white">You're all set!</h2>
              <p className="text-gray-400 text-sm">Your school is configured and ready to go. Head to your dashboard to manage everything.</p>
              <button onClick={() => router.push('/dashboard')} className={btnCls}>Go to Dashboard →</button>
            </div>
          )}
        </div>

        {step === 0 && (
          <p className="text-center text-gray-500 text-sm mt-4">Already set up? <a href="/login" className="text-purple-400 hover:text-purple-300">Sign in</a></p>
        )}
      </div>
    </div>
  );
}
