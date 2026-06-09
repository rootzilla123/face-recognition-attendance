'use client';
import { usePathname } from 'next/navigation';
import { useAuth } from '../context/AuthContext';
import Sidebar from './Sidebar';
import ChatbotWidget from './ChatbotWidget';
import { useEffect, useState } from 'react';

const PUBLIC_PATHS = ['/', '/login', '/register', '/complete-profile', '/forgot-password', '/reset-password', '/setup', '/verify-email'];

export default function AppShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const { user } = useAuth();
  const [mounted, setMounted] = useState(false);

  useEffect(() => { setMounted(true); }, []);

  const isPublic = PUBLIC_PATHS.includes(pathname);

  if (!mounted || isPublic || !user) {
    return <>{children}</>;
  }

  return (
    <div className="flex min-h-screen overflow-hidden">
      <Sidebar />
      <main className="flex-1 overflow-y-auto pt-14 lg:pt-0">
        {children}
      </main>
      <ChatbotWidget />
    </div>
  );
}
