'use client';

import { useState, useEffect } from 'react';

interface CameraFeedProps {
  cameraId: string;
  locationName: string;
  frameData?: string; // Base64 JPEG data
  status: 'online' | 'offline' | 'error';
  lastUpdate?: Date;
}

export default function CameraFeed({
  cameraId,
  locationName,
  frameData,
  status,
  lastUpdate
}: CameraFeedProps) {
  const [imageSrc, setImageSrc] = useState<string>('');

  useEffect(() => {
    if (frameData) {
      setImageSrc(`data:image/jpeg;base64,${frameData}`);
    }
  }, [frameData]);

  const getStatusColor = () => {
    switch (status) {
      case 'online':
        return 'bg-green-500';
      case 'offline':
        return 'bg-gray-500';
      case 'error':
        return 'bg-red-500';
      default:
        return 'bg-gray-500';
    }
  };

  const getStatusText = () => {
    switch (status) {
      case 'online':
        return 'Online';
      case 'offline':
        return 'Offline';
      case 'error':
        return 'Error';
      default:
        return 'Unknown';
    }
  };

  return (
    <div className="relative bg-gray-900 rounded-lg overflow-hidden shadow-lg">
      {/* Camera Header */}
      <div className="absolute top-0 left-0 right-0 z-10 bg-gradient-to-b from-black/70 to-transparent p-3">
        <div className="flex items-center justify-between">
          <div>
            <h3 className="text-white font-semibold text-sm">{locationName}</h3>
            <p className="text-gray-300 text-xs">Camera {cameraId}</p>
          </div>
          <div className="flex items-center gap-2">
            <div className={`w-2 h-2 rounded-full ${getStatusColor()} animate-pulse`}></div>
            <span className="text-white text-xs">{getStatusText()}</span>
          </div>
        </div>
      </div>

      {/* Video Feed */}
      <div className="aspect-video bg-gray-800 flex items-center justify-center">
        {status === 'online' && imageSrc ? (
          <img
            src={imageSrc}
            alt={`${locationName} feed`}
            className="w-full h-full object-cover"
          />
        ) : (
          <div className="text-center p-6">
            {status === 'offline' && (
              <>
                <div className="text-gray-400 text-4xl mb-2">📹</div>
                <p className="text-gray-400 text-sm">Camera Offline</p>
              </>
            )}
            {status === 'error' && (
              <>
                <div className="text-red-400 text-4xl mb-2">⚠️</div>
                <p className="text-red-400 text-sm">Connection Error</p>
              </>
            )}
            {status === 'online' && !imageSrc && (
              <>
                <div className="text-blue-400 text-4xl mb-2">⏳</div>
                <p className="text-blue-400 text-sm">Loading feed...</p>
              </>
            )}
          </div>
        )}
      </div>

      {/* Footer with timestamp */}
      {lastUpdate && (
        <div className="absolute bottom-0 left-0 right-0 bg-black/50 px-3 py-1">
          <p className="text-gray-300 text-xs">
            Last update: {lastUpdate.toLocaleTimeString()}
          </p>
        </div>
      )}
    </div>
  );
}
