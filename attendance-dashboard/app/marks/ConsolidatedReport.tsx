import React from 'react';

interface Mark {
  subject: string;
  term: string;
  score: number;
  max_score: number;
  percentage: number;
  grade?: string;
  remarks?: string;
}

interface ConsolidatedReportProps {
  studentName: string;
  studentId: string;
  term: string;
  marks: Mark[];
  totalScore: number;
  totalMax: number;
  overallPercentage: number;
  overallGrade?: string;
  schoolLogo?: string;
}

const ConsolidatedReport: React.FC<ConsolidatedReportProps> = ({
  studentName, studentId, term, marks, totalScore, totalMax, overallPercentage, overallGrade, schoolLogo
}) => {
  return (
    <div className="consolidated-report bg-white p-10 max-w-[210mm] mx-auto text-gray-900 border border-gray-300 shadow-xl print:shadow-none print:border-none print:m-0">
      {/* Header */}
      <div className="flex justify-between items-center border-b-4 border-blue-900 pb-6 mb-8">
        <div className="flex items-center gap-6">
          {schoolLogo ? (
            <img src={schoolLogo} alt="Logo" className="w-24 h-24 object-contain" />
          ) : (
            <div className="w-24 h-24 bg-blue-900 rounded-2xl flex items-center justify-center text-white text-4xl font-black shadow-lg">SF</div>
          )}
          <div>
            <h1 className="text-3xl font-black text-blue-900 tracking-tight">SHADOMFACE PRO ACADEMY</h1>
            <p className="text-lg font-medium text-gray-500 italic">Excellence in Digital Learning</p>
          </div>
        </div>
        <div className="text-right text-sm text-gray-400 font-medium">
          <p>Official Academic Document</p>
          <p>Serial: {studentId}-{new Date().getFullYear()}</p>
        </div>
      </div>

      <div className="text-center mb-10">
        <h2 className="text-2xl font-black uppercase tracking-[0.2em] bg-gray-900 text-white py-3 inline-block px-12 rounded-full">Term Summary Report</h2>
        <p className="mt-4 text-gray-500 font-bold uppercase tracking-widest">{term}</p>
      </div>

      {/* Profile Section */}
      <div className="grid grid-cols-3 gap-8 mb-10 bg-blue-50/50 p-6 rounded-3xl border border-blue-100">
        <div className="col-span-2">
          <p className="text-[10px] uppercase font-black text-blue-400 tracking-widest mb-1">Student Name</p>
          <p className="text-2xl font-black text-gray-800">{studentName}</p>
          <div className="flex gap-8 mt-4">
             <div>
                <p className="text-[10px] uppercase font-black text-blue-400 tracking-widest mb-1">Student ID</p>
                <p className="font-mono font-bold text-gray-700">{studentId}</p>
             </div>
             <div>
                <p className="text-[10px] uppercase font-black text-blue-400 tracking-widest mb-1">Status</p>
                <p className="font-bold text-green-600">PASSED</p>
             </div>
          </div>
        </div>
        <div className="bg-white p-4 rounded-2xl border border-blue-100 text-center flex flex-col justify-center shadow-sm">
           <p className="text-[10px] uppercase font-black text-blue-400 tracking-widest mb-1">Overall Grade</p>
           <p className="text-5xl font-black text-blue-900">{overallGrade || '—'}</p>
           <p className="text-xs font-bold text-gray-400 mt-1">{overallPercentage}% Average</p>
        </div>
      </div>

      {/* Detailed Results */}
      <table className="w-full mb-12 border-collapse overflow-hidden rounded-2xl border border-gray-200">
        <thead>
          <tr className="bg-gray-900 text-white text-left text-[11px] uppercase tracking-widest font-bold">
            <th className="p-4">Subject</th>
            <th className="p-4 text-center">Score</th>
            <th className="p-4 text-center">Max</th>
            <th className="p-4 text-center">Grade</th>
            <th className="p-4">Performance Indicator</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-gray-100">
          {marks.map((m, i) => (
            <tr key={i} className="hover:bg-blue-50/30 transition-colors">
              <td className="p-4 font-bold text-gray-800">{m.subject}</td>
              <td className="p-4 text-center font-black text-gray-700">{m.score}</td>
              <td className="p-4 text-center text-gray-400 font-medium">{m.max_score}</td>
              <td className="p-4 text-center">
                <span className={`px-3 py-1 rounded-lg font-black text-sm ${
                   (m.percentage >= 80) ? 'bg-green-100 text-green-700' :
                   (m.percentage >= 50) ? 'bg-blue-100 text-blue-700' : 'bg-red-100 text-red-700'
                }`}>
                  {m.grade || `${m.percentage}%`}
                </span>
              </td>
              <td className="p-4">
                 <div className="w-full bg-gray-100 h-2 rounded-full overflow-hidden">
                    <div className="bg-blue-600 h-full rounded-full" style={{ width: `${m.percentage}%` }} />
                 </div>
              </td>
            </tr>
          ))}
          <tr className="bg-gray-50 border-t-2 border-gray-900">
             <td className="p-4 font-black text-gray-900 uppercase">Grand Total</td>
             <td className="p-4 text-center font-black text-blue-900 text-xl">{totalScore.toFixed(1)}</td>
             <td className="p-4 text-center font-black text-gray-400">{totalMax}</td>
             <td colSpan={2} className="p-4 text-right pr-8">
                <span className="text-gray-400 font-bold text-sm mr-4">Weighted Percentage:</span>
                <span className="text-2xl font-black text-gray-900">{overallPercentage.toFixed(1)}%</span>
             </td>
          </tr>
        </tbody>
      </table>

      {/* Comments Section */}
      <div className="mb-12">
         <h3 className="text-xs font-black text-gray-400 uppercase tracking-widest mb-4 border-b border-gray-100 pb-2">Class Teacher's Evaluative Remarks</h3>
         <div className="bg-gray-50 p-6 rounded-3xl min-h-[100px] border border-gray-100 italic text-gray-600">
            {marks.find(m => m.remarks)?.remarks || "The student has shown consistent effort throughout the term. Continued focus on core subjects is recommended to maintain this high standard of academic performance."}
         </div>
      </div>

      {/* Verification */}
      <div className="grid grid-cols-3 gap-12 items-end pt-12">
        <div className="text-center">
          <div className="w-full border-b-2 border-gray-300 mb-2"></div>
          <p className="text-[10px] font-black uppercase text-gray-400 tracking-tighter">Academic Coordinator</p>
        </div>
        <div className="flex flex-col items-center">
           <div className="w-24 h-24 border-4 border-blue-900/10 rounded-full flex items-center justify-center mb-2">
              <div className="text-center rotate-[-15deg]">
                 <p className="text-[8px] font-black text-blue-900 uppercase">Verified</p>
                 <p className="text-[10px] font-black text-blue-900 uppercase">ShadomFace</p>
                 <p className="text-[8px] font-black text-blue-900 uppercase">2026</p>
              </div>
           </div>
           <p className="text-[9px] font-bold text-gray-300 uppercase tracking-widest">School Seal</p>
        </div>
        <div className="text-center">
          <div className="w-full border-b-2 border-gray-300 mb-2"></div>
          <p className="text-[10px] font-black uppercase text-gray-400 tracking-tighter">Principal / Head of School</p>
        </div>
      </div>

      <p className="text-center text-[9px] text-gray-300 mt-20 uppercase tracking-[0.3em] font-black">
        Generated by AttendanceAI Intelligence System • {new Date().toLocaleDateString()}
      </p>

      <style jsx>{`
        @media print {
          body * { visibility: hidden; }
          .consolidated-report, .consolidated-report * { visibility: visible; }
          .consolidated-report {
            position: absolute;
            left: 0;
            top: 0;
            width: 100%;
            border: none;
            box-shadow: none;
            padding: 0;
          }
        }
      `}</style>
    </div>
  );
};

export default ConsolidatedReport;
