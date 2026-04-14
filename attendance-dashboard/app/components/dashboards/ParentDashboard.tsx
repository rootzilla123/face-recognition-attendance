'use client';
import { useEffect, useState } from 'react';
import { api } from '@/lib/api';
import { useAuth } from '../../context/AuthContext';

export default function ParentDashboard() {
  const { user } = useAuth();
  const [children, setChildren] = useState<any[]>([]);
  const [selected, setSelected] = useState<string | null>(null);
  const [attendance, setAttendance] = useState<any>(null);
  const [fees, setFees] = useState<any>(null);
  const [linkId, setLinkId] = useState('');
  const [linkError, setLinkError] = useState('');
  const [linking, setLinking] = useState(false);

  useEffect(() => {
    api.getMyChildren().then(setChildren).catch(console.error);
  }, []);

  const loadAttendance = async (student_id: string) => {
    setSelected(student_id);
    setAttendance(null); setFees(null);
    const [att, f] = await Promise.all([
      api.getChildAttendance(student_id).catch(() => null),
      api.getChildFees(student_id).catch(() => null),
    ]);
    setAttendance(att);
    setFees(f);
  };

  const handleLink = async (e: React.FormEvent) => {
    e.preventDefault();
    setLinkError(''); setLinking(true);
    try {
      await api.linkChild(linkId);
      const updated = await api.getMyChildren();
      setChildren(updated); setLinkId('');
    } catch (err: any) {
      setLinkError(err.message);
    } finally { setLinking(false); }
  };

  return (
    <div className="p-8 space-y-8">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Parent Dashboard</h1>
        <p className="text-gray-500 mt-1">Welcome, {user?.name}</p>
      </div>

      {/* Link child */}
      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
        <h2 className="text-lg font-bold text-gray-900 mb-4">Link a Child</h2>
        <form onSubmit={handleLink} className="flex gap-3">
          <input value={linkId} onChange={e => setLinkId(e.target.value)} required
            placeholder="Enter Student ID (e.g. STU2024001)"
            className="flex-1 border border-gray-200 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:border-blue-500" />
          <button type="submit" disabled={linking}
            className="px-5 py-2.5 bg-gradient-to-r from-blue-600 to-purple-600 text-white rounded-xl text-sm font-semibold hover:opacity-90 disabled:opacity-50 transition">
            {linking ? 'Linking...' : 'Link Child'}
          </button>
        </form>
        {linkError && <p className="text-red-500 text-sm mt-2">{linkError}</p>}
      </div>

      {/* Children list */}
      {children.length === 0 && !linking && (
        <div className="bg-blue-50 border border-blue-200 rounded-2xl p-6 text-center">
          <p className="text-3xl mb-2">👨‍👧</p>
          <p className="font-semibold text-gray-900 mb-1">No children linked yet</p>
          <p className="text-sm text-gray-500">Enter your child's Student ID above to link their account and track attendance.</p>
        </div>
      )}
      {children.length > 0 && (
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
          <h2 className="text-lg font-bold text-gray-900 mb-4">My Children</h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            {children.map((c: any) => (
              <button key={c.student_id} onClick={() => loadAttendance(c.student_id)}
                className={`text-left p-4 rounded-xl border-2 transition ${selected === c.student_id ? 'border-blue-500 bg-blue-50' : 'border-gray-100 hover:border-gray-200'}`}>
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-gradient-to-br from-orange-500 to-amber-600 rounded-xl flex items-center justify-center text-white font-bold">
                    {c.full_name[0]}
                  </div>
                  <div>
                    <p className="font-semibold text-gray-900">{c.full_name}</p>
                    <p className="text-xs text-gray-400">{c.grade_level} {c.section ? `• ${c.section}` : ''}</p>
                  </div>
                </div>
              </button>
            ))}
          </div>
        </div>
      )}

      {/* Fees section */}
      {fees && (
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-bold text-gray-900">Fee Balance</h2>
            <span className="text-sm font-semibold text-blue-600 bg-blue-50 px-3 py-1 rounded-full">
              Owed: ${(fees.total_owed as number).toFixed(2)}
            </span>
          </div>
          {fees.fees.length === 0 ? (
            <p className="text-gray-400 text-sm">No fee records.</p>
          ) : (
            <div className="space-y-2">
              {fees.fees.map((f: any) => (
                <div key={f.id} className="flex items-center justify-between py-2 border-b border-gray-50 last:border-0">
                  <div className="flex items-center gap-3">
                    <span className={`text-lg ${f.is_paid ? '✅' : '⏳'}`}>{f.is_paid ? '✅' : '⏳'}</span>
                    <div>
                      <p className="text-sm font-medium text-gray-900">{f.fee_type}</p>
                      <p className="text-xs text-gray-400">
                        {f.term}{f.due_date ? ` • Due: ${f.due_date.substring(0, 10)}` : ''}
                      </p>
                    </div>
                  </div>
                  <span className={`text-sm font-semibold ${f.is_paid ? 'text-green-600' : 'text-orange-500'}`}>
                    ${(f.amount as number).toFixed(2)}
                  </span>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* Child attendance */}
      {attendance && (
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
          <h2 className="text-lg font-bold text-gray-900 mb-4">
            {attendance.student.full_name}'s Attendance
          </h2>
          {attendance.attendance.length === 0 ? (
            <p className="text-gray-400 text-sm">No records yet.</p>
          ) : (
            <div className="space-y-2">
              {attendance.attendance.slice(0, 20).map((r: any) => (
                <div key={r.id} className="flex items-center justify-between py-2 border-b border-gray-50 last:border-0">
                  <div>
                    <p className="text-sm font-medium text-gray-900">{new Date(r.timestamp).toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' })}</p>
                    <p className="text-xs text-gray-400 capitalize">{r.camera_location?.replace(/_/g, ' ')}</p>
                  </div>
                  <span className="text-sm text-gray-600">{new Date(r.timestamp).toLocaleTimeString()}</span>
                </div>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
