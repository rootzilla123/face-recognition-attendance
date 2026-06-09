'use client';
import { useRef, useState } from 'react';
import { pb } from '@/lib/pocketbase';

interface Props {
  student: { student_id: string; full_name: string };
  onClose: () => void;
  onSuccess: () => void;
}

export default function FaceEnrollModal({ student, onClose, onSuccess }: Props) {
  const [preview, setPreview] = useState<string | null>(null);
  const [file, setFile] = useState<File | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [done, setDone] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);

  function handleFile(f: File) {
    setFile(f);
    setPreview(URL.createObjectURL(f));
    setError('');
  }

  function handleDrop(e: React.DragEvent) {
    e.preventDefault();
    const f = e.dataTransfer.files[0];
    if (f?.type.startsWith('image/')) handleFile(f);
  }

  async function handleEnroll() {
    if (!file) return;
    setLoading(true); setError('');
    try {
      const form = new FormData();
      form.append('photo', file);
      // Use pb.authStore.token — stored in localStorage, not cookies
      const token = pb.authStore.token;
      const apiBase = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:8001';
      const res = await fetch(
        `${apiBase}/api/v1/students/${student.student_id}/enroll-face`,
        { method: 'POST', headers: { Authorization: `Bearer ${token}` }, body: form }
      );
      if (!res.ok) {
        const data = await res.json();
        throw new Error(data.detail || 'Enrollment failed');
      }
      setDone(true);
      setTimeout(() => { onSuccess(); onClose(); }, 1500);
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md p-6">
        <div className="flex items-center justify-between mb-5">
          <div>
            <h2 className="text-xl font-bold text-gray-900">Enroll Face</h2>
            <p className="text-sm text-gray-500">{student.full_name} · {student.student_id}</p>
          </div>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600 text-2xl leading-none">×</button>
        </div>

        {done ? (
          <div className="text-center py-8">
            <div className="text-5xl mb-3">✅</div>
            <p className="font-semibold text-gray-800">Face enrolled successfully!</p>
          </div>
        ) : (
          <>
            {/* Drop zone */}
            <div
              onDrop={handleDrop}
              onDragOver={e => e.preventDefault()}
              onClick={() => inputRef.current?.click()}
              className="border-2 border-dashed border-gray-200 rounded-xl p-6 text-center cursor-pointer hover:border-purple-400 hover:bg-purple-50 transition mb-4"
            >
              {preview ? (
                <img src={preview} alt="preview" className="w-40 h-40 object-cover rounded-xl mx-auto" />
              ) : (
                <>
                  <div className="text-4xl mb-2">📷</div>
                  <p className="text-sm text-gray-500">Drop a photo here or <span className="text-purple-600 font-medium">browse</span></p>
                  <p className="text-xs text-gray-400 mt-1">Clear front-facing photo works best</p>
                </>
              )}
              <input ref={inputRef} type="file" accept="image/*" className="hidden"
                onChange={e => { const f = e.target.files?.[0]; if (f) handleFile(f); }} />
            </div>

            {error && <p className="text-sm text-red-500 mb-3">{error}</p>}

            <div className="flex gap-3">
              <button onClick={onClose} className="flex-1 py-2.5 rounded-xl border border-gray-200 text-gray-600 hover:bg-gray-50 transition text-sm font-medium">
                Cancel
              </button>
              <button
                onClick={handleEnroll}
                disabled={!file || loading}
                className="flex-1 py-2.5 rounded-xl bg-gradient-to-r from-purple-600 to-pink-600 text-white font-semibold text-sm hover:opacity-90 disabled:opacity-50 transition"
              >
                {loading ? 'Enrolling...' : 'Enroll Face'}
              </button>
            </div>
          </>
        )}
      </div>
    </div>
  );
}
