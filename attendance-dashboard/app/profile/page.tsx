'use client';
import { useEffect, useState } from 'react';
import { api } from '@/lib/api';
import { useAuth } from '../context/AuthContext';
import RouteGuard from '../components/RouteGuard';
import { pb } from '@/lib/pocketbase';

function ProfileContent() {
  const { user } = useAuth();
  const [profile, setProfile] = useState<any>(null);
  const [error, setError] = useState('');
  const [photo, setPhoto] = useState<File | null>(null);
  const [photoPreview, setPhotoPreview] = useState<string | null>(null);
  const [enrolling, setEnrolling] = useState(false);
  const [enrollMsg, setEnrollMsg] = useState('');

  useEffect(() => {
    api.getMyStudentProfile().then(setProfile).catch(e => setError(e.message));
  }, []);

  const handlePhoto = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setPhoto(file);
    setPhotoPreview(URL.createObjectURL(file));
  };

  const enrollFace = async () => {
    if (!photo || !profile) return;
    setEnrolling(true); setEnrollMsg('');
    try {
      const formData = new FormData();
      formData.append('photo', photo);
      // Use the correct re-enroll endpoint
      const apiBase = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:8001';
      const res = await fetch(`${apiBase}/api/v1/students/${profile.student_id}/enroll-face`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${pb.authStore.token}` },
        body: formData,
      });
      if (!res.ok) {
        const err = await res.json();
        throw new Error(err.detail || 'Enrollment failed');
      }
      setEnrollMsg('✅ Face enrolled successfully! You will now be recognized by cameras.');
      setPhoto(null); setPhotoPreview(null);
    } catch (err: any) {
      setEnrollMsg(`❌ ${err.message}`);
    } finally { setEnrolling(false); }
  };

  return (
    <div className="p-8 space-y-6">
      <h1 className="text-3xl font-bold text-gray-900">My Profile</h1>

      {error && <div className="bg-red-50 border border-red-200 text-red-600 rounded-xl px-4 py-3 text-sm">Could not load profile: {error}</div>}

      {!profile && !error && <div className="flex justify-center py-12"><div className="w-8 h-8 border-4 border-green-500 border-t-transparent rounded-full animate-spin" /></div>}

      {profile && (
        <>
          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-8 max-w-lg">
            <div className="flex items-center gap-5 mb-8">
              <div className="w-20 h-20 bg-gradient-to-br from-green-500 to-teal-600 rounded-2xl flex items-center justify-center text-4xl">🎓</div>
              <div>
                <h2 className="text-2xl font-bold text-gray-900">{profile.full_name}</h2>
                <p className="text-gray-500">{profile.grade_level}{profile.section ? ` • Section ${profile.section}` : ''}</p>
              </div>
            </div>
            <div className="space-y-3">
              {[
                { label: 'Student ID', value: profile.student_id },
                { label: 'Email', value: user?.email || '—' },
                { label: 'Grade Level', value: profile.grade_level },
                { label: 'Section', value: profile.section || '—' },
                { label: 'Status', value: profile.is_active ? '✅ Active' : '❌ Inactive' },
              ].map(({ label, value }) => (
                <div key={label} className="flex justify-between py-3 border-b border-gray-50 last:border-0">
                  <span className="text-sm text-gray-500">{label}</span>
                  <span className="text-sm font-medium text-gray-900">{value}</span>
                </div>
              ))}
            </div>
          </div>

          {/* Face enrollment */}
          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 max-w-lg">
            <h2 className="text-lg font-bold text-gray-900 mb-1">Face Recognition Enrollment</h2>
            <p className="text-sm text-gray-500 mb-4">Upload a clear headshot to be recognized by attendance cameras.</p>

            {enrollMsg && (
              <div className={`rounded-xl px-4 py-3 mb-4 text-sm ${enrollMsg.startsWith('✅') ? 'bg-green-50 text-green-700' : 'bg-red-50 text-red-600'}`}>
                {enrollMsg}
              </div>
            )}

            <label className="flex flex-col items-center justify-center w-full h-36 border-2 border-dashed border-gray-200 rounded-xl cursor-pointer hover:border-blue-400 transition overflow-hidden mb-3">
              {photoPreview ? <img src={photoPreview} alt="preview" className="w-full h-full object-cover" /> : (
                <div className="text-center"><p className="text-3xl mb-1">📷</p><p className="text-sm text-gray-400">Click to select a photo</p></div>
              )}
              <input type="file" accept="image/*" onChange={handlePhoto} className="hidden" />
            </label>

            {photo && (
              <button onClick={enrollFace} disabled={enrolling}
                className="w-full py-2.5 bg-gradient-to-r from-green-500 to-teal-600 text-white rounded-xl text-sm font-semibold hover:opacity-90 disabled:opacity-50 transition">
                {enrolling ? 'Enrolling...' : 'Enroll Face for Recognition'}
              </button>
            )}
          </div>
        </>
      )}
    </div>
  );
}

export default function ProfilePage() {
  return <RouteGuard allowedRoles={['student']}><ProfileContent /></RouteGuard>;
}
