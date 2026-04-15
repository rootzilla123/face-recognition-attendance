'use client';
import { useEffect, useState, Suspense } from 'react';
import { useSearchParams, useRouter } from 'next/navigation';
import Link from 'next/link';
import { pb } from '@/lib/pocketbase';

function VerifyEmailContent() {
  const params = useSearchParams();
  const router = useRouter();
  const [status, setStatus] = useState<'verifying' | 'success' | 'error'>('verifying');
  const [error, setError] = useState('');

  useEffect(() => {
    const token = params.get('token');
    if (!token) { setStatus('error'); setError('No verification token found.'); return; }
    pb.collection('users').confirmVerification(token)
      .then(() => { setStatus('success'); setTimeout(() => router.replace('/login'), 3000); })
      .catch(e => { setStatus('error'); setError(e.message || 'Verification failed'); });
  }, []);

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-950 via-gray-900 to-blue-950 flex items-center justify-center px-4">
      <div className="text-center max-w-md">
        {status === 'verifying' && (
          <>
            <div className="w-12 h-12 border-4 border-blue-500 border-t-transparent rounded-full animate-spin mx-auto mb-4" />
            <p className="text-white text-lg">Verifying your email...</p>
          </>
        )}
        {status === 'success' && (
          <>
            <div className="text-6xl mb-4">✅</div>
            <h1 className="text-2xl font-bold text-white mb-2">Email verified!</h1>
            <p className="text-gray-400 mb-6">Redirecting to login...</p>
            <Link href="/login" className="text-blue-400 hover:text-blue-300 text-sm">Go to login now</Link>
          </>
        )}
        {status === 'error' && (
          <>
            <div className="text-6xl mb-4">❌</div>
            <h1 className="text-2xl font-bold text-white mb-2">Verification failed</h1>
            <p className="text-red-400 mb-6 text-sm">{error}</p>
            <Link href="/login" className="text-blue-400 hover:text-blue-300 text-sm">Back to login</Link>
          </>
        )}
      </div>
    </div>
  );
}

export default function VerifyEmailPage() {
  return (
    <Suspense>
      <VerifyEmailContent />
    </Suspense>
  );
}
