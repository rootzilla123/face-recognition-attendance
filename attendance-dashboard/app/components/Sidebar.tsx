'use client';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useEffect, useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { api } from '@/lib/api';
import Logo from './Logo';

const NAV_BY_ROLE: Record<string, { name: string; path: string; icon: string; description: string }[]> = {
  admin: [
    { name: 'Dashboard', path: '/dashboard', icon: '📊', description: 'Overview & Stats' },
    { name: 'Live Cameras', path: '/cameras', icon: '📹', description: 'Monitor Feeds' },
    { name: 'Students', path: '/students', icon: '👥', description: 'Manage Students' },
    { name: 'Marks', path: '/marks', icon: '📝', description: 'Examination Marks' },
    { name: 'Announcements', path: '/announcements', icon: '📢', description: 'Post Announcements' },
    { name: 'Reports', path: '/reports', icon: '📄', description: 'Attendance Reports' },
    { name: 'Settings', path: '/settings', icon: '⚙️', description: 'Configuration' },
    { name: 'User Management', path: '/admin', icon: '👤', description: 'Manage Users' },
  ],
  teacher: [
    { name: 'Dashboard', path: '/dashboard', icon: '📊', description: 'Overview & Stats' },
    { name: 'Live Cameras', path: '/cameras', icon: '📹', description: 'Monitor Feeds' },
    { name: 'Students', path: '/students', icon: '👥', description: 'View Students' },
    { name: 'Marks', path: '/marks', icon: '📝', description: 'Record Marks' },
    { name: 'Announcements', path: '/announcements', icon: '📢', description: 'Post Announcements' },
    { name: 'Reports', path: '/reports', icon: '📄', description: 'Attendance Reports' },
    { name: 'My Profile', path: '/teacher-profile', icon: '👤', description: 'My Profile & Class' },
  ],
  student: [
    { name: 'My Dashboard', path: '/dashboard', icon: '📊', description: 'My Attendance' },
    { name: 'My Marks', path: '/my-marks', icon: '📝', description: 'Examination Results' },
    { name: 'Announcements', path: '/announcements', icon: '📢', description: 'School News' },
    { name: 'My Profile', path: '/profile', icon: '👤', description: 'My Profile' },
  ],
  parent: [
    { name: 'Dashboard', path: '/dashboard', icon: '📊', description: 'Children Overview' },
    { name: 'My Children', path: '/children', icon: '👨‍👧', description: 'Attendance & Marks' },
    { name: 'Announcements', path: '/announcements', icon: '📢', description: 'School News' },
    { name: 'Notifications', path: '/notifications', icon: '🔔', description: 'My Alerts' },
    { name: 'Preferences', path: '/preferences', icon: '⚙️', description: 'Notification Settings' },
  ],
};

const roleColors: Record<string, string> = {
  admin: 'from-purple-500 to-pink-600',
  teacher: 'from-blue-500 to-cyan-600',
  student: 'from-green-500 to-teal-600',
  parent: 'from-orange-500 to-amber-600',
};

