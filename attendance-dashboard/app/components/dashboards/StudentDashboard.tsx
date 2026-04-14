'use client';
import { useEffect, useState } from 'react';
import { api } from '@/lib/api';
import { useAuth } from '../../context/AuthContext';

export default function StudentDashboard() {
  const { user } = useAuth();
  const [records, setRecords] = useState<any[]>([]);
  const [profile, setProfile] = useState<any>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(true);
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');

  const load = (start?: string, end?: string) => {
    setLoading(true);
    const params = new URLSearchParams();
    if (start) params.append('start_date', start);
    if (end) params.append('end_date', end);
    const qs = params.toString();
    api.request('GET', `/attendance/my${qs ? '?' + qs : ''}`)
      .then(setRecords).catch(e => setError(e.message)).finally(() => setLoading(false));
  };

  useEffect(() => {
    api.getMyStudentProfile().then(setProfile).catch(() => {});
    load();
  }, []);

  const daysPresent = new Set(records.map((r: any) => new Date(r.timestamp).toDateString())).size;

  return (
    <div className="p-8 space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">My Dashboard</h1>
        <p className="text-gray-500 mt-1">Welcome, {user?.name}</p>
      </div>

      {error && <div className="bg-red-50 border border-red-200 text-red-600 rounded-xl px-4 py-3 text-sm">{error}</div>}

      {profile && (
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5 flex items-center gap-4">
          <div className="w-14 h-14 bg-gradient-to-br from-green-500 to-teal-600 rounded-2xl flex items-center justify-center text-2xl">🎓</div>
          <div>
            <p className="text-lg font-bold text-gray-900">{profile.full_name}</p>
            <p className="text-gray-500 text-sm">{profile.grade_level}{profile.section ? ` • Section ${profile.section}` : ''}</p>
            <p className="text-xs text-gray-400">ID: {profile.student_id}</p>
          </div>
        </div>
      )}

      <div className="grid grid-cols-2 gap-4">
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
          <div className="w-10 h-10 bg-gradient-to-br from-green-500 to-teal-600 rounded-xl flex items-center justify-center text-xl mb-3">📅</div>
          <p className="text-3xl font-bold text-gray-900">{daysPresent}</p>
          <p className="text-sm text-gray-500 mt-1">Days Present</p>
        </div>
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
          <div className="w-10 h-10 bg-gradient-to-br from-blue-500 to-blue-600 rounded-xl flex items-center justify-center text-xl mb-3">🕐</div>
          <p className="text-3xl font-bold text-gray-900">{records.length}</p>
          <p className="text-sm text-gray-500 mt-1">Total Check-ins</p>
        </div>
      </div>

      {/* Date filter */}
      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
        <h2 className="text-base font-bold text-gray-900 mb-3">Attendance History</h2>
        <div className="flex flex-wrap gap-3 mb-4">
          <div>
            <label className="block text-xs text-gray-500 mb-1">From</label>
            <input type="date" value={startDate} onChange={e => setStartDate(e.target.value)}
              className="border border-gray-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:border-blue-500" />
          </div>
          <div>
            <label className="block text-xs text-gray-500 mb-1">To</label>
            <input type="date" value={endDate} onChange={e => setEndDate(e.target.value)}
              className="border border-gray-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:border-blue-500" />
          </div>
          <div className="flex items-end gap-2">
            <button onClick={() => load(startDate, endDate)}
              className="px-4 py-2 bg-gradient-to-r from-blue-600 to-purple-600 text-white rounded-xl text-sm font-semibold hover:opacity-90 transition">
              Filter
            </button>
            <button onClick={() => { setStartDate(''); setEndDate(''); load(); }}
              className="px-4 py-2 border border-gray-200 text-gray-600 rounded-xl text-sm hover:bg-gray-50 transition">
              Clear
            </button>
          </div>
        </div>

        {loading ? (
          <div className="flex justify-center py-8"><div className="w-6 h-6 border-4 border-blue-500 border-t-transparent rounded-full animate-spin" /></div>
        ) : records.length === 0 ? (
          <p className="text-gray-400 text-sm text-center py-6">No attendance records for this period.</p>
        ) : (
          <div className="space-y-2 max-h-96 overflow-y-auto">
            {records.map((r: any) => (
              <div key={r.id} className="flex items-center justify-between py-2.5 border-b border-gray-50 last:border-0">
                <div>
                  <p className="text-sm font-medium text-gray-900">
                    {new Date(r.timestamp).toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric', year: 'numeric' })}
                  </p>
                  <p className="text-xs text-gray-400 capitalize">{r.camera_location?.replace(/_/g, ' ')}</p>
                </div>
                <div className="text-right">
                  <p className="text-sm text-gray-600">{new Date(r.timestamp).toLocaleTimeString()}</p>
                  <span className="text-xs bg-green-100 text-green-700 px-2 py-0.5 rounded-full">Present</span>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
