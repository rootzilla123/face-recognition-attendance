'use client';

import { useState, useEffect, useRef } from 'react';
import { pb } from '@/lib/pocketbase';

interface MJPEGCameraFeedProps {
  cameraId: string;
  locationName: string;
  status: 'online' | 'offline' | 'error';
  apiBaseUrl?: string;
}

export default function MJPEGCameraFeed({
  cameraId,
  locationName,
  status,
  apiBaseUrl = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:8001'
}: MJPEGCameraFeedProps) {
  const [hasError, setHasError] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const imgRef = useRef<HTMLImageElement>(null);
  const abortRef = useRef<AbortController | null>(null);

  useEffect(() => {
    if (status !== 'online') return;
    setHasError(false);
    setIsLoading(true);

    const controller = new AbortController();
    abortRef.current = controller;

    const token = pb.authStore.token;
    const streamUrl = `${apiBaseUrl}/api/v1/cameras/${cameraId}/stream`;

    fetch(streamUrl, {
      headers: token ? { Authorization: `Bearer ${token}` } : {},
      signal: controller.signal,
    })
      .then(res => {
        if (!res.ok || !res.body) throw new Error('Stream unavailable');
        const reader = res.body.getReader();
        let buffer = new Uint8Array(0);

        const SOI = [0xff, 0xd8];
        const EOI = [0xff, 0xd9];

        function findSequence(arr: Uint8Array, seq: number[], from = 0): number {
          for (let i = from; i <= arr.length - seq.length; i++) {
            if (seq.every((b, j) => arr[i + j] === b)) return i;
          }
          return -1;
        }

        function pump(): Promise<void> {
          return reader.read().then(({ done, value }) => {
            if (done || controller.signal.aborted) return;
            const merged = new Uint8Array(buffer.length + value.length);
            merged.set(buffer);
            merged.set(value, buffer.length);
            buffer = merged;

            let start = findSequence(buffer, SOI);
            while (start !== -1) {
              const end = findSequence(buffer, EOI, start + 2);
              if (end === -1) break;
              const jpeg = buffer.slice(start, end + 2);
              buffer = buffer.slice(end + 2);
              start = findSequence(buffer, SOI);

              const blob = new Blob([jpeg], { type: 'image/jpeg' });
              const url = URL.createObjectURL(blob);
              if (imgRef.current) {
                const old = imgRef.current.src;
                imgRef.current.src = url;
                if (old.startsWith('blob:')) URL.revokeObjectURL(old);
                setIsLoading(false);
              }
            }
            return pump();
          });
        }

        return pump();
      })
      .catch(() => {
        if (!controller.signal.aborted) setHasError(true);
        setIsLoading(false);
      });

    return () => {
      controller.abort();
      if (imgRef.current?.src.startsWith('blob:')) URL.revokeObjectURL(imgRef.current.src);
    };
  }, [cameraId, status, apiBaseUrl]);

  const statusColor = status === 'online' ? 'bg-green-500' : status === 'error' ? 'bg-red-500' : 'bg-gray-500';
  const statusText = status === 'online' ? 'Online' : status === 'error' ? 'Error' : 'Offline';

  return (
    <div className="relative bg-gray-900 rounded-lg overflow-hidden shadow-lg">
      <div className="absolute top-0 left-0 right-0 z-10 bg-gradient-to-b from-black/70 to-transparent p-3">
        <div className="flex items-center justify-between">
          <div>
            <h3 className="text-white font-semibold text-sm">{locationName}</h3>
            <p className="text-gray-300 text-xs">Camera {cameraId}</p>
          </div>
          <div className="flex items-center gap-2">
            <div className={`w-2 h-2 rounded-full ${statusColor} animate-pulse`} />
            <span className="text-white text-xs">{statusText}</span>
          </div>
        </div>
      </div>

      <div className="aspect-video bg-gray-800 flex items-center justify-center">
        {status !== 'online' && (
          <div className="text-center p-6">
            <div className="text-4xl mb-2">{status === 'error' ? '⚠️' : '📹'}</div>
            <p className={`text-sm ${status === 'error' ? 'text-red-400' : 'text-gray-400'}`}>
              {status === 'error' ? 'Connection Error' : 'Camera Offline'}
            </p>
          </div>
        )}
        {status === 'online' && isLoading && !hasError && (
          <div className="text-center p-6">
            <div className="text-blue-400 text-4xl mb-2">⏳</div>
            <p className="text-blue-400 text-sm">Loading stream...</p>
          </div>
        )}
        {status === 'online' && hasError && (
          <div className="text-center p-6">
            <div className="text-red-400 text-4xl mb-2">⚠️</div>
            <p className="text-red-400 text-sm">Failed to load stream</p>
          </div>
        )}
        {/* img is always rendered when online so ref is available */}
        {status === 'online' && (
          <img
            ref={imgRef}
            alt={locationName}
            className="w-full h-full object-cover"
            style={{ display: isLoading || hasError ? 'none' : 'block' }}
          />
        )}
      </div>
    </div>
  );
}
