'use client';
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { pb } from '@/lib/pocketbase';
import { motion, AnimatePresence } from 'framer-motion';

type RoleType = 'student' | 'parent';

export default function RegisterPage() {
  const router = useRouter();
  const [role, setRole] = useState<RoleType>('student');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [form, setForm] = useState({ email: '', password: '', passwordConfirm: '', name: '', student_id: '', grade_level: '', section: '', phone: '' });
  const [photo, setPhoto] = useState<File | null>(null);
  const [photoPreview, setPhotoPreview] = useState<string | null>(null);

  const set = (k: string, v: string) => setForm(f => ({ ...f, [k]: v }));

  const handlePhoto = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setPhoto(file);
    setPhotoPreview(URL.createObjectURL(file));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(''); setLoading(true);
    try {
      if (form.password !== form.passwordConfirm) throw new Error('Passwords do not match');

      const formData = new FormData();
      formData.append('email', form.email);
      formData.append('password', form.password);
      formData.append('passwordConfirm', form.passwordConfirm);
      formData.append('name', form.name);
      formData.append('role', role);
      if (role === 'student') formData.append('profile_id', form.student_id);
      if (form.phone) formData.append('phone', form.phone);
      if (photo) formData.append('avatar', photo);

      await pb.collection('users').create(formData);
      await pb.collection('users').requestVerification(form.email);

      if (role === 'student') {
        const loginRes = await pb.collection('users').authWithPassword(form.email, form.password);
        const token = pb.authStore.token;
        const studentForm = new FormData();
        studentForm.append('student_id', form.student_id);
        studentForm.append('full_name', form.name);
        studentForm.append('grade_level', form.grade_level);
        if (form.section) studentForm.append('section', form.section);
        studentForm.append('parent_phone', form.phone || '');
        studentForm.append('parent_email', form.email);
        if (photo) studentForm.append('photo', photo);

        const apiUrl = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:8001';
        const ctrl = new AbortController();
        const t = setTimeout(() => ctrl.abort(), 8000);
        await fetch(`${apiUrl}/api/v1/students`, {
          method: 'POST',
          headers: { Authorization: `Bearer ${token}` },
          body: studentForm,
          signal: ctrl.signal,
        }).catch(() => {}).finally(() => clearTimeout(t));
        pb.authStore.clear();
      }

      router.replace('/login?registered=1');
    } catch (err: any) {
      setError(err.message || 'Registration failed');
    } finally { setLoading(false); }
  };

  const inputCls = "w-full bg-white/[0.03] border border-white/5 rounded-2xl px-5 py-3 text-white placeholder-gray-500 focus:outline-none focus:border-blue-500/40 focus:bg-white/[0.06] transition-all duration-300";
  const labelCls = "text-sm font-semibold text-gray-300 mb-2 ml-1 block";

  return (
    <div className="min-h-screen bg-[#030712] flex items-center justify-center px-4 py-16 relative overflow-hidden">
      <div className="fixed inset-0 bg-grid opacity-[0.1] pointer-events-none" />
      <div className="absolute top-0 right-0 w-[500px] h-[500px] bg-blue-600/5 blur-[150px] pointer-events-none" />

      <motion.div 
        initial={{ opacity: 0, scale: 0.98 }}
        animate={{ opacity: 1, scale: 1 }}
        className="w-full max-w-[550px] relative z-10"
      >
        <div className="text-center mb-10">
          <Link href="/" className="inline-flex items-center gap-3 mb-6 group">
            <div className="w-12 h-12 bg-gradient-to-br from-blue-500 to-purple-600 rounded-2xl flex items-center justify-center shadow-glow-blue group-hover:scale-110 transition-transform duration-500">
              <span className="text-2xl">📸</span>
            </div>
            <span className="text-2xl font-bold tracking-tight text-white">AttendanceAI</span>
          </Link>
          <h1 className="text-3xl font-extrabold tracking-tight text-white">Create Account</h1>
          <p className="text-gray-400 mt-2 font-medium italic">Join your school's smart attendance system</p>
        </div>

        <div className="glass-panel rounded-[2.5rem] p-8 md:p-12 relative group overflow-hidden border-white/[0.08] shadow-2xl">
          <div className="flex bg-white/[0.05] p-1.5 rounded-2xl mb-10 border border-white/5">
            {(['student', 'parent'] as RoleType[]).map(r => (
              <button key={r} type="button" onClick={() => setRole(r)}
                className={`flex-1 py-3 rounded-xl text-sm font-bold capitalize transition-all duration-300 ${role === r ? 'bg-gradient-to-r from-blue-600 to-purple-600 text-white shadow-glow-blue' : 'text-gray-500 hover:text-white'}`}>
                {r === 'student' ? 'Student' : 'Parent'}
              </button>
            ))}
          </div>

          <form onSubmit={handleSubmit} className="space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div><label className={labelCls}>Full Name</label><input type="text" required value={form.name} onChange={e => set('name', e.target.value)} className={inputCls} placeholder="John Doe" /></div>
              <div><label className={labelCls}>Email Address</label><input type="email" required value={form.email} onChange={e => set('email', e.target.value)} className={inputCls} placeholder="name@school.com" /></div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div><label className={labelCls}>Password</label><input type="password" required minLength={8} value={form.password} onChange={e => set('password', e.target.value)} className={inputCls} placeholder="••••••••" /></div>
              <div><label className={labelCls}>Confirm Password</label><input type="password" required value={form.passwordConfirm} onChange={e => set('passwordConfirm', e.target.value)} className={inputCls} placeholder="••••••••" /></div>
            </div>

            {role === 'student' && (
              <motion.div initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: 'auto' }} className="space-y-6 pt-4 border-t border-white/5 overflow-hidden">
                <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                  <div><label className={labelCls}>Student ID</label><input type="text" required value={form.student_id} onChange={e => set('student_id', e.target.value)} className={inputCls} placeholder="STU-001" /></div>
                  <div><label className={labelCls}>Grade</label><input type="text" required value={form.grade_level} onChange={e => set('grade_level', e.target.value)} className={inputCls} placeholder="11" /></div>
                  <div><label className={labelCls}>Section</label><input type="text" value={form.section} onChange={e => set('section', e.target.value)} className={inputCls} placeholder="A" /></div>
                </div>
                
                <div className="relative">
                  <label className={labelCls}>Upload Face Photo <span className="text-gray-500 font-normal ml-1">(for recognition)</span></label>
                  <label className="flex items-center justify-center w-full h-40 border-2 border-dashed border-white/10 rounded-[2rem] cursor-pointer hover:bg-blue-500/5 hover:border-blue-500/30 transition-all overflow-hidden bg-black/20">
                    {photoPreview ? (
                      <img src={photoPreview} alt="preview" className="w-full h-full object-cover" />
                    ) : (
                      <div className="text-center"><p className="text-2xl mb-2">📸</p><p className="text-xs font-bold text-gray-500 uppercase tracking-widest">Select Image</p></div>
                    )}
                    <input type="file" accept="image/*" onChange={handlePhoto} className="hidden" />
                  </label>
                </div>
              </motion.div>
            )}

            {role === 'parent' && (
              <motion.div initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: 'auto' }} className="pt-4 border-t border-white/5">
                <label className={labelCls}>Mobile Number <span className="text-gray-500 font-normal ml-1">(for SMS alerts)</span></label>
                <input type="tel" value={form.phone} onChange={e => set('phone', e.target.value)} className={inputCls} placeholder="+1 234 567 8900" />
              </motion.div>
            )}

            {error && <div className="text-red-400 text-sm text-center font-bold px-2 py-1 bg-red-500/10 rounded-xl border border-red-500/20">{error}</div>}

            <button type="submit" disabled={loading}
              className="w-full py-4 rounded-2xl bg-gradient-to-r from-blue-600 via-blue-500 to-purple-600 hover:from-blue-500 hover:to-purple-500 disabled:opacity-50 transition-all font-bold text-white shadow-glow-purple transform hover:scale-[1.01] active:scale-95 shimmer-btn mt-4">
              {loading ? 'Creating account...' : 'Create My Account'}
            </button>
          </form>
          
          <p className="text-center text-gray-400 text-sm mt-10">
            Already have an account? <Link href="/login" className="text-blue-500 hover:text-blue-400 font-bold hover:underline underline-offset-4 decoration-blue-400/30">Sign In</Link>
          </p>
        </div>
      </motion.div>
    </div>
  );
}
