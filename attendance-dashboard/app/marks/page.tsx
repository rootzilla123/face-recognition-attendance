'use client';
import { useEffect, useState } from 'react';
import RouteGuard from '../components/RouteGuard';
import { api, Mark, Student } from '@/lib/api';
import ReportCard from './ReportCard';

function MarksContent() {
  const [marks, setMarks] = useState<Mark[]>([]);
  const [students, setStudents] = useState<Student[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingMark, setEditingMark] = useState<Mark | null>(null);

  // For bulk upload
  const [isBulkModalOpen, setIsBulkModalOpen] = useState(false);
  const [bulkFile, setBulkFile] = useState<File | null>(null);
  const [bulkTerm, setBulkTerm] = useState('Term 1 2026');

  // For analytics
  const [analytics, setAnalytics] = useState<any>(null);
  const [selectedSubject, setSelectedSubject] = useState('');

  // For printing
  const [printingStudent, setPrintingStudent] = useState<Student | null>(null);
  const [printingMarks, setPrintingMarks] = useState<Mark[]>([]);

  // Form states
  const [formData, setFormData] = useState({
    student_id: '',
    subject: '',
    term: '',
    score: 0,
    max_score: 100,
    grade: '',
    remarks: ''
  });

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    setLoading(true);
    try {
      const [marksData, studentsData] = await Promise.all([
        api.getMarks(),
        api.getStudents()
      ]);
      setMarks(marksData);
      setStudents(studentsData);
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  };

  const handleOpenModal = (mark?: Mark) => {
    if (mark) {
      setEditingMark(mark);
      setFormData({
        student_id: mark.student_id,
        subject: mark.subject,
        term: mark.term,
        score: mark.score,
        max_score: mark.max_score,
        grade: mark.grade || '',
        remarks: mark.remarks || ''
      });
    } else {
      setEditingMark(null);
      setFormData({
        student_id: '',
        subject: '',
        term: '',
        score: 0,
        max_score: 100,
        grade: '',
        remarks: ''
      });
    }
    setIsModalOpen(true);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      if (editingMark) {
        await api.updateMark(editingMark.id, formData);
      } else {
        await api.createMark(formData);
      }
      setIsModalOpen(false);
      loadData();
    } catch (e: any) {
      alert(e.message);
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this mark?')) return;
    try {
      await api.deleteMark(id);
      loadData();
    } catch (e: any) {
      alert(e.message);
    }
  };

  const handlePublish = async (id: string) => {
    try {
      await api.publishMark(id);
      loadData();
    } catch (e: any) {
      alert(e.message);
    }
  };

  const handlePrint = (studentId: string) => {
    const student = students.find(s => s.student_id === studentId);
    if (!student) return;
    const studentMarks = marks.filter(m => m.student_id === studentId && m.is_published);
    if (studentMarks.length === 0) {
      alert('This student has no published marks to print.');
      return;
    }
    setPrintingStudent(student);
    setPrintingMarks(studentMarks);
    setTimeout(() => {
      window.print();
    }, 100);
  };

  const handleBulkUpload = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!bulkFile) return;
    try {
      const res = await api.bulkUploadMarks(bulkFile, bulkTerm);
      alert(`Successfully uploaded ${res.success} marks. Failed: ${res.failed}`);
      setIsBulkModalOpen(false);
      loadData();
    } catch (e: any) {
      alert(e.message);
    }
  };

  const fetchAnalytics = async (subject: string) => {
    setSelectedSubject(subject);
    if (!subject) {
      setAnalytics(null);
      return;
    }
    try {
      const data = await api.getSubjectAnalytics(subject, 'Term 1 2026');
      setAnalytics(data);
    } catch (e) {
      console.error(e);
    }
  };

  return (
    <div className="p-8 space-y-6">
      {/* Hidden for screen, visible for print */}
      <div className="hidden">
        {printingStudent && <ReportCard student={printingStudent} marks={printingMarks} />}
      </div>

      <div className="flex items-center justify-between print:hidden">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Examination Marks</h1>
          <p className="text-gray-500 mt-1">Manage and publish student examination results</p>
        </div>
        <div className="flex gap-3">
          <button
            onClick={() => setIsBulkModalOpen(true)}
            className="bg-gray-100 hover:bg-gray-200 text-gray-700 px-5 py-2.5 rounded-xl font-semibold transition flex items-center gap-2 shadow-sm"
          >
            <span>📤</span> Bulk Upload
          </button>
          <button
            onClick={() => handleOpenModal()}
            className="bg-blue-600 hover:bg-blue-700 text-white px-5 py-2.5 rounded-xl font-semibold transition flex items-center gap-2 shadow-sm"
          >
            <span>➕</span> Add Mark
          </button>
        </div>
      </div>

      {/* Analytics Card */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6 print:hidden">
        <div className="md:col-span-1 bg-white p-6 rounded-2xl border border-gray-100 shadow-sm">
          <label className="block text-xs font-bold text-gray-400 uppercase mb-2">Subject Performance</label>
          <select 
            className="w-full border border-gray-200 rounded-xl px-4 py-2 text-sm"
            onChange={(e) => fetchAnalytics(e.target.value)}
          >
            <option value="">Select Subject</option>
            {Array.from(new Set(marks.map(m => m.subject))).map(s => (
              <option key={s} value={s}>{s}</option>
            ))}
          </select>
          {analytics && (
            <div className="mt-4 space-y-3">
              <div className="flex justify-between items-center">
                <span className="text-sm text-gray-500">Average</span>
                <span className="font-bold text-blue-600">{analytics.average_percentage}%</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm text-gray-500">Highest</span>
                <span className="font-bold text-green-600">{analytics.highest_percentage}%</span>
              </div>
              <div className="w-full bg-gray-100 rounded-full h-1.5 mt-1">
                <div className="bg-blue-500 h-full rounded-full" style={{ width: `${analytics.average_percentage}%` }} />
              </div>
            </div>
          )}
        </div>
        <div className="md:col-span-3 bg-gradient-to-r from-blue-600 to-indigo-700 rounded-2xl p-6 text-white flex items-center justify-between shadow-md">
           <div>
              <h3 className="text-lg font-bold">Automatic Grading Active</h3>
              <p className="text-blue-100 text-sm opacity-80 max-w-md">Grades are automatically assigned based on your school&apos;s active grading scheme. Notifications are sent to parents instantly when results are published.</p>
           </div>
           <div className="text-5xl opacity-20">🤖</div>
        </div>
      </div>

      {error && <div className="bg-red-50 border border-red-200 text-red-600 rounded-xl px-4 py-3 text-sm print:hidden">{error}</div>}

      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden print:hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 border-b border-gray-100">
            <tr>
              {['Student', 'Subject', 'Term', 'Score', 'Grade', 'Status', 'Actions'].map(h => (
                <th key={h} className="text-left px-6 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">{h}</th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-50">
            {loading ? (
              <tr><td colSpan={7} className="text-center py-8"><div className="w-6 h-6 border-2 border-blue-500 border-t-transparent rounded-full animate-spin mx-auto" /></td></tr>
            ) : marks.length === 0 ? (
              <tr><td colSpan={7} className="text-center py-12 text-gray-400">No marks recorded yet.</td></tr>
            ) : (
              marks.map((m) => (
                <tr key={m.id} className="hover:bg-gray-50 transition-colors">
                  <td className="px-6 py-4">
                    <div className="font-medium text-gray-900">{m.student_name}</div>
                    <div className="text-xs text-gray-400">{m.student_id}</div>
                  </td>
                  <td className="px-6 py-4 text-gray-600 font-medium">{m.subject}</td>
                  <td className="px-6 py-4 text-gray-600">{m.term}</td>
                  <td className="px-6 py-4">
                    <div className="font-semibold text-gray-900">{m.score} / {m.max_score}</div>
                    <div className="text-xs text-gray-500">{m.percentage}%</div>
                  </td>
                  <td className="px-6 py-4">
                    <span className="px-2.5 py-1 bg-gray-100 rounded-lg font-bold text-gray-700">{m.grade || '—'}</span>
                  </td>
                  <td className="px-6 py-4">
                    {m.is_published ? (
                      <span className="px-2 py-1 bg-green-100 text-green-700 rounded-full text-xs font-bold uppercase tracking-wider">Published</span>
                    ) : (
                      <span className="px-2 py-1 bg-amber-100 text-amber-700 rounded-full text-xs font-bold uppercase tracking-wider">Draft</span>
                    )}
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-2">
                      <button onClick={() => handlePrint(m.student_id)} className="p-1.5 text-gray-600 hover:bg-gray-100 rounded-lg" title="Print Report Card">
                        🖨️
                      </button>
                      {!m.is_published && (
                        <button onClick={() => handlePublish(m.id)} className="p-1.5 text-blue-600 hover:bg-blue-50 rounded-lg" title="Publish">
                          🚀
                        </button>
                      )}
                      <button onClick={() => handleOpenModal(m)} className="p-1.5 text-gray-600 hover:bg-gray-100 rounded-lg" title="Edit">
                        ✏️
                      </button>
                      <button onClick={() => handleDelete(m.id)} className="p-1.5 text-red-600 hover:bg-red-50 rounded-lg" title="Delete">
                        🗑️
                      </button>
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {/* Bulk Upload Modal */}
      {isBulkModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm print:hidden">
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md overflow-hidden">
             <div className="px-6 py-4 border-b border-gray-100 flex items-center justify-between">
                <h2 className="text-xl font-bold text-gray-900">Bulk Upload Marks</h2>
                <button onClick={() => setIsBulkModalOpen(false)} className="text-gray-400 hover:text-gray-600 text-2xl">×</button>
             </div>
             <form onSubmit={handleBulkUpload} className="p-6 space-y-4">
                <div className="bg-blue-50 p-4 rounded-xl text-sm text-blue-700">
                   <p className="font-bold mb-1">CSV Format Requirements:</p>
                   <p>student_id, subject, score, max_score, remarks</p>
                   <p className="mt-2 opacity-80 italic">Template: STU001, Mathematics, 85, 100, Good work</p>
                </div>
                <div>
                   <label className="block text-sm font-semibold text-gray-700 mb-1">Select Term</label>
                   <input 
                      className="w-full border border-gray-200 rounded-xl px-4 py-2 text-sm focus:outline-none focus:border-blue-500"
                      value={bulkTerm}
                      onChange={(e) => setBulkTerm(e.target.value)}
                   />
                </div>
                <div>
                   <label className="block text-sm font-semibold text-gray-700 mb-1">CSV File</label>
                   <input 
                      type="file" accept=".csv"
                      className="w-full text-sm file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-sm file:font-semibold file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100"
                      onChange={(e) => setBulkFile(e.target.files?.[0] || null)}
                   />
                </div>
                <div className="pt-2 flex gap-3">
                   <button type="button" onClick={() => setIsBulkModalOpen(false)} className="flex-1 px-4 py-2.5 border border-gray-200 text-gray-600 rounded-xl font-semibold hover:bg-gray-50 transition">Cancel</button>
                   <button type="submit" disabled={!bulkFile} className="flex-1 px-4 py-2.5 bg-blue-600 text-white rounded-xl font-semibold disabled:opacity-50 hover:bg-blue-700 shadow-md transition">Upload CSV</button>
                </div>
             </form>
          </div>
        </div>
      )}

      {/* Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm print:hidden">
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md overflow-hidden">
            <div className="px-6 py-4 border-b border-gray-100 flex items-center justify-between">
              <h2 className="text-xl font-bold text-gray-900">{editingMark ? 'Edit Mark' : 'Add New Mark'}</h2>
              <button onClick={() => setIsModalOpen(false)} className="text-gray-400 hover:text-gray-600 text-2xl">×</button>
            </div>
            <form onSubmit={handleSubmit} className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-1">Student</label>
                <select
                  required
                  disabled={!!editingMark}
                  className="w-full border border-gray-200 rounded-xl px-4 py-2 text-sm focus:outline-none focus:border-blue-500 bg-white"
                  value={formData.student_id}
                  onChange={(e) => setFormData({ ...formData, student_id: e.target.value })}
                >
                  <option value="">Select a student</option>
                  {students.map(s => (
                    <option key={s.id} value={s.student_id}>{s.full_name} ({s.student_id})</option>
                  ))}
                </select>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-1">Subject</label>
                  <input
                    required
                    className="w-full border border-gray-200 rounded-xl px-4 py-2 text-sm focus:outline-none focus:border-blue-500"
                    placeholder="e.g. Mathematics"
                    value={formData.subject}
                    onChange={(e) => setFormData({ ...formData, subject: e.target.value })}
                  />
                </div>
                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-1">Term</label>
                  <input
                    required
                    className="w-full border border-gray-200 rounded-xl px-4 py-2 text-sm focus:outline-none focus:border-blue-500"
                    placeholder="e.g. First Term"
                    value={formData.term}
                    onChange={(e) => setFormData({ ...formData, term: e.target.value })}
                  />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-1">Score</label>
                  <input
                    required
                    type="number"
                    step="0.01"
                    className="w-full border border-gray-200 rounded-xl px-4 py-2 text-sm focus:outline-none focus:border-blue-500"
                    value={formData.score}
                    onChange={(e) => setFormData({ ...formData, score: parseFloat(e.target.value) })}
                  />
                </div>
                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-1">Max Score</label>
                  <input
                    required
                    type="number"
                    step="0.01"
                    className="w-full border border-gray-200 rounded-xl px-4 py-2 text-sm focus:outline-none focus:border-blue-500"
                    value={formData.max_score}
                    onChange={(e) => setFormData({ ...formData, max_score: parseFloat(e.target.value) })}
                  />
                </div>
              </div>
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-1">Grade (Optional)</label>
                <input
                  className="w-full border border-gray-200 rounded-xl px-4 py-2 text-sm focus:outline-none focus:border-blue-500"
                  placeholder="e.g. A+"
                  value={formData.grade}
                  onChange={(e) => setFormData({ ...formData, grade: e.target.value })}
                />
              </div>
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-1">Remarks (Optional)</label>
                <textarea
                  className="w-full border border-gray-200 rounded-xl px-4 py-2 text-sm focus:outline-none focus:border-blue-500"
                  placeholder="Additional notes..."
                  rows={2}
                  value={formData.remarks}
                  onChange={(e) => setFormData({ ...formData, remarks: e.target.value })}
                />
              </div>
              <div className="pt-2 flex gap-3">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="flex-1 px-4 py-2.5 border border-gray-200 text-gray-600 rounded-xl font-semibold hover:bg-gray-50 transition"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="flex-1 px-4 py-2.5 bg-blue-600 text-white rounded-xl font-semibold hover:bg-blue-700 shadow-md transition"
                >
                  {editingMark ? 'Update Mark' : 'Save Mark'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

export default function MarksPage() {
  return <RouteGuard allowedRoles={['admin', 'teacher']}><MarksContent /></RouteGuard>;
}
