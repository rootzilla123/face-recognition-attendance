'use client';
import { useEffect, useState } from 'react';
import { api } from '@/lib/api';
import { useAuth } from '../../context/AuthContext';
import { pb } from '@/lib/pocketbase';

const API = typeof window !== 'undefined'
  ? `${window.location.protocol}//${window.location.hostname}:8001`
  : 'http://localhost:8001';

export default function TeacherDashboard() {
  const { user } = useAuth();
  const [stats, setStats] = useState<any>(null);
  const [today, setToday] = useState<any[]>([]);
  const [profile, setProfile] = useState<any>(null);
  const [cameras, setCameras] = useState<any[]>([]);
  const [error, setError] = useState('');

  useEffect(() => {
    Promise.all([
      api.getAttendanceStats(),
      api.getTodayAttendance(),
      fetch(`${API}/api/v1/admin/teacher/me`, { headers: { Authorization: `Bearer ${pb.authStore.token}` } }).then(r => r.ok ? r.json() : null),
      api.getCameras(),
    ]).then(([s, t, p, c]) => {
      setStats(s); setToday(Array.isArray(t) ? t : []);
      setProfile(p); setCameras(Array.isArray(c) ? c : []);
    }).catch(e => setError(e.message));
  }, []);

  return (
    <div className="p-8 space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Teacher Dashboard</h1>
        <p className="text-gray-500 mt-1">Welcome, {user?.name}</p>
      </div>

      {error && <div className="bg-red-50 border border-red-200 text-red-600 rounded-xl px-4 py-3 text-sm">{error}</div>}

      {/* Profile + class info */}
      {profile && (
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5 flex items-center gap-4">
          <div className="w-14 h-14 bg-gradient-to-br from-blue-500 to-cyan-600 rounded-2xl flex items-center justify-center text-2xl">👩‍🏫</div>
          <div>
            <p className="font-bold text-gray-900 text-lg">{profile.full_name}</p>
            <p className="text-gray-500 text-sm">{profile.department || '—'}{profile.class_name ? ` • ${profile.class_name}` : ''}</p>
            <p className="text-xs text-gray-400">ID: {profile.employee_id}</p>
          </div>
        </div>
      )}

      {/* Stats */}
      <div className="grid grid-cols-3 gap-4">
        {[
          { label: 'Present Today', value: stats?.present_students ?? 0, icon: '✅', color: 'from-green-500 to-green-600' },
          { label: 'Absent Today', value: stats?.absent_students ?? 0, icon: '❌', color: 'from-red-500 to-red-600' },
          { label: 'Attendance Rate', value: `${(stats?.attendance_percentage ?? 0).toFixed(1)}%`, icon: '📊', color: 'from-blue-500 to-blue-600' },
        ].map(({ label, value, icon, color }) => (
          <div key={label} className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
            <div className={`w-10 h-10 bg-gradient-to-br ${color} rounded-xl flex items-center justify-center text-xl mb-3`}>{icon}</div>
            <p className="text-2xl font-bold text-gray-900">{value}</p>
            <p className="text-sm text-gray-500 mt-1">{label}</p>
          </div>
        ))}
      </div>

      {/* Assigned cameras */}
      {cameras.length > 0 && (
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
          <h2 className="text-base font-bold text-gray-900 mb-3">My Assigned Cameras</h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            {cameras.map((c: any) => (
              <div key={c.id} className="flex items-center gap-3 p-3 bg-gray-50 rounded-xl border border-gray-100">
                <div className={`w-2.5 h-2.5 rounded-full flex-shrink-0 ${c.status === 'online' ? 'bg-green-400 animate-pulse' : 'bg-gray-300'}`} />
                <div>
                  <p className="font-medium text-gray-900 text-sm">{c.name}</p>
                  <p className="text-xs text-gray-400 capitalize">{c.location?.replace(/_/g, ' ')}</p>
                </div>
                <span className={`ml-auto text-xs px-2 py-0.5 rounded-full font-medium ${c.status === 'online' ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>{c.status}</span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Today's check-ins */}
      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
        <h2 className="text-base font-bold text-gray-900 mb-4">Today's Check-ins</h2>
        {today.length === 0 ? (
          <p className="text-gray-400 text-sm">No records yet today.</p>
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
                {today.slice(0, 20).map((r: any) => (
                  <tr key={r.id} className="hover:bg-gray-50">
                    <td className="py-3 font-medium text-gray-900">{r.student_id}</td>
                    <td className="py-3 text-gray-600 capitalize">{r.camera_location?.replace(/_/g, ' ')}</td>
                    <td className="py-3 text-gray-600">{new Date(r.timestamp).toLocaleTimeString()}</td>
                    <td className="py-3"><span className="bg-green-100 text-green-700 px-2 py-0.5 rounded-full text-xs">{(r.confidence_score * 100).toFixed(1)}%</span></td>
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
