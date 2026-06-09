'use client';
import { useEffect, useState } from 'react';
import { api } from '@/lib/api';
import { useAuth } from '../../context/AuthContext';
import AnalyticsDashboard from '../AnalyticsDashboard';

export default function AdminDashboard() {
  const { user } = useAuth();
  const [stats, setStats] = useState<any>(null);
  const [today, setToday] = useState<any[]>([]);
  const [grade, setGrade] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([
      api.getAttendanceStats(),
      api.getTodayAttendance(),
      api.getGradeSummary(),
    ]).then(([s, t, g]) => {
      setStats(s); setToday(t); setGrade(g);
    }).catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  if (loading) return (
    <div className="flex items-center justify-center min-h-screen">
      <div className="w-10 h-10 border-4 border-purple-500 border-t-transparent rounded-full animate-spin" />
    </div>
  );

  return (
    <div className="p-8 space-y-8">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Admin Dashboard</h1>
        <p className="text-gray-500 mt-1">Welcome back, {user?.name}</p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
        {[
          { label: 'Total Students', value: stats?.total_students ?? 0, icon: '👥', color: 'from-blue-500 to-blue-600' },
          { label: 'Present Today', value: stats?.present_students ?? 0, icon: '✅', color: 'from-green-500 to-green-600' },
          { label: 'Absent Today', value: stats?.absent_students ?? 0, icon: '❌', color: 'from-red-500 to-red-600' },
          { label: 'Attendance Rate', value: `${(stats?.attendance_percentage ?? 0).toFixed(1)}%`, icon: '📊', color: 'from-purple-500 to-purple-600' },
        ].map(({ label, value, icon, color }) => (
          <div key={label} className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
            <div className={`w-12 h-12 bg-gradient-to-br ${color} rounded-xl flex items-center justify-center text-2xl mb-4`}>{icon}</div>
            <p className="text-3xl font-bold text-gray-900">{value}</p>
            <p className="text-sm text-gray-500 mt-1">{label}</p>
          </div>
        ))}
      </div>

      {/* Analytics */}
      <AnalyticsDashboard />

      {/* Grade breakdown */}
      {grade?.grades?.length > 0 && (
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
          <h2 className="text-lg font-bold text-gray-900 mb-4">Attendance by Grade</h2>
          <div className="space-y-3">
            {grade.grades.map((g: any) => (
              <div key={g.grade} className="flex items-center gap-4">
                <span className="w-24 text-sm font-medium text-gray-700">{g.grade}</span>
                <div className="flex-1 bg-gray-100 rounded-full h-3 overflow-hidden">
                  <div className="h-full bg-gradient-to-r from-blue-500 to-purple-500 rounded-full transition-all"
                    style={{ width: `${g.rate}%` }} />
                </div>
                <span className="text-sm font-semibold text-gray-700 w-12 text-right">{g.rate}%</span>
                <span className="text-xs text-gray-400">{g.present}/{g.total}</span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Recent check-ins */}
      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
        <h2 className="text-lg font-bold text-gray-900 mb-4">Recent Check-ins Today</h2>
        {today.length === 0 ? (
          <p className="text-gray-400 text-sm">No attendance records yet today.</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="text-left text-gray-400 border-b border-gray-100">
                  {['Student', 'Location', 'Time', 'Confidence'].map(h => (
                    <th key={h} className="pb-3 font-medium">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {today.slice(0, 10).map((r: any) => (
                  <tr key={r.id} className="hover:bg-gray-50">
                    <td className="py-3 font-medium text-gray-900">{r.student_id}</td>
                    <td className="py-3 text-gray-600 capitalize">{r.camera_location?.replace(/_/g, ' ')}</td>
                    <td className="py-3 text-gray-600">{new Date(r.timestamp).toLocaleTimeString()}</td>
                    <td className="py-3">
                      <span className="bg-green-100 text-green-700 px-2 py-0.5 rounded-full text-xs font-medium">
                        {(r.confidence_score * 100).toFixed(1)}%
                      </span>
                    </td>
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