export default function Sidebar() {
  const pathname = usePathname();
  const { user, logout } = useAuth();
  const [stats, setStats] = useState({ present: 0, total: 0, percentage: 0 });
  const [unread, setUnread] = useState(0);
  const [open, setOpen] = useState(false); // mobile drawer

  const role = user?.role || 'student';
  const navItems = NAV_BY_ROLE[role] || NAV_BY_ROLE.student;
  const color = roleColors[role];

  useEffect(() => {
    if (!user) return;
    if (role === 'admin' || role === 'teacher') {
      api.getAttendanceStats()
        .then(d => setStats({ present: d.present_students, total: d.total_students, percentage: d.attendance_percentage }))
        .catch(() => {});
    }
    api.getUnreadCount().then(d => setUnread(d.unread_count)).catch(() => {});
    const iv = setInterval(() => {
      api.getUnreadCount().then(d => setUnread(d.unread_count)).catch(() => {});
    }, 30000);
    return () => clearInterval(iv);
  }, [user, role]);

  // Real-time notification updates via WebSocket
  useEffect(() => {
    if (!user) return;
    let ws: WebSocket | null = null;
    let reconnectTimer: NodeJS.Timeout | null = null;
    let disposed = false;

    const apiBase = process.env.NEXT_PUBLIC_API_URL ?? `http://${typeof window !== 'undefined' ? window.location.hostname : 'localhost'}:8001`;
    const wsBase = apiBase.replace('https://', 'wss://').replace('http://', 'ws://');

    const connect = () => {
      if (disposed) return;
      try {
        ws = new WebSocket(`${wsBase}/ws/attendance`);
        ws.onmessage = (e) => {
          try {
            const msg = JSON.parse(e.data);
            if (msg.type === 'attendance_event' || msg.type === 'notification') {
              api.getUnreadCount().then(d => setUnread(d.unread_count)).catch(() => {});
            }
          } catch {}
        };
        ws.onclose = () => {
          if (!disposed) reconnectTimer = setTimeout(connect, 5000);
        };
      } catch {}
    };
    connect();
    return () => {
      disposed = true;
      if (reconnectTimer) clearTimeout(reconnectTimer);
      ws?.close();
    };
  }, [user]);

  // Close drawer on route change
  useEffect(() => { setOpen(false); }, [pathname]);

  const SidebarContent = () => (
    <div className="flex flex-col h-full">
      {/* Logo */}
      <div className="p-6 border-b border-gray-700 flex items-center justify-between">
        <Link href="/dashboard" className="flex items-center space-x-3 group">
          <Logo size="sm" />
        </Link>
        {/* Close button - mobile only */}
        <button onClick={() => setOpen(false)} className="lg:hidden text-gray-400 hover:text-white text-xl p-1">✕</button>
      </div>

      {/* Nav */}
      <nav className="flex-1 p-4 space-y-1 overflow-y-auto">
        {navItems.map((item) => {
          const isActive = pathname === item.path;
          return (
            <Link key={item.path} href={item.path}
              className={`flex items-center space-x-3 px-4 py-3 rounded-xl transition-all group ${
                isActive ? `bg-gradient-to-r ${color} shadow-lg` : 'hover:bg-gray-700/50'
              }`}>
              <span className="text-xl flex-shrink-0">{item.icon}</span>
              <div className="flex-1 min-w-0">
                <p className={`text-sm font-semibold truncate ${isActive ? 'text-white' : 'text-gray-200'}`}>{item.name}</p>
                <p className={`text-xs truncate ${isActive ? 'text-white/70' : 'text-gray-400'}`}>{item.description}</p>
              </div>
              {item.name === 'Notifications' && unread > 0 && (
                <span className="bg-red-500 text-white text-xs rounded-full w-5 h-5 flex items-center justify-center font-bold flex-shrink-0">
                  {unread > 9 ? '9+' : unread}
                </span>
              )}
              {isActive && <div className="w-1 h-8 bg-white rounded-full flex-shrink-0" />}
            </Link>
          );
        })}
      </nav>

      {/* Live stats - admin/teacher only */}
      {(role === 'admin' || role === 'teacher') && (
        <div className="px-4 pb-2">
          <div className="bg-gradient-to-br from-green-500/20 to-blue-500/20 rounded-2xl p-4 border border-green-500/30">
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-semibold text-gray-200">Today's Attendance</span>
              <div className="flex items-center gap-1">
                <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse" />
                <span className="text-xs text-green-400">Live</span>
              </div>
            </div>
            <p className="text-2xl font-bold text-white">{stats.percentage.toFixed(0)}%</p>
            <p className="text-xs text-gray-300">{stats.present} of {stats.total} present</p>
            <div className="mt-2 bg-gray-700/50 rounded-full h-1.5 overflow-hidden">
              <div className="h-full bg-gradient-to-r from-green-400 to-blue-500 transition-all duration-500"
                style={{ width: `${stats.percentage}%` }} />
            </div>
          </div>
        </div>
      )}

      {/* User + Logout */}
      <div className="p-4 border-t border-gray-700 space-y-2">
        <div className="flex items-center space-x-3 px-3 py-2 rounded-xl">
          <div className={`w-9 h-9 bg-gradient-to-br ${color} rounded-full flex items-center justify-center shadow-lg flex-shrink-0`}>
            <span className="text-white font-bold text-sm">{user?.name?.[0] || '?'}</span>
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-sm font-semibold text-white truncate">{user?.name}</p>
            <p className="text-xs text-gray-400 capitalize">{role}</p>
          </div>
        </div>
        <button onClick={logout}
          className="w-full flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-red-500/10 hover:bg-red-500/20 border border-red-500/20 text-red-400 hover:text-red-300 transition text-sm font-semibold">
          <span>🚪</span> Sign Out
        </button>
      </div>
    </div>
  );

  return (
    <>
      {/* Mobile top bar */}
      <div className="lg:hidden fixed top-0 left-0 right-0 z-40 bg-gray-950 border-b border-gray-700 flex items-center justify-between px-4 py-3">
        <div className="flex items-center gap-2">
          <Logo size="sm" showText={false} />
          <span className="text-white font-bold text-sm tracking-tight">SHADOMFACEPRO</span>
        </div>
        <button onClick={() => setOpen(true)}
          className="text-gray-300 hover:text-white p-2 rounded-lg hover:bg-gray-700 transition">
          <div className="space-y-1">
            <div className="w-5 h-0.5 bg-current" />
            <div className="w-5 h-0.5 bg-current" />
            <div className="w-5 h-0.5 bg-current" />
          </div>
        </button>
      </div>

      {/* Mobile overlay */}
      {open && (
        <div className="lg:hidden fixed inset-0 z-40 bg-black/60" onClick={() => setOpen(false)} />
      )}

      {/* Mobile drawer */}
      <div className={`lg:hidden fixed top-0 left-0 h-full w-72 bg-gradient-to-b from-gray-950 to-gray-900 z-50 transform transition-transform duration-300 ${open ? 'translate-x-0' : '-translate-x-full'}`}>
        <SidebarContent />
      </div>

      {/* Desktop sidebar */}
      <aside className="hidden lg:flex w-72 bg-gradient-to-b from-gray-950 to-gray-900 text-white flex-col min-h-screen shadow-2xl flex-shrink-0">
        <SidebarContent />
      </aside>

      {/* Mobile top bar spacer */}
      <div className="lg:hidden h-14 flex-shrink-0" />
    </>
  );
}
