'use client';
import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import ParentDashboard from '../components/dashboards/ParentDashboard';
import { useAuth } from '../context/AuthContext';

export default function ChildrenPage() {
  const { user } = useAuth();
  const router = useRouter();
  useEffect(() => {
    if (user && user.role !== 'parent') router.replace('/dashboard');
  }, [user, router]);
  return <ParentDashboard />;
}
