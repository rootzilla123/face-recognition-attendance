'use client';
import { useEffect, useState } from 'react';
import { api } from '@/lib/api';

// ── SVG Line Chart ────────────────────────────────────────────────────────────
function TrendChart({ data }: { data: { day: string; rate: number; present: number }[] }) {
  if (!data.length) return null;
  const W = 500, H = 160, PAD = 30;
  const max = Math.max(...data.map(d => d.rate), 100);
  const pts = data.map((d, i) => {
    const x = PAD + (i / (data.length - 1)) * (W - PAD * 2);
    const y = H - PAD - (d.rate / max) * (H - PAD * 2);
    return { x, y, ...d };
  });
  const polyline = pts.map(p => `${p.x},${p.y}`).join(' ');
  const area = `M${pts[0].x},${H - PAD} ` + pts.map(p => `L${p.x},${p.y}`).join(' ') + ` L${pts[pts.length - 1].x},${H - PAD} Z`;

  return (
    <svg viewBox={`0 0 ${W} ${H}`} className="w-full h-40">
      <defs>
        <linearGradient id="grad" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#8b5cf6" stopOpacity="0.3" />
          <stop offset="100%" stopColor="#8b5cf6" stopOpacity="0" />
        </linearGradient>
      </defs>
      <path d={area} fill="url(#grad)" />
      <polyline points={polyline} fill="none" stroke="#8b5cf6" strokeWidth="2.5" strokeLinejoin="round" />
      {pts.map((p, i) => (
        <g key={i}>
          <circle cx={p.x} cy={p.y} r="4" fill="#8b5cf6" />
          <text x={p.x} y={H - 8} textAnchor="middle" fontSize="11" fill="#9ca3af">{p.day}</text>
          <text x={p.x} y={p.y - 8} textAnchor="middle" fontSize="10" fill="#6d28d9" fontWeight="600">{p.rate}%</text>
        </g>
      ))}
    </svg>
  );
}

// ── Bar Chart ─────────────────────────────────────────────────────────────────
function GradeBarChart({ grades }: { grades: { grade: string; rate: number; present: number; total: number }[] }) {
  if (!grades.length) return null;
  return (
    <div className="space-y-3">
      {grades.map(g => (
        <div key={g.grade} className="flex items-center gap-3">
          <span className="w-20 text-sm font-medium text-gray-600 truncate">{g.grade}</span>
          <div className="flex-1 bg-gray-100 rounded-full h-4 overflow-hidden">
            <div
              className="h-full rounded-full transition-all duration-700"
              style={{
                width: `${g.rate}%`,
                background: g.rate >= 90 ? '#16a34a' : g.rate >= 75 ? '#d97706' : '#dc2626'
              }}
            />
          </div>
          <span className="text-sm font-bold text-gray-700 w-12 text-right">{g.rate}%</span>
          <span className="text-xs text-gray-400 w-16">{g.present}/{g.total}</span>
        </div>
      ))}
    </div>
  );
}

// ── Main Component ────────────────────────────────────────────────────────────
export default function AnalyticsDashboard() {
  const [trend, setTrend] = useState<any[]>([]);
  const [grade, setGrade] = useState<any[]>([]);
  const [late, setLate] = useState<any[]>([]);
  const [stats, setStats] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([
      api.getWeeklyTrend(),
      api.getGradeSummary(),
      api.getLateArrivals(),
      api.getAttendanceStats(),
    ]).then(([t, g, l, s]) => {
      setTrend(t?.trend ?? []);
      setGrade(g?.grades ?? []);
      setLate(l?.records ?? []);
      setStats(s);
    }).catch(console.error).finally(() => setLoading(false));
  }, []);

  if (loading) return (
    <div className="flex items-center justify-center py-16">
      <div className="w-8 h-8 border-4 border-purple-500 border-t-transparent rounded-full animate-spin" />
    </div>
  );

  const avgRate = trend.length ? Math.round(trend.reduce((s, d) => s + d.rate, 0) / trend.length) : 0;
  const bestDay = trend.length ? trend.reduce((a, b) => a.rate > b.rate ? a : b) : null;

  return (
    <div className="space-y-6">
      {/* KPI row */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {[
          { label: '7-Day Avg Rate', value: `${avgRate}%`, icon: '📈', color: 'text-purple-600', bg: 'bg-purple-50' },
          { label: 'Present Today', value: stats?.present_students ?? '—', icon: '✅', color: 'text-green-600', bg: 'bg-green-50' },
          { label: 'Late Today', value: late.length, icon: '⏰', color: 'text-orange-600', bg: 'bg-orange-50' },
          { label: 'Best Day', value: bestDay?.day ?? '—', icon: '🏆', color: 'text-blue-600', bg: 'bg-blue-50' },
        ].map(k => (
          <div key={k.label} className={`${k.bg} rounded-2xl p-5 border border-white`}>
            <div className="text-2xl mb-2">{k.icon}</div>
            <p className={`text-3xl font-bold ${k.color}`}>{k.value}</p>
            <p className="text-xs text-gray-500 mt-1">{k.label}</p>
          </div>
        ))}
      </div>

      {/* Trend chart */}
      <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-6">
        <h3 className="text-base font-bold text-gray-900 mb-4">7-Day Attendance Trend</h3>
        <TrendChart data={trend} />
      </div>

      {/* Grade breakdown + Late arrivals */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-6">
          <h3 className="text-base font-bold text-gray-900 mb-4">Attendance by Class/Grade</h3>
          <GradeBarChart grades={grade} />
          {!grade.length && <p className="text-gray-400 text-sm">No grade data available.</p>}
        </div>

        <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-6">
          <h3 className="text-base font-bold text-gray-900 mb-1">Late Arrivals Today</h3>
          <p className="text-xs text-gray-400 mb-4">Students who arrived after 08:00</p>
          {late.length === 0 ? (
            <div className="text-center py-6 text-gray-400">
              <p className="text-3xl mb-2">🎉</p>
              <p className="text-sm">No late arrivals today!</p>
            </div>
          ) : (
            <div className="space-y-2 max-h-52 overflow-y-auto">
              {late.map((s, i) => (
                <div key={i} className="flex items-center justify-between py-2 border-b border-gray-50 last:border-0">
                  <div>
                    <p className="text-sm font-medium text-gray-900">{s.full_name}</p>
                    <p className="text-xs text-gray-400">{s.grade_level}</p>
                  </div>
                  <div className="text-right">
                    <p className="text-sm font-bold text-orange-600">{s.arrival_time}</p>
                    <p className="text-xs text-gray-400">+{s.minutes_late} min</p>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
