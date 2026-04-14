'use client';
import { useAuth } from '../context/AuthContext';
import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import AdminDashboard from '../components/dashboards/AdminDashboard';
import TeacherDashboard from '../components/dashboards/TeacherDashboard';
import StudentDashboard from '../components/dashboards/StudentDashboard';
import ParentDashboard from '../components/dashboards/ParentDashboard';

// Skeleton loader
function DashboardSkeleton() {
  return (
    <div className="p-8 space-y-6 animate-pulse">
      <div className="h-8 bg-gray-200 rounded-xl w-64" />
      <div className="h-4 bg-gray-100 rounded-xl w-40" />
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
        {[...Array(4)].map((_, i) => (
          <div key={i} className="bg-white rounded-2xl border border-gray-100 p-6 space-y-3">
            <div className="w-12 h-12 bg-gray-200 rounded-xl" />
            <div className="h-8 bg-gray-200 rounded-lg w-20" />
            <div className="h-4 bg-gray-100 rounded-lg w-32" />
          </div>
        ))}
      </div>
      <div className="bg-white rounded-2xl border border-gray-100 p-6 space-y-3">
        <div className="h-6 bg-gray-200 rounded-lg w-48" />
        {[...Array(5)].map((_, i) => (
          <div key={i} className="h-10 bg-gray-100 rounded-lg" />
        ))}
      </div>
    </div>
  );
}

export default function DashboardPage() {
  const { user, loading } = useAuth();
  const router = useRouter();
  const [mounted, setMounted] = useState(false);

  useEffect(() => { setMounted(true); }, []);

  useEffect(() => {
    if (!loading && !user) router.replace('/login');
    // Redirect OAuth users who haven't completed profile
    if (!loading && user && !user.role) router.replace('/complete-profile');
  }, [user, loading, router]);

  if (!mounted || loading || !user) return <DashboardSkeleton />;
  if (!user.role) return <DashboardSkeleton />;

  if (user.role === 'admin') return <AdminDashboard />;
  if (user.role === 'teacher') return <TeacherDashboard />;
  if (user.role === 'student') return <StudentDashboard />;
  if (user.role === 'parent') return <ParentDashboard />;
  return <DashboardSkeleton />;
}
