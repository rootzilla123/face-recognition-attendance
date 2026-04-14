'use client';
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { pb } from '@/lib/pocketbase';

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
      if (role === 'student') {
        formData.append('profile_id', form.student_id); // temp, updated after FastAPI creates student
      }
      if (form.phone) formData.append('phone', form.phone);
      if (photo) formData.append('avatar', photo);

      // Create user in PocketBase
      await pb.collection('users').create(formData);

      // Request email verification
      await pb.collection('users').requestVerification(form.email);

      // If student, also create in FastAPI backend
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

        const apiUrl = typeof window !== 'undefined'
          ? `${window.location.protocol}//${window.location.hostname}:8001`
          : 'http://localhost:8001';
        const ctrl = new AbortController();
        const t = setTimeout(() => ctrl.abort(), 5000);
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

  const inputCls = "w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-white placeholder-gray-500 focus:outline-none focus:border-blue-500 transition";
  const labelCls = "block text-sm font-medium text-gray-300 mb-1.5";

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-950 via-gray-900 to-blue-950 flex items-center justify-center px-4 py-12">
      <div className="w-full max-w-md">
        <div className="text-center mb-8">
          <Link href="/" className="inline-flex items-center gap-2 mb-6">
            <div className="w-10 h-10 bg-gradient-to-br from-blue-500 to-purple-600 rounded-xl flex items-center justify-center"><span className="text-xl">📸</span></div>
            <span className="text-xl font-bold text-white">AttendanceAI</span>
          </Link>
          <h1 className="text-3xl font-bold text-white">Create account</h1>
          <p className="text-gray-400 mt-2">Join your school attendance system</p>
        </div>

        <div className="bg-white/5 border border-white/10 rounded-2xl p-8">
          <div className="flex rounded-xl bg-white/5 p-1 mb-6">
            {(['student', 'parent'] as RoleType[]).map(r => (
              <button key={r} type="button" onClick={() => setRole(r)}
                className={`flex-1 py-2 rounded-lg text-sm font-semibold capitalize transition ${role === r ? 'bg-gradient-to-r from-blue-600 to-purple-600 text-white' : 'text-gray-400 hover:text-white'}`}>
                {r === 'student' ? '🎓 Student' : '👨‍👧 Parent'}
              </button>
            ))}
          </div>

          {error && <div className="bg-red-500/10 border border-red-500/30 text-red-400 rounded-xl px-4 py-3 mb-5 text-sm">{error}</div>}

          <form onSubmit={handleSubmit} className="space-y-4">
            <div><label className={labelCls}>Full Name</label><input type="text" required value={form.name} onChange={e => set('name', e.target.value)} className={inputCls} placeholder="John Doe" /></div>
            <div><label className={labelCls}>Email</label><input type="email" required value={form.email} onChange={e => set('email', e.target.value)} className={inputCls} placeholder="you@school.com" /></div>
            <div><label className={labelCls}>Password</label><input type="password" required minLength={8} value={form.password} onChange={e => set('password', e.target.value)} className={inputCls} placeholder="••••••••" /></div>
            <div><label className={labelCls}>Confirm Password</label><input type="password" required value={form.passwordConfirm} onChange={e => set('passwordConfirm', e.target.value)} className={inputCls} placeholder="••••••••" /></div>

            {role === 'student' && (<>
              <div><label className={labelCls}>Student ID</label><input type="text" required value={form.student_id} onChange={e => set('student_id', e.target.value)} className={inputCls} placeholder="STU2024001" /></div>
              <div className="grid grid-cols-2 gap-3">
                <div><label className={labelCls}>Grade Level</label><input type="text" required value={form.grade_level} onChange={e => set('grade_level', e.target.value)} className={inputCls} placeholder="Grade 10" /></div>
                <div><label className={labelCls}>Section</label><input type="text" value={form.section} onChange={e => set('section', e.target.value)} className={inputCls} placeholder="A" /></div>
              </div>
              <div>
                <label className={labelCls}>Face Photo <span className="text-gray-500 font-normal">(for recognition)</span></label>
                <label className="flex flex-col items-center justify-center w-full h-32 border-2 border-dashed border-white/20 rounded-xl cursor-pointer hover:border-blue-500 transition overflow-hidden">
                  {photoPreview ? <img src={photoPreview} alt="preview" className="w-full h-full object-cover" /> : (
                    <div className="text-center"><p className="text-3xl mb-1">📷</p><p className="text-sm text-gray-400">Click to upload a clear headshot</p></div>
                  )}
                  <input type="file" accept="image/*" onChange={handlePhoto} className="hidden" />
                </label>
                {photo && <p className="text-xs text-green-400 mt-1">✓ {photo.name} — will be enrolled for face recognition</p>}
              </div>
            </>)}

            {role === 'parent' && (
              <div><label className={labelCls}>Phone Number</label><input type="tel" value={form.phone} onChange={e => set('phone', e.target.value)} className={inputCls} placeholder="+1 234 567 8900" /></div>
            )}

            <button type="submit" disabled={loading}
              className="w-full py-3 rounded-xl bg-gradient-to-r from-blue-600 to-purple-600 hover:opacity-90 disabled:opacity-50 transition font-semibold text-white mt-2">
              {loading ? 'Creating account...' : 'Create Account'}
            </button>
          </form>
          <p className="text-center text-gray-400 text-sm mt-6">Already have an account? <Link href="/login" className="text-blue-400 hover:text-blue-300 font-medium">Sign in</Link></p>
        </div>
      </div>
    </div>
  );
}
