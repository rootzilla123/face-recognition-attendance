'use client';
import { useEffect, useState } from 'react';
import RouteGuard from '../components/RouteGuard';
import { api, Mark, Student } from '@/lib/api';
import ReportCard from '../marks/ReportCard';

function MyMarksContent() {
  const [marks, setMarks] = useState<Mark[]>([]);
  const [student, setStudent] = useState<Student | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    Promise.all([
      api.getMyMarks(),
      api.getMyStudentProfile()
    ]).then(([m, s]) => {
      setMarks(m);
      setStudent(s);
    }).catch(e => setError(e.message))
      .finally(() => setLoading(false));
  }, []);

  const handlePrint = () => {
    window.print();
  };

  return (
    <div className="p-8 space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">My Examination Marks</h1>
          <p className="text-gray-500 mt-1">View your published examination results and performance</p>
        </div>
        {marks.length > 0 && student && (
          <button 
            onClick={handlePrint}
            className="bg-blue-600 hover:bg-blue-700 text-white px-5 py-2.5 rounded-xl font-semibold transition flex items-center gap-2 shadow-sm print:hidden"
          >
            <span>🖨️</span> Print Report Card
          </button>
        )}
      </div>

      {error && <div className="bg-red-50 border border-red-200 text-red-600 rounded-xl px-4 py-3 text-sm">{error}</div>}

      {/* Hidden for screen, visible for print (controlled by ReportCard's style) */}
      <div className="hidden">
        {student && <ReportCard student={student} marks={marks} />}
      </div>

      {loading ? (
        <div className="flex justify-center py-12"><div className="w-8 h-8 border-4 border-blue-500 border-t-transparent rounded-full animate-spin" /></div>
      ) : marks.length === 0 ? (
        <div className="bg-white rounded-2xl border border-gray-100 p-16 text-center text-gray-400">
          <p className="text-5xl mb-4">📝</p>
          <p className="text-lg font-medium">No marks published yet.</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {marks.map((m) => (
            <div key={m.id} className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 space-y-4 hover:shadow-md transition-shadow">
              <div className="flex justify-between items-start">
                <div>
                  <h3 className="font-bold text-lg text-gray-900">{m.subject}</h3>
                  <p className="text-sm text-gray-500">{m.term}</p>
                </div>
                <div className="bg-blue-50 text-blue-700 px-3 py-1 rounded-lg text-sm font-bold">
                  {m.grade || `${m.percentage}%`}
                </div>
              </div>

              <div className="space-y-2">
                <div className="flex justify-between text-sm">
                  <span className="text-gray-500">Score</span>
                  <span className="font-semibold text-gray-900">{m.score} / {m.max_score}</span>
                </div>
                <div className="w-full bg-gray-100 rounded-full h-2 overflow-hidden">
                  <div 
                    className="bg-blue-600 h-full rounded-full transition-all duration-1000" 
                    style={{ width: `${m.percentage}%` }}
                  />
                </div>
              </div>

              {m.remarks && (
                <div className="bg-gray-50 rounded-xl p-3">
                  <p className="text-xs font-semibold text-gray-400 uppercase mb-1">Teacher&apos;s Remarks</p>
                  <p className="text-sm text-gray-600 italic">"{m.remarks}"</p>
                </div>
              )}
              
              <div className="pt-2 text-[10px] text-gray-400 uppercase tracking-widest font-bold">
                Recorded on {new Date(m.created_at).toLocaleDateString()}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

export default function MyMarksPage() {
  return <RouteGuard allowedRoles={['student']}><MyMarksContent /></RouteGuard>;
}
