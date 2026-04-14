'use client';
import { useEffect, useState } from 'react';
import { api, Notification } from '@/lib/api';

export default function NotificationsPage() {
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.getNotifications().then(setNotifications).catch(console.error).finally(() => setLoading(false));
  }, []);

  const markRead = async (id: string) => {
    await api.markRead(id).catch(console.error);
    setNotifications(prev => prev.map(n => n.id === id ? { ...n, is_read: true } : n));
  };

  const markAll = async () => {
    await api.markAllRead().catch(console.error);
    setNotifications(prev => prev.map(n => ({ ...n, is_read: true })));
  };

  const filtered = notifications.filter(n => !search || n.message?.toLowerCase().includes(search.toLowerCase()) || n.title?.toLowerCase().includes(search.toLowerCase()));
  const unread = notifications.filter(n => !n.is_read).length;

  return (
    <div className="p-8 space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Notifications</h1>
          <p className="text-gray-500 mt-1">{unread} unread</p>
        </div>
        {unread > 0 && (
          <button onClick={markAll} className="text-sm text-blue-600 hover:text-blue-700 font-medium">
            Mark all as read
          </button>
        )}
      </div>

      {/* Search */}
      <div className="relative max-w-md">
        <span className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400">🔍</span>
        <input value={search} onChange={e => setSearch(e.target.value)}
          placeholder="Search notifications..."
          className="w-full pl-10 pr-4 py-3 border border-gray-200 rounded-xl text-sm focus:outline-none focus:border-blue-500 bg-white" />
      </div>

      {loading ? (
        <div className="flex justify-center py-12"><div className="w-8 h-8 border-4 border-blue-500 border-t-transparent rounded-full animate-spin" /></div>
      ) : filtered.length === 0 ? (
        <div className="text-center py-16 text-gray-400">
          <p className="text-5xl mb-4">🔔</p>
          <p className="text-lg font-medium">No notifications yet</p>
        </div>
      ) : (
        <div className="space-y-3">
          {filtered.map(n => (
            <div key={n.id} onClick={() => !n.is_read && markRead(n.id)}
              className={`bg-white rounded-2xl border p-5 cursor-pointer transition ${n.is_read ? 'border-gray-100' : 'border-blue-200 bg-blue-50/30'}`}>
              <div className="flex items-start gap-4">
                <div className={`w-2 h-2 rounded-full mt-2 flex-shrink-0 ${n.is_read ? 'bg-gray-300' : 'bg-blue-500'}`} />
                <div className="flex-1">
                  {n.title && <p className="font-semibold text-gray-900 text-sm">{n.title}</p>}
                  <p className="text-gray-600 text-sm mt-0.5">{n.message}</p>
                  <p className="text-xs text-gray-400 mt-2">{new Date(n.created_at).toLocaleString()}</p>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
