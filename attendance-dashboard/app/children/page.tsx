'use client';
import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { api } from '@/lib/api';
import { useAuth } from '../context/AuthContext';
import RouteGuard from '../components/RouteGuard';
import ConsolidatedReport from '../marks/ConsolidatedReport';

function ChildrenContent() {
  const { user } = useAuth();
  const [children, setChildren] = useState<any[]>([]);
  const [selected, setSelected] = useState<string | null>(null);
  const [attendance, setAttendance] = useState<any>(null);
  const [fees, setFees] = useState<any>(null);
  const [marks, setMarks] = useState<any[]>([]);
  // Consolidated report state
  const [consolidatedData, setConsolidatedData] = useState<any>(null);
  const [showConsolidated, setShowConsolidated] = useState(false);

  const [linkId, setLinkId] = useState('');
  const [linkError, setLinkError] = useState('');
  const [linking, setLinking] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.getMyChildren().then(setChildren).catch(console.error).finally(() => setLoading(false));
  }, []);

  const loadDetails = async (student_id: string) => {
    setSelected(student_id);
    setAttendance(null); setFees(null); setMarks([]); setConsolidatedData(null);
    const [att, f, m] = await Promise.all([
      api.getChildAttendance(student_id).catch(() => null),
      api.getChildFees(student_id).catch(() => null),
      api.getChildMarks(student_id).catch(() => []),
    ]);
    setAttendance(att);
    setFees(f);
    setMarks(m);
    
    if (m.length > 0) {
       api.getConsolidatedReport(student_id, 'Term 1 2026')
          .then(setConsolidatedData)
          .catch(() => {});
    }
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

  const handleUnlink = async (studentId: string) => {
    if (!confirm('Unlink this child from your account?')) return;
    try {
      await api.delete(`/parent/children/${studentId}/unlink`);
      setChildren(prev => prev.filter(c => c.student_id !== studentId));
      if (selected === studentId) { setSelected(null); setAttendance(null); setFees(null); }
    } catch (err: any) {
      alert(err.message || 'Failed to unlink');
    }
  };

  return (
    <div className="p-8 space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">My Children</h1>
        <p className="text-gray-500 mt-1">View attendance records and fee balances for your children</p>
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
      {loading ? (
        <div className="flex justify-center py-12"><div className="w-8 h-8 border-4 border-orange-500 border-t-transparent rounded-full animate-spin" /></div>
      ) : children.length === 0 ? (
        <div className="bg-orange-50 border border-orange-200 rounded-2xl p-8 text-center">
          <p className="text-4xl mb-3">👨‍👧</p>
          <p className="font-semibold text-gray-900 mb-1">No children linked yet</p>
          <p className="text-sm text-gray-500">Enter your child&apos;s Student ID above to link their account.</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Children cards */}
          <div className="space-y-3">
            <p className="text-xs font-semibold text-gray-500 uppercase tracking-wider">Your Children</p>
            {children.map((c: any) => (
              <div key={c.student_id}
                className={`p-4 rounded-xl border-2 transition cursor-pointer ${selected === c.student_id ? 'border-orange-500 bg-orange-50' : 'border-gray-100 hover:border-gray-200 bg-white'}`}>
                <div className="flex items-center gap-3" onClick={() => loadDetails(c.student_id)}>
                  <div className="w-10 h-10 bg-gradient-to-br from-orange-500 to-amber-600 rounded-xl flex items-center justify-center text-white font-bold flex-shrink-0">
                    {c.full_name?.[0] || '?'}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="font-semibold text-gray-900 truncate">{c.full_name}</p>
                    <p className="text-xs text-gray-400">{c.student_id} • {c.grade_level}{c.section ? ` • ${c.section}` : ''}</p>
                  </div>
                  <button onClick={(e) => { e.stopPropagation(); handleUnlink(c.student_id); }}
                    className="text-xs text-red-400 hover:text-red-600 p-1" title="Unlink child">
                    ✕
                  </button>
                </div>
              </div>
            ))}
          </div>

          {/* Detail panel */}
          <div className="lg:col-span-2 space-y-4">
            {!selected ? (
              <div className="bg-white rounded-2xl border border-gray-100 p-12 text-center text-gray-400">
                <p className="text-3xl mb-2">👈</p>
                <p>Select a child to view details</p>
              </div>
            ) : (
              <>
                {/* Fees */}
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
                              <span className="text-lg">{f.is_paid ? '✅' : '⏳'}</span>
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

                {/* Examination Marks */}
                <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
                  <div className="flex items-center justify-between mb-4">
                    <h2 className="text-lg font-bold text-gray-900">Examination Results</h2>
                    {consolidatedData && (
                       <button 
                          onClick={() => setShowConsolidated(true)}
                          className="text-xs font-bold text-blue-600 bg-blue-50 px-3 py-1 rounded-full hover:bg-blue-100 transition"
                       >
                          View Full Report Card
                       </button>
                    )}
                  </div>
                  {marks.length === 0 ? (
                    <p className="text-gray-400 text-sm">No examination marks published yet.</p>
                  ) : (
                    <div className="space-y-4">
                      {marks.map((m: any) => (
                        <div key={m.id} className="p-4 rounded-xl border border-gray-100 bg-gray-50/30">
                          <div className="flex justify-between items-start mb-2">
                            <div>
                              <p className="font-bold text-gray-900">{m.subject}</p>
                              <p className="text-xs text-gray-500 uppercase tracking-wider font-semibold">{m.term}</p>
                            </div>
                            <div className="text-right">
                              <p className="font-bold text-blue-600">{m.score} / {m.max_score}</p>
                              <p className="text-xs font-bold text-gray-400">{m.percentage}% • Grade: {m.grade || '—'}</p>
                            </div>
                          </div>
                          {m.remarks && (
                            <p className="text-xs text-gray-600 italic border-t border-gray-100 pt-2 mt-2">
                              &ldquo;{m.remarks}&rdquo;
                            </p>
                          )}
                        </div>
                      ))}
                    </div>
                  )}
                </div>

                {/* Attendance */}
                {attendance && (
                  <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
                    <h2 className="text-lg font-bold text-gray-900 mb-4">
                      {attendance.student?.full_name || 'Child'}&apos;s Attendance
                    </h2>
                    {attendance.attendance?.length === 0 ? (
                      <p className="text-gray-400 text-sm">No records yet.</p>
                    ) : (
                      <div className="space-y-2 max-h-96 overflow-y-auto">
                        {attendance.attendance?.slice(0, 30).map((r: any) => (
                          <div key={r.id} className="flex items-center justify-between py-2 border-b border-gray-50 last:border-0">
                            <div>
                              <p className="text-sm font-medium text-gray-900">
                                {new Date(r.timestamp).toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' })}
                              </p>
                              <p className="text-xs text-gray-400 capitalize">{r.camera_location?.replace(/_/g, ' ')}</p>
                            </div>
                            <span className="text-sm text-gray-600">{new Date(r.timestamp).toLocaleTimeString()}</span>
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                )}

                {!attendance && !fees && (
                  <div className="bg-white rounded-2xl border border-gray-100 p-8 text-center">
                    <div className="w-8 h-8 border-4 border-orange-500 border-t-transparent rounded-full animate-spin mx-auto" />
                    <p className="text-sm text-gray-400 mt-3">Loading details...</p>
                  </div>
                )}
              </>
            )}
          </div>
        </div>
      )}

      {/* Consolidated Report Modal */}
      {showConsolidated && consolidatedData && (
         <ConsolidatedModal data={consolidatedData} onClose={() => setShowConsolidated(false)} />
      )}
    </div>
  );
}

export default function ChildrenPage() {
  return <RouteGuard allowedRoles={['parent']}><ChildrenContent /></RouteGuard>;
}

// Separate component for the modal to avoid layout shift
function ConsolidatedModal({ data, onClose }: { data: any, onClose: () => void }) {
  return (
    <div className="fixed inset-0 z-[100] bg-black/60 backdrop-blur-md flex items-center justify-center p-4 overflow-y-auto print:p-0 print:bg-white print:backdrop-none">
      <div className="relative w-full max-w-4xl print:max-w-none">
        <button 
          onClick={onClose}
          className="absolute -top-12 right-0 text-white hover:text-blue-400 font-bold flex items-center gap-2 print:hidden"
        >
          <span>✕</span> Close Preview
        </button>
        <div className="bg-white rounded-3xl overflow-hidden shadow-2xl print:rounded-none print:shadow-none">
          <div className="p-4 bg-gray-50 border-b border-gray-100 flex justify-between items-center print:hidden">
            <p className="text-sm font-bold text-gray-500">Official Report Preview</p>
            <button 
              onClick={() => window.print()}
              className="bg-blue-600 text-white px-4 py-1.5 rounded-xl text-xs font-bold shadow-lg shadow-blue-200"
            >
              🖨️ Print Now
            </button>
          </div>
          <ConsolidatedReport 
            studentName={data.student_name}
            studentId={data.student_id}
            term={data.term}
            marks={data.marks}
            totalScore={data.total_score}
            totalMax={data.total_max}
            overallPercentage={data.overall_percentage}
            overallGrade={data.overall_grade}
          />
        </div>
      </div>
    </div>
  );
}
