'use client';
import RouteGuard from '../components/RouteGuard';

function DemoContent() {
  return (
    <div className="p-8">
      <h1 className="text-3xl font-bold text-gray-900 mb-4">Demo</h1>
      <p className="text-gray-500">Demo page — admin and teacher access only.</p>
    </div>
  );
}

export default function DemoPage() {
  return <RouteGuard allowedRoles={['admin', 'teacher']}><DemoContent /></RouteGuard>;
}
