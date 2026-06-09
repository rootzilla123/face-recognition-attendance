'use client';
import { useEffect, useState } from 'react';
import RouteGuard from '../components/RouteGuard';
import { getToken } from '@/lib/auth';

const API = typeof window !== 'undefined'
  ? `${window.location.protocol}//${window.location.hostname}:8001`
  : 'http://localhost:8001';

function AdminUsersPage() {
  const [users, setUsers] = useState<any[]>([]);
  const [teachers, setTeachers] = useState<any[]>([]);
  const [cameras, setCameras] = useState<any[]>([]);
  const [tab, setTab] = useState<'users' | 'cameras' | 'enrollment' | 'fees' | 'settings' | 'audit'>('users');
  const [sysSettings, setSysSettings] = useState<any>(null);
  const [auditLogs, setAuditLogs] = useState<any[]>([]);
  const [savingSettings, setSavingSettings] = useState(false);
  const [enrollment, setEnrollment] = useState<any>(null);
  const [students, setStudents] = useState<any[]>([]);
  const [selectedStudent, setSelectedStudent] = useState<any>(null);
  const [studentFees, setStudentFees] = useState<any[]>([]);
  const [feeForm, setFeeForm] = useState({ fee_type: '', amount: '', due_date: '', term: '', notes: '', is_paid: false });
  const [editingFee, setEditingFee] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({ email: '', password: '', full_name: '', employee_id: '', department: '', class_name: '', phone: '' });
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [assigningTeacher, setAssigningTeacher] = useState<any>(null);
  const [selectedCams, setSelectedCams] = useState<number[]>([]);

  const set = (k: string, v: string) => setForm(f => ({ ...f, [k]: v }));
  const auth = () => ({ headers: { Authorization: `Bearer ${getToken()}` } });

  useEffect(() => { loadAll(); }, []);

  const loadEnrollment = async () => {
    const data = await fetch(`${API}/api/v1/admin/students/enrollment-status`, auth()).then(r => r.ok ? r.json() : null);
    setEnrollment(data);
  };

  const loadAll = async () => {
    setLoading(true);
    const [u, t, c, e, s] = await Promise.all([
      fetch(`${API}/api/v1/admin/users`, auth()).then(r => r.ok ? r.json() : []),
      fetch(`${API}/api/v1/admin/teachers`, auth()).then(r => r.ok ? r.json() : []),
      fetch(`${API}/api/v1/cameras`, auth()).then(r => r.ok ? r.json() : []),
      fetch(`${API}/api/v1/admin/students/enrollment-status`, auth()).then(r => r.ok ? r.json() : []),
      fetch(`${API}/api/v1/students`, auth()).then(r => r.ok ? r.json() : []),
    ]);
    setUsers(u); setTeachers(t); setCameras(c); setEnrollment(e); setStudents(s);
    // Load system settings and audit logs
    const [ss, al] = await Promise.all([
      fetch(`${API}/api/v1/admin/system-settings`, auth()).then(r => r.ok ? r.json() : null),
      fetch(`${API}/api/v1/admin/audit-logs?limit=50`, auth()).then(r => r.ok ? r.json() : []),
    ]);
    setSysSettings(ss);
    setAuditLogs(al);
    setLoading(false);
  };

  const loadStudentFees = async (studentId: string) => {
    const data = await fetch(`${API}/api/v1/admin/students/${studentId}/fees`, auth()).then(r => r.ok ? r.json() : []);
    setStudentFees(data);
  };

  const saveFee = async (e: React.FormEvent) => {
    e.preventDefault();
    const payload = { ...feeForm, amount: parseFloat(feeForm.amount) };
    if (editingFee) {
      await fetch(`${API}/api/v1/admin/fees/${editingFee.id}`, { method: 'PATCH', headers: { 'Content-Type': 'application/json', ...auth().headers }, body: JSON.stringify(payload) });
    } else {
      await fetch(`${API}/api/v1/admin/students/${selectedStudent.student_id}/fees`, { method: 'POST', headers: { 'Content-Type': 'application/json', ...auth().headers }, body: JSON.stringify(payload) });
    }
    setFeeForm({ fee_type: '', amount: '', due_date: '', term: '', notes: '', is_paid: false });
    setEditingFee(null);
    loadStudentFees(selectedStudent.student_id);
  };

  const deleteFee = async (feeId: string) => {
    if (!confirm('Delete this fee?')) return;
    await fetch(`${API}/api/v1/admin/fees/${feeId}`, { method: 'DELETE', ...auth() });
    loadStudentFees(selectedStudent.student_id);
  };

  const startEdit = (fee: any) => {
    setEditingFee(fee);
    setFeeForm({ fee_type: fee.fee_type, amount: String(fee.amount), due_date: fee.due_date?.substring(0, 10) || '', term: fee.term || '', notes: fee.notes || '', is_paid: fee.is_paid });
  };

  const createTeacher = async (e: React.FormEvent) => {
    e.preventDefault(); setError(''); setSaving(true);
    try {
      const res = await fetch(`${API}/api/v1/auth/register/teacher`, {
        method: 'POST', headers: { 'Content-Type': 'application/json', ...auth().headers },
        body: JSON.stringify(form),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.detail || 'Failed');
      setSuccess(`Teacher ${form.full_name} created`);
      setShowForm(false);
      setForm({ email: '', password: '', full_name: '', employee_id: '', department: '', class_name: '', phone: '' });
      loadAll();
    } catch (err: any) { setError(err.message); }
    finally { setSaving(false); }
  };


  const resetPassword = async (userId: string, email: string) => {
    if (!confirm(`Send password reset email to ${email}?`)) return;
    try {
      await fetch(`${API}/api/v1/auth/reset-password`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', ...auth().headers },
        body: JSON.stringify({ email }),
      });
      setSuccess(`Reset email sent to ${email}`);
    } catch { setError('Failed to send reset email'); }
  };

  const toggleUser = async (userId: string, isActive: boolean, name: string) => {
    if (isActive && !confirm(`Deactivate ${name}? They will lose access immediately.`)) return;
    await fetch(`${API}/api/v1/admin/users/${userId}/toggle`, { method: "POST", ...auth() });
    setUsers(prev => prev.map(u => u.id === userId ? { ...u, is_active: !isActive } : u));
  };

  const openAssign = (teacher: any) => {
    setAssigningTeacher(teacher);
    setSelectedCams(teacher.assigned_camera_ids || []);
  };

  const saveAssignment = async () => {
    await fetch(`${API}/api/v1/admin/teachers/${assigningTeacher.id}/cameras`, {
      method: 'PUT', headers: { 'Content-Type': 'application/json', ...auth().headers },
      body: JSON.stringify({ camera_ids: selectedCams }),
    });
    setAssigningTeacher(null);
    setSuccess(`Cameras assigned to ${assigningTeacher.full_name}`);
    loadAll();
  };

  const toggleCam = (id: number) => setSelectedCams(prev => prev.includes(id) ? prev.filter(x => x !== id) : [...prev, id]);

  const roleColor: Record<string, string> = { admin: 'bg-purple-100 text-purple-700', teacher: 'bg-blue-100 text-blue-700', student: 'bg-green-100 text-green-700', parent: 'bg-orange-100 text-orange-700' };
  const inputCls = "w-full border border-gray-200 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:border-blue-500";

  return (
    <div className="p-8 space-y-6">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div><h1 className="text-3xl font-bold text-gray-900">Admin Panel</h1><p className="text-gray-500 mt-1">Manage users and camera assignments</p></div>
        {tab === 'users' && <button onClick={() => setShowForm(!showForm)} className="px-5 py-2.5 bg-gradient-to-r from-purple-600 to-pink-600 text-white rounded-xl text-sm font-semibold hover:opacity-90 transition">{showForm ? 'Cancel' : '+ Add Teacher'}</button>}
      </div>

      {/* Tabs */}
      <div className="flex flex-wrap gap-2 bg-gray-100 p-1 rounded-xl w-fit">
        {(['users', 'cameras', 'enrollment', 'fees', 'settings', 'audit'] as const).map(t => (
          <button key={t} onClick={() => { setTab(t); if (t === 'enrollment') loadEnrollment(); }} className={`px-4 py-2 rounded-lg text-sm font-semibold capitalize transition ${tab === t ? 'bg-white shadow text-gray-900' : 'text-gray-500 hover:text-gray-700'}`}>
            {t === 'users' ? '👥 Users' : t === 'cameras' ? '📹 Cameras' : t === 'enrollment' ? '🎭 Enrollment' : t === 'fees' ? '💰 Fees' : t === 'settings' ? '⚙️ Settings' : '📋 Audit Log'}
          </button>
        ))}
      </div>

      {success && <div className="bg-green-50 border border-green-200 text-green-700 rounded-xl px-4 py-3 text-sm">{success}</div>}

      {/* Create teacher form */}
      {tab === 'users' && showForm && (
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
          <h2 className="text-lg font-bold text-gray-900 mb-4">Create Teacher Account</h2>
          {error && <div className="bg-red-50 text-red-600 rounded-xl px-4 py-3 mb-4 text-sm">{error}</div>}
          <form onSubmit={createTeacher} className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div><label className="block text-xs text-gray-500 mb-1">Full Name</label><input required value={form.full_name} onChange={e => set('full_name', e.target.value)} className={inputCls} placeholder="Jane Smith" /></div>
            <div><label className="block text-xs text-gray-500 mb-1">Email</label><input type="email" required value={form.email} onChange={e => set('email', e.target.value)} className={inputCls} placeholder="teacher@school.com" /></div>
            <div><label className="block text-xs text-gray-500 mb-1">Password</label><input type="password" required minLength={6} value={form.password} onChange={e => set('password', e.target.value)} className={inputCls} placeholder="••••••••" /></div>
            <div><label className="block text-xs text-gray-500 mb-1">Employee ID</label><input required value={form.employee_id} onChange={e => set('employee_id', e.target.value)} className={inputCls} placeholder="EMP001" /></div>
            <div><label className="block text-xs text-gray-500 mb-1">Department</label><input value={form.department} onChange={e => set('department', e.target.value)} className={inputCls} placeholder="Mathematics" /></div>
            <div><label className="block text-xs text-gray-500 mb-1">Class Name</label><input value={form.class_name} onChange={e => set('class_name', e.target.value)} className={inputCls} placeholder="Grade 10 - Section A" /></div>
            <div className="sm:col-span-2"><button type="submit" disabled={saving} className="px-6 py-2.5 bg-gradient-to-r from-blue-600 to-purple-600 text-white rounded-xl text-sm font-semibold hover:opacity-90 disabled:opacity-50 transition">{saving ? 'Creating...' : 'Create Teacher'}</button></div>
          </form>
        </div>
      )}

      {loading ? <div className="flex justify-center py-12"><div className="w-8 h-8 border-4 border-purple-500 border-t-transparent rounded-full animate-spin" /></div> : (
        <>
          {/* Users table */}
          {tab === 'users' && (
            <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
              <table className="w-full text-sm">
                <thead className="bg-gray-50 border-b border-gray-100">
                  <tr>{['Name', 'Email', 'Role', 'Status', 'Joined', 'Action'].map(h => <th key={h} className="text-left px-6 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">{h}</th>)}</tr>
                </thead>
                <tbody className="divide-y divide-gray-50">
                  {users.map((u: any) => (
                    <tr key={u.id} className="hover:bg-gray-50">
                      <td className="px-6 py-4 font-medium text-gray-900">{u.full_name}</td>
                      <td className="px-6 py-4 text-gray-600">{u.email}</td>
                      <td className="px-6 py-4"><span className={`px-2.5 py-1 rounded-full text-xs font-semibold capitalize ${roleColor[u.role] || 'bg-gray-100 text-gray-600'}`}>{u.role}</span></td>
                      <td className="px-6 py-4"><span className={`px-2.5 py-1 rounded-full text-xs font-semibold ${u.is_active ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-600'}`}>{u.is_active ? 'Active' : 'Inactive'}</span></td>
                      <td className="px-6 py-4 text-gray-500">{new Date(u.created_at).toLocaleDateString()}</td>
                      <td className="px-6 py-4"><button onClick={() => resetPassword(u.id, u.email)} className="text-xs font-semibold px-3 py-1.5 rounded-lg bg-blue-50 text-blue-600 hover:bg-blue-100 transition mr-2">Reset PW</button>
                      <button onClick={() => toggleUser(u.id, u.is_active, u.full_name)} className={`text-xs font-semibold px-3 py-1.5 rounded-lg transition ${u.is_active ? 'bg-red-50 text-red-600 hover:bg-red-100' : 'bg-green-50 text-green-600 hover:bg-green-100'}`}>{u.is_active ? 'Deactivate' : 'Activate'}</button></td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}

          {/* Face enrollment status */}
          {tab === 'enrollment' && (
            <div className="space-y-4">
              {!enrollment ? (
                <div className="flex justify-center py-12"><div className="w-8 h-8 border-4 border-purple-500 border-t-transparent rounded-full animate-spin" /></div>
              ) : (
                <>
                  <div className="grid grid-cols-3 gap-4">
                    {[
                      { label: 'Total Students', value: enrollment.total, color: 'from-blue-500 to-blue-600' },
                      { label: 'Face Enrolled', value: enrollment.enrolled, color: 'from-green-500 to-green-600' },
                      { label: 'Not Enrolled', value: enrollment.not_enrolled, color: 'from-red-500 to-red-600' },
                    ].map(({ label, value, color }) => (
                      <div key={label} className="bg-white rounded-2xl border border-gray-100 p-5">
                        <div className={`w-10 h-10 bg-gradient-to-br ${color} rounded-xl flex items-center justify-center text-white text-lg mb-3`}>
                          {label === 'Face Enrolled' ? '✅' : label === 'Not Enrolled' ? '❌' : '👥'}
                        </div>
                        <p className="text-2xl font-bold text-gray-900">{value}</p>
                        <p className="text-xs text-gray-500 mt-1">{label}</p>
                      </div>
                    ))}
                  </div>
                  <div className="bg-white rounded-2xl border border-gray-100 overflow-hidden">
                    <table className="w-full text-sm">
                      <thead className="bg-gray-50 border-b border-gray-100">
                        <tr>{['Student ID','Name','Grade','Section','Face Status'].map(h => (
                          <th key={h} className="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase">{h}</th>
                        ))}</tr>
                      </thead>
                      <tbody className="divide-y divide-gray-50">
                        {enrollment.students.map((s: any) => (
                          <tr key={s.student_id} className="hover:bg-gray-50">
                            <td className="px-5 py-3 font-mono text-xs text-gray-600">{s.student_id}</td>
                            <td className="px-5 py-3 font-medium text-gray-900">{s.full_name}</td>
                            <td className="px-5 py-3 text-gray-600">{s.grade_level}</td>
                            <td className="px-5 py-3 text-gray-600">{s.section || '—'}</td>
                            <td className="px-5 py-3">
                              <span className={`px-2.5 py-1 rounded-full text-xs font-semibold ${s.face_enrolled ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-600'}`}>
                                {s.face_enrolled ? '✅ Enrolled' : '❌ Not enrolled'}
                              </span>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </>
              )}
            </div>
          )}

          {/* Fees management */}
          {tab === 'fees' && (
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
              {/* Student list */}
              <div className="bg-white rounded-2xl border border-gray-100 p-4 space-y-2 max-h-[600px] overflow-y-auto">
                <p className="text-xs font-semibold text-gray-500 uppercase mb-3">Select Student</p>
                {students.map((s: any) => (
                  <button key={s.id} onClick={() => { setSelectedStudent(s); loadStudentFees(s.student_id); setEditingFee(null); setFeeForm({ fee_type: '', amount: '', due_date: '', term: '', notes: '', is_paid: false }); }}
                    className={`w-full text-left px-4 py-3 rounded-xl text-sm transition ${selectedStudent?.id === s.id ? 'bg-blue-50 border border-blue-200' : 'hover:bg-gray-50 border border-transparent'}`}>
                    <p className="font-semibold text-gray-900">{s.full_name}</p>
                    <p className="text-xs text-gray-400">{s.student_id} • {s.grade_level}</p>
                  </button>
                ))}
              </div>

              {/* Fees panel */}
              <div className="lg:col-span-2 space-y-4">
                {!selectedStudent ? (
                  <div className="bg-white rounded-2xl border border-gray-100 p-12 text-center text-gray-400">Select a student to manage fees</div>
                ) : (
                  <>
                    <div className="bg-white rounded-2xl border border-gray-100 p-5">
                      <h3 className="font-bold text-gray-900 mb-4">{editingFee ? 'Edit Fee' : 'Add Fee'} — {selectedStudent.full_name}</h3>
                      <form onSubmit={saveFee} className="grid grid-cols-2 gap-3">
                        <div><label className="block text-xs text-gray-500 mb-1">Fee Type</label><input required value={feeForm.fee_type} onChange={e => setFeeForm(f => ({ ...f, fee_type: e.target.value }))} className={inputCls} placeholder="Tuition, Transport…" /></div>
                        <div><label className="block text-xs text-gray-500 mb-1">Amount ($)</label><input required type="number" step="0.01" value={feeForm.amount} onChange={e => setFeeForm(f => ({ ...f, amount: e.target.value }))} className={inputCls} placeholder="0.00" /></div>
                        <div><label className="block text-xs text-gray-500 mb-1">Due Date</label><input type="date" value={feeForm.due_date} onChange={e => setFeeForm(f => ({ ...f, due_date: e.target.value }))} className={inputCls} /></div>
                        <div><label className="block text-xs text-gray-500 mb-1">Term</label><input value={feeForm.term} onChange={e => setFeeForm(f => ({ ...f, term: e.target.value }))} className={inputCls} placeholder="Term 1 2026" /></div>
                        <div className="col-span-2"><label className="block text-xs text-gray-500 mb-1">Notes</label><input value={feeForm.notes} onChange={e => setFeeForm(f => ({ ...f, notes: e.target.value }))} className={inputCls} /></div>
                        <div className="col-span-2 flex items-center gap-3">
                          <label className="flex items-center gap-2 text-sm text-gray-700 cursor-pointer">
                            <input type="checkbox" checked={feeForm.is_paid} onChange={e => setFeeForm(f => ({ ...f, is_paid: e.target.checked }))} className="w-4 h-4 accent-green-600" /> Mark as Paid
                          </label>
                          <button type="submit" className="ml-auto px-5 py-2 bg-gradient-to-r from-blue-600 to-purple-600 text-white rounded-xl text-sm font-semibold hover:opacity-90 transition">{editingFee ? 'Update' : 'Add Fee'}</button>
                          {editingFee && <button type="button" onClick={() => { setEditingFee(null); setFeeForm({ fee_type: '', amount: '', due_date: '', term: '', notes: '', is_paid: false }); }} className="px-4 py-2 border border-gray-200 text-gray-600 rounded-xl text-sm hover:bg-gray-50 transition">Cancel</button>}
                        </div>
                      </form>
                    </div>

                    <div className="bg-white rounded-2xl border border-gray-100 overflow-hidden">
                      {studentFees.length === 0 ? (
                        <p className="text-center text-gray-400 text-sm py-8">No fees added yet</p>
                      ) : (
                        <table className="w-full text-sm">
                          <thead className="bg-gray-50 border-b border-gray-100">
                            <tr>{['Type', 'Amount', 'Due', 'Term', 'Status', ''].map(h => <th key={h} className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase">{h}</th>)}</tr>
                          </thead>
                          <tbody className="divide-y divide-gray-50">
                            {studentFees.map((f: any) => (
                              <tr key={f.id} className="hover:bg-gray-50">
                                <td className="px-4 py-3 font-medium text-gray-900">{f.fee_type}</td>
                                <td className="px-4 py-3 font-semibold">${Number(f.amount).toFixed(2)}</td>
                                <td className="px-4 py-3 text-gray-500">{f.due_date?.substring(0, 10) || '—'}</td>
                                <td className="px-4 py-3 text-gray-500">{f.term || '—'}</td>
                                <td className="px-4 py-3"><span className={`px-2.5 py-1 rounded-full text-xs font-semibold ${f.is_paid ? 'bg-green-100 text-green-700' : 'bg-orange-100 text-orange-700'}`}>{f.is_paid ? 'Paid' : 'Unpaid'}</span></td>
                                <td className="px-4 py-3 flex gap-2">
                                  <button onClick={() => startEdit(f)} className="text-xs px-3 py-1 bg-blue-50 text-blue-600 rounded-lg hover:bg-blue-100 transition">Edit</button>
                                  <button onClick={() => deleteFee(f.id)} className="text-xs px-3 py-1 bg-red-50 text-red-600 rounded-lg hover:bg-red-100 transition">Delete</button>
                                </td>
                              </tr>
                            ))}
                          </tbody>
                        </table>
                      )}
                    </div>
                  </>
                )}
              </div>
            </div>
          )}

          {/* Camera assignments */}
          {tab === 'cameras' && (
            <div className="space-y-4">
              {teachers.length === 0 ? <p className="text-gray-400 text-sm">No teachers yet.</p> : teachers.map((t: any) => (
                <div key={t.id} className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
                  <div className="flex items-center justify-between flex-wrap gap-3">
                    <div>
                      <p className="font-bold text-gray-900">{t.full_name}</p>
                      <p className="text-sm text-gray-500">{t.department || '—'}{t.class_name ? ` • ${t.class_name}` : ''}</p>
                      <p className="text-xs text-gray-400 mt-1">
                        {t.assigned_camera_ids?.length > 0
                          ? `${t.assigned_camera_ids.length} camera(s) assigned`
                          : 'No cameras assigned'}
                      </p>
                    </div>
                    <button onClick={() => openAssign(t)} className="px-4 py-2 bg-blue-50 text-blue-600 hover:bg-blue-100 rounded-xl text-sm font-semibold transition">
                      Assign Cameras
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </>
      )}

      {/* System Settings Tab */}
      {tab === 'settings' && sysSettings && (
        <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-6 max-w-lg space-y-5">
          <h2 className="text-lg font-bold text-gray-900">System Settings</h2>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Face Recognition Threshold: <span className="text-purple-600 font-bold">{sysSettings.recognition_threshold}</span>
            </label>
            <input type="range" min="0.5" max="1.0" step="0.01"
              value={sysSettings.recognition_threshold}
              onChange={e => setSysSettings((s: any) => ({ ...s, recognition_threshold: parseFloat(e.target.value) }))}
              className="w-full accent-purple-600"
            />
            <p className="text-xs text-gray-400 mt-1">Higher = stricter matching. Recommended: 0.85–0.95</p>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Duplicate Window (minutes): <span className="text-purple-600 font-bold">{sysSettings.duplicate_window_minutes}</span></label>
            <input type="number" min="1" max="120"
              value={sysSettings.duplicate_window_minutes}
              onChange={e => setSysSettings((s: any) => ({ ...s, duplicate_window_minutes: parseInt(e.target.value) }))}
              className="border border-gray-200 rounded-xl px-4 py-2 text-sm w-32 focus:outline-none focus:border-purple-500"
            />
            <p className="text-xs text-gray-400 mt-1">Prevents the same student being marked twice within this window</p>
          </div>
          <button
            disabled={savingSettings}
            onClick={async () => {
              setSavingSettings(true);
              await fetch(`${API}/api/v1/admin/system-settings`, { method: 'PUT', headers: { 'Content-Type': 'application/json', ...auth().headers }, body: JSON.stringify(sysSettings) });
              setSavingSettings(false);
              setSuccess('Settings saved');
              setTimeout(() => setSuccess(''), 3000);
            }}
            className="px-6 py-2.5 bg-gradient-to-r from-purple-600 to-pink-600 text-white rounded-xl text-sm font-semibold hover:opacity-90 disabled:opacity-50 transition"
          >
            {savingSettings ? 'Saving...' : 'Save Settings'}
          </button>
        </div>
      )}

      {/* Audit Log Tab */}
      {tab === 'audit' && (
        <div className="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
          <div className="px-6 py-4 border-b border-gray-100">
            <h2 className="text-lg font-bold text-gray-900">Audit Log</h2>
            <p className="text-sm text-gray-400">Last 50 actions</p>
          </div>
          {auditLogs.length === 0 ? (
            <p className="text-gray-400 text-sm p-6">No audit logs yet.</p>
          ) : (
            <table className="w-full text-sm">
              <thead className="bg-gray-50 border-b border-gray-100">
                <tr>{['Time', 'Actor', 'Action', 'Target', 'Detail'].map(h => <th key={h} className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase">{h}</th>)}</tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {auditLogs.map((l: any) => (
                  <tr key={l.id} className="hover:bg-gray-50">
                    <td className="px-4 py-3 text-gray-400 text-xs whitespace-nowrap">{new Date(l.timestamp).toLocaleString()}</td>
                    <td className="px-4 py-3 text-gray-700 text-xs">{l.actor}</td>
                    <td className="px-4 py-3"><span className="bg-purple-100 text-purple-700 px-2 py-0.5 rounded-full text-xs font-medium">{l.action}</span></td>
                    <td className="px-4 py-3 text-gray-600 text-xs">{l.target_type} {l.target_id}</td>
                    <td className="px-4 py-3 text-gray-400 text-xs font-mono">{JSON.stringify(l.detail)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}

      {/* Camera assignment modal */}
      {assigningTeacher && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-md p-6">
            <h2 className="text-lg font-bold text-gray-900 mb-1">Assign Cameras</h2>
            <p className="text-sm text-gray-500 mb-4">Select cameras for {assigningTeacher.full_name}</p>
            <div className="space-y-2 max-h-64 overflow-y-auto mb-5">
              {cameras.length === 0 ? <p className="text-gray-400 text-sm">No cameras in system yet.</p> : cameras.map((c: any) => (
                <label key={c.id} className={`flex items-center gap-3 p-3 rounded-xl border cursor-pointer transition ${selectedCams.includes(c.id) ? 'border-blue-500 bg-blue-50' : 'border-gray-100 hover:border-gray-200'}`}>
                  <input type="checkbox" checked={selectedCams.includes(c.id)} onChange={() => toggleCam(c.id)} className="w-4 h-4 accent-blue-600" />
                  <div>
                    <p className="font-medium text-gray-900 text-sm">{c.name}</p>
                    <p className="text-xs text-gray-400 capitalize">{c.location?.replace(/_/g, ' ')}</p>
                  </div>
                </label>
              ))}
            </div>
            <div className="flex gap-3">
              <button onClick={saveAssignment} className="flex-1 py-2.5 bg-gradient-to-r from-blue-600 to-purple-600 text-white rounded-xl text-sm font-semibold hover:opacity-90 transition">Save</button>
              <button onClick={() => setAssigningTeacher(null)} className="flex-1 py-2.5 border border-gray-200 text-gray-600 rounded-xl text-sm font-semibold hover:bg-gray-50 transition">Cancel</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default function AdminPage() {
  return <RouteGuard allowedRoles={['admin']}><AdminUsersPage /></RouteGuard>;
}
