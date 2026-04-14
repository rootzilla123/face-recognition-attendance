'use client';
import { useEffect, useState } from 'react';
import RouteGuard from '../components/RouteGuard';
import { getToken } from '@/lib/auth';
import { api } from '@/lib/api';

const API = typeof window !== 'undefined'
  ? `${window.location.protocol}//${window.location.hostname}:8001`
  : 'http://localhost:8001';

function TeacherProfileContent() {
  const [profile, setProfile] = useState<any>(null);
  const [cameras, setCameras] = useState<any[]>([]);
  const [attendance, setAttendance] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([
      fetch(`${API}/api/v1/admin/teacher/me`, { headers: { Authorization: `Bearer ${getToken()}` } }).then(r => r.ok ? r.json() : null),
      api.getCameras(),
      api.getTodayAttendance(),
    ]).then(([p, c, a]) => {
      setProfile(p);
      setCameras(Array.isArray(c) ? c : []);
      setAttendance(Array.isArray(a) ? a : []);
    }).catch(console.error).finally(() => setLoading(false));
  }, []);

  if (loading) return <div className="flex items-center justify-center min-h-screen"><div className="w-8 h-8 border-4 border-blue-500 border-t-transparent rounded-full animate-spin" /></div>;

  return (
    <div className="p-8 space-y-6">
      <h1 className="text-3xl font-bold text-gray-900">My Profile</h1>

      {/* Profile card */}
      {profile && (
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 flex items-center gap-5">
          <div className="w-16 h-16 bg-gradient-to-br from-blue-500 to-cyan-600 rounded-2xl flex items-center justify-center text-3xl">👩‍🏫</div>
          <div className="flex-1">
            <h2 className="text-xl font-bold text-gray-900">{profile.full_name}</h2>
            <p className="text-gray-500">{profile.department || 'No department'}{profile.class_name ? ` • ${profile.class_name}` : ''}</p>
            <p className="text-sm text-gray-400">ID: {profile.employee_id} • {profile.email}</p>
          </div>
        </div>
      )}

      {/* Assigned cameras */}
      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
        <h2 className="text-lg font-bold text-gray-900 mb-4">My Assigned Cameras</h2>
        {cameras.length === 0 ? (
          <p className="text-gray-400 text-sm">No cameras assigned yet. Contact your admin.</p>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            {cameras.map((c: any) => (
              <div key={c.id} className="flex items-center gap-3 p-4 bg-gray-50 rounded-xl border border-gray-100">
                <div className={`w-3 h-3 rounded-full flex-shrink-0 ${c.status === 'online' ? 'bg-green-400' : 'bg-gray-300'}`} />
                <div>
                  <p className="font-medium text-gray-900 text-sm">{c.name}</p>
                  <p className="text-xs text-gray-400 capitalize">{c.location?.replace(/_/g, ' ')}</p>
                </div>
                <span className={`ml-auto text-xs px-2 py-1 rounded-full font-medium ${c.status === 'online' ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>
                  {c.status}
                </span>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Today's attendance from my cameras */}
      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
        <h2 className="text-lg font-bold text-gray-900 mb-4">Today's Attendance — My Class</h2>
        {attendance.length === 0 ? (
          <p className="text-gray-400 text-sm">No attendance records yet today.</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead><tr className="text-left text-gray-400 border-b border-gray-100">
                <th className="pb-3 font-medium">Student ID</th>
                <th className="pb-3 font-medium">Location</th>
                <th className="pb-3 font-medium">Time</th>
                <th className="pb-3 font-medium">Confidence</th>
              </tr></thead>
              <tbody className="divide-y divide-gray-50">
                {attendance.slice(0, 20).map((r: any) => (
                  <tr key={r.id} className="hover:bg-gray-50">
                    <td className="py-3 font-medium text-gray-900">{r.student_id}</td>
                    <td className="py-3 text-gray-600 capitalize">{r.camera_location?.replace(/_/g, ' ')}</td>
                    <td className="py-3 text-gray-600">{new Date(r.timestamp).toLocaleTimeString()}</td>
                    <td className="py-3"><span className="bg-green-100 text-green-700 px-2 py-0.5 rounded-full text-xs font-medium">{(r.confidence_score * 100).toFixed(1)}%</span></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}

export default function TeacherProfilePage() {
  return <RouteGuard allowedRoles={['teacher']}><TeacherProfileContent /></RouteGuard>;
}
