import React from 'react';
import { Mark, Student } from '@/lib/api';

interface ReportCardProps {
  student: Student;
  marks: Mark[];
  schoolLogo?: string;
}

const ReportCard: React.FC<ReportCardProps> = ({ student, marks, schoolLogo }) => {
  return (
    <div className="report-card bg-white p-8 max-w-[210mm] mx-auto text-gray-900 font-sans border border-gray-200 shadow-lg print:shadow-none print:border-none print:m-0 print:p-0">
      {/* Header */}
      <div className="flex justify-between items-start border-b-2 border-blue-900 pb-4 mb-6">
        <div className="flex items-center gap-4">
          {schoolLogo ? (
            <img src={schoolLogo} alt="Logo" className="w-20 h-20 object-contain" />
          ) : (
            <div className="w-20 h-20 bg-blue-900 rounded-lg flex items-center justify-center text-white text-3xl font-bold">SF</div>
          )}
          <div>
            <h1 className="text-2xl font-bold text-blue-900 tracking-tight">SHADOMFACE PRO ACADEMY</h1>
            <p className="text-sm italic text-gray-600">Knowledge for the Future</p>
          </div>
        </div>
        <div className="text-right text-xs text-gray-500">
          <p>123 School Avenue, Digital City</p>
          <p>support@shadomfacepro.com</p>
          <p>www.shadomfacepro.org</p>
        </div>
      </div>

      <div className="text-center mb-8">
        <h2 className="text-xl font-bold uppercase tracking-widest border-y border-gray-100 py-2">Student Progress Report</h2>
      </div>

      {/* Student Details */}
      <div className="grid grid-cols-2 gap-6 bg-gray-50 p-4 rounded-xl mb-8 border border-gray-100">
        <div className="space-y-1">
          <p className="text-xs uppercase font-bold text-gray-400">Student Name</p>
          <p className="font-bold text-lg">{student.full_name}</p>
          <p className="text-xs uppercase font-bold text-gray-400 mt-2">Student ID</p>
          <p className="font-mono">{student.student_id}</p>
        </div>
        <div className="space-y-1">
          <p className="text-xs uppercase font-bold text-gray-400">Grade & Section</p>
          <p className="font-bold text-lg">{student.grade_level} - {student.section || 'N/A'}</p>
          <p className="text-xs uppercase font-bold text-gray-400 mt-2">Academic Year</p>
          <p className="">2025/2026</p>
        </div>
      </div>

      {/* Marks Table */}
      <table className="w-full mb-12 border-collapse">
        <thead>
          <tr className="bg-blue-900 text-white text-left text-xs uppercase tracking-wider">
            <th className="p-3 rounded-tl-lg">Subject</th>
            <th className="p-3">Term</th>
            <th className="p-3">Score</th>
            <th className="p-3">Max</th>
            <th className="p-3">Grade</th>
            <th className="p-3 rounded-tr-lg">Remarks</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-gray-100 border-x border-b border-gray-100">
          {marks.map((m, i) => (
            <tr key={i} className={i % 2 === 0 ? 'bg-white' : 'bg-gray-50/30'}>
              <td className="p-3 font-bold">{m.subject}</td>
              <td className="p-3 text-gray-600">{m.term}</td>
              <td className="p-3 font-bold">{m.score}</td>
              <td className="p-3 text-gray-500">{m.max_score}</td>
              <td className="p-3">
                <span className="bg-blue-50 text-blue-700 px-2 py-1 rounded font-bold text-xs">{m.grade || `${m.percentage}%`}</span>
              </td>
              <td className="p-3 text-sm italic text-gray-600">{m.remarks || '—'}</td>
            </tr>
          ))}
        </tbody>
      </table>

      {/* Footer */}
      <div className="flex justify-between items-end mt-auto pt-12">
        <div className="text-center w-48">
          <div className="border-t border-gray-900 pt-2 text-xs font-bold uppercase">Class Teacher</div>
        </div>
        <div className="text-center">
          <p className="text-[10px] text-gray-400 mb-4">Issued on: {new Date().toLocaleDateString()}</p>
          <div className="w-32 h-12 border-2 border-blue-900/10 rounded flex items-center justify-center opacity-20 rotate-[-5deg]">
            <span className="text-blue-900 font-black uppercase text-xs">Official Seal</span>
          </div>
        </div>
        <div className="text-center w-48">
          <div className="border-t border-gray-900 pt-2 text-xs font-bold uppercase">Principal</div>
        </div>
      </div>

      <p className="text-center text-[8px] text-gray-400 mt-16 uppercase tracking-widest">
        This is a computer-generated document. SHADOMFACE PRO ACADEMY © 2026
      </p>

      <style jsx>{`
        @media print {
          body * {
            visibility: hidden;
          }
          .report-card, .report-card * {
            visibility: visible;
          }
          .report-card {
            position: absolute;
            left: 0;
            top: 0;
            width: 100%;
            border: none;
            box-shadow: none;
          }
        }
      `}</style>
    </div>
  );
};

export default ReportCard;
