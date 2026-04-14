'use client';

import { useState, useEffect } from 'react';

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
  apiBaseUrl = typeof window !== 'undefined' ? `${window.location.protocol}//${window.location.hostname}:8001` : 'http://localhost:8001'
}: MJPEGCameraFeedProps) {
  const [isLoading, setIsLoading] = useState(true);
  const [hasError, setHasError] = useState(false);
  
  // Construct streamUrl as ${apiBaseUrl}/api/v1/cameras/${cameraId}/stream
  const streamUrl = `${apiBaseUrl}/api/v1/cameras/${cameraId}/stream`;
  
  // Use useEffect hook to watch cameraId prop changes
  useEffect(() => {
    // Reset loading and error states on camera change
    setIsLoading(true);
    setHasError(false);
  }, [cameraId]);
  
  // Add onLoad handler to set isLoading to false
  const handleLoad = () => {
    setIsLoading(false);
  };
  
  // Add onError handler to set hasError to true and isLoading to false
  const handleError = () => {
    setHasError(true);
    setIsLoading(false);
  };
  
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
        {/* Show offline message when status is 'offline' */}
        {status === 'offline' && (
          <div className="text-center p-6">
            <div className="text-gray-400 text-4xl mb-2">📹</div>
            <p className="text-gray-400 text-sm">Camera Offline</p>
          </div>
        )}
        
        {/* Show error message when status is 'error' */}
        {status === 'error' && (
          <div className="text-center p-6">
            <div className="text-red-400 text-4xl mb-2">⚠️</div>
            <p className="text-red-400 text-sm">Connection Error</p>
          </div>
        )}
        
        {/* Show loading indicator when isLoading is true */}
        {status === 'online' && isLoading && !hasError && (
          <div className="text-center p-6">
            <div className="text-blue-400 text-4xl mb-2">⏳</div>
            <p className="text-blue-400 text-sm">Loading stream...</p>
          </div>
        )}
        
        {/* Show error message when hasError is true */}
        {status === 'online' && hasError && (
          <div className="text-center p-6">
            <div className="text-red-400 text-4xl mb-2">⚠️</div>
            <p className="text-red-400 text-sm">Failed to load camera stream</p>
          </div>
        )}
        
        {/* Render img element with src={streamUrl} */}
        {status === 'online' && (
          <img
            src={streamUrl}
            alt={locationName}
            className="w-full h-full object-cover"
            onLoad={handleLoad}
            onError={handleError}
            style={{ display: isLoading || hasError ? 'none' : 'block' }}
          />
        )}
      </div>
    </div>
  );
}
