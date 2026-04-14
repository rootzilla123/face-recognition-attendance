'use client';
import { useState } from 'react';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { api } from '@/lib/api';
import RouteGuard from '../components/RouteGuard';

const exportCSV = (records: any[], filename: string) => {
  if (!records.length) return;
  const headers = Object.keys(records[0]).join(',');
  const rows = records.map((r: any) => Object.values(r).map((v: any) => `"${v}"`).join(',')).join('\n');
  const blob = new Blob([headers + '\n' + rows], { type: 'text/csv' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a'); a.href = url; a.download = filename; a.click();
  URL.revokeObjectURL(url);
};

const exportPDF = (data: any, title: string) => {
  const doc = new jsPDF();
  doc.setFontSize(16); doc.text(title, 14, 15);
  doc.setFontSize(10); doc.text(`Generated: ${new Date().toLocaleString()}`, 14, 22);
  const records = data?.records || data?.grades || [];
  if (records.length > 0) {
    autoTable(doc, { head: [Object.keys(records[0])], body: records.map((r: any) => Object.values(r).map(String)), startY: 28, styles: { fontSize: 8 } });
  }
  doc.save(`${title.replace(/\s+/g, '-').toLowerCase()}.pdf`);
};

function ReportsContent() {
  const [tab, setTab] = useState<'daily' | 'student' | 'grade'>('daily');
  const [date, setDate] = useState(new Date().toISOString().split('T')[0]);
  const [studentId, setStudentId] = useState('');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const run = async () => {
    setError(''); setLoading(true); setData(null);
    try {
      if (tab === 'daily') setData(await api.getDailySummary(date));
      else if (tab === 'student') setData(await api.getStudentReport(studentId, startDate, endDate));
      else setData(await api.getGradeSummary(date));
    } catch (e: any) { setError(e.message); }
    finally { setLoading(false); }
  };

  const inputCls = "border border-gray-200 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:border-blue-500";
  const records = data?.records || data?.grades || [];

  return (
    <div className="p-8 space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Reports</h1>
        <p className="text-gray-500 mt-1">Generate attendance reports</p>
      </div>

      {/* Tabs */}
      <div className="flex gap-2 bg-gray-100 p-1 rounded-xl w-fit">
        {(['daily', 'student', 'grade'] as const).map(t => (
          <button key={t} onClick={() => { setTab(t); setData(null); }}
            className={`px-5 py-2 rounded-lg text-sm font-semibold capitalize transition ${tab === t ? 'bg-white shadow text-gray-900' : 'text-gray-500 hover:text-gray-700'}`}>
            {t === 'daily' ? 'Daily Summary' : t === 'student' ? 'By Student' : 'By Grade'}
          </button>
        ))}
      </div>

      {/* Filters */}
      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
        <div className="flex flex-wrap gap-3 items-end">
          {(tab === 'daily' || tab === 'grade') && (
            <div><label className="block text-xs text-gray-500 mb-1">Date</label>
              <input type="date" value={date} onChange={e => setDate(e.target.value)} className={inputCls} /></div>
          )}
          {tab === 'student' && (<>
            <div><label className="block text-xs text-gray-500 mb-1">Student ID</label>
              <input value={studentId} onChange={e => setStudentId(e.target.value)} placeholder="e.g. STU001" className={inputCls} /></div>
            <div><label className="block text-xs text-gray-500 mb-1">Start Date</label>
              <input type="date" value={startDate} onChange={e => setStartDate(e.target.value)} className={inputCls} /></div>
            <div><label className="block text-xs text-gray-500 mb-1">End Date</label>
              <input type="date" value={endDate} onChange={e => setEndDate(e.target.value)} className={inputCls} /></div>
          </>)}
          <button onClick={run} disabled={loading}
            className="px-6 py-2.5 bg-gradient-to-r from-blue-600 to-purple-600 text-white rounded-xl text-sm font-semibold hover:opacity-90 disabled:opacity-50 transition">
            {loading ? 'Generating...' : 'Generate Report'}
          </button>
          {data && records.length > 0 && (<>
            <button onClick={() => exportCSV(records, `report-${tab}-${date}.csv`)}
              className="px-5 py-2.5 bg-green-600 text-white rounded-xl text-sm font-semibold hover:opacity-90 transition">⬇ CSV</button>
            <button onClick={() => exportPDF(data, `${tab} Report`)}
              className="px-5 py-2.5 bg-red-600 text-white rounded-xl text-sm font-semibold hover:opacity-90 transition">⬇ PDF</button>
          </>)}
        </div>
        {error && <p className="text-red-500 text-sm mt-3">{error}</p>}
      </div>

      {/* Results */}
      {data && (
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
          {tab === 'daily' && (<>
            <div className="grid grid-cols-4 gap-4 mb-6">
              {[{label:'Total',value:data.total_students},{label:'Present',value:data.present},{label:'Absent',value:data.absent},{label:'Rate',value:`${data.attendance_rate}%`}].map(({label,value}) => (
                <div key={label} className="text-center p-4 bg-gray-50 rounded-xl">
                  <p className="text-2xl font-bold text-gray-900">{value}</p>
                  <p className="text-xs text-gray-500 mt-1">{label}</p>
                </div>
              ))}
            </div>
            <table className="w-full text-sm">
              <thead><tr className="text-left text-gray-400 border-b border-gray-100">
                <th className="pb-3 font-medium">Student</th><th className="pb-3 font-medium">Grade</th>
                <th className="pb-3 font-medium">First Seen</th><th className="pb-3 font-medium">Location</th>
              </tr></thead>
              <tbody className="divide-y divide-gray-50">
                {data.records?.map((r: any) => (
                  <tr key={r.student_id} className="hover:bg-gray-50">
                    <td className="py-3 font-medium text-gray-900">{r.full_name}</td>
                    <td className="py-3 text-gray-600">{r.grade_level}</td>
                    <td className="py-3 text-gray-600">{new Date(r.first_seen).toLocaleTimeString()}</td>
                    <td className="py-3 text-gray-600 capitalize">{r.camera_location?.replace(/_/g, ' ')}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </>)}

          {tab === 'student' && data.records && (<>
            <div className="mb-4">
              <p className="font-bold text-gray-900 text-lg">{data.student?.full_name}</p>
              <p className="text-gray-500 text-sm">{data.student?.grade_level} • Days Present: {data.days_present}</p>
            </div>
            <div className="space-y-2">
              {data.records.map((r: any, i: number) => (
                <div key={i} className="flex justify-between py-2 border-b border-gray-50 text-sm">
                  <span className="text-gray-900">{r.date}</span>
                  <span className="text-gray-600">{r.time}</span>
                  <span className="text-gray-500 capitalize">{r.camera_location?.replace(/_/g, ' ')}</span>
                </div>
              ))}
            </div>
          </>)}

          {tab === 'grade' && data.grades && (
            <div className="space-y-4">
              {data.grades.map((g: any) => (
                <div key={g.grade} className="flex items-center gap-4">
                  <span className="w-24 text-sm font-medium text-gray-700">{g.grade}</span>
                  <div className="flex-1 bg-gray-100 rounded-full h-3 overflow-hidden">
                    <div className="h-full bg-gradient-to-r from-blue-500 to-purple-500 rounded-full" style={{ width: `${g.rate}%` }} />
                  </div>
                  <span className="text-sm font-semibold text-gray-700 w-12 text-right">{g.rate}%</span>
                  <span className="text-xs text-gray-400">{g.present}/{g.total}</span>
                </div>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
}

export default function ReportsPage() {
  return <RouteGuard allowedRoles={['admin', 'teacher']}><ReportsContent /></RouteGuard>;
}
