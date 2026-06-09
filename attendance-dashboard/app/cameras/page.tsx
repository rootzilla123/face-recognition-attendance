'use client';

import RouteGuard from '../components/RouteGuard';

import { useState, useEffect, useRef } from 'react';
import { useWebSocket } from '@/lib/useWebSocket';
import MJPEGCameraFeed from '@/app/components/MJPEGCameraFeed';
import RecognitionOverlay from '@/app/components/RecognitionOverlay';
import AddCameraModal, { CameraConfig } from '@/app/components/AddCameraModal';
import EditCameraModal, { CameraEditConfig } from '@/app/components/EditCameraModal';
import Toast from '@/app/components/Toast';
import { api } from '@/lib/api';

interface CameraState {
  id: string;
  name: string;
  location: string;
  protocol: string;
  streamUrl: string;
  status: 'online' | 'offline' | 'error';
  frameRate: number;
  isActive: boolean;
  lastUpdate?: Date;
}

interface AttendanceNotification {
  studentId: string;
  studentName: string;
  cameraLocation: string;
  timestamp: string;
  confidence: number;
}

interface Detection {
  x: number;
  y: number;
  width: number;
  height: number;
  student_id?: string;
  student_name?: string;
  confidence?: number;
}

interface RecognitionEvent {
  camera_id: string;
  detections: Detection[];
  timestamp: string;
}

interface ToastMessage {
  message: string;
  type: 'success' | 'error' | 'info' | 'warning';
}

function CamerasContent() {
  const [cameras, setCameras] = useState<CameraState[]>([]);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [editingCamera, setEditingCamera] = useState<CameraEditConfig | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [notifications, setNotifications] = useState<AttendanceNotification[]>([]);
  const [cameraDetections, setCameraDetections] = useState<Record<string, Detection[]>>({});
  const [selectedCamera, setSelectedCamera] = useState<string | null>(null);
  const [toast, setToast] = useState<ToastMessage | null>(null);
  const [liveAlert, setLiveAlert] = useState<AttendanceNotification | null>(null);
  const liveAlertTimer = useRef<NodeJS.Timeout | null>(null);

  const showToast = (message: string, type: 'success' | 'error' | 'info' | 'warning') => {
    setToast({ message, type });
  };

  useEffect(() => {
    loadCameras();
  }, []);

  const loadCameras = async () => {
    try {
      setIsLoading(true);
      const response = await api.get('/cameras');
      const camerasData = Array.isArray(response) ? response : (response.data || []);
      setCameras(camerasData
        .filter((cam: any) => cam.is_active !== false)
        .map((cam: any) => ({
          id: cam.id.toString(),
          name: cam.name,
          location: cam.location,
          protocol: cam.protocol,
          streamUrl: cam.stream_url,
          frameRate: cam.frame_rate || 5,
          isActive: cam.is_active !== false,
          status: 'online'
        })));
    } catch (error) {
      console.error('Error loading cameras:', error);
      setCameras([]);
    } finally {
      setIsLoading(false);
    }
  };

  const handleAddCamera = async (config: CameraConfig) => {
    try {
      const response = await api.post('/cameras', {
        name: config.name,
        location: config.location,
        stream_url: config.streamUrl,
        protocol: config.protocol,
        username: config.username,
        password: config.password,
        is_active: true
      });

      const newCamera: CameraState = {
        id: response.id.toString(),
        name: response.name,
        location: response.location,
        protocol: response.protocol,
        streamUrl: response.stream_url,
        frameRate: response.frame_rate || 5,
        isActive: response.is_active !== false,
        status: 'offline'
      };

      setCameras(prev => [...prev, newCamera]);
      showToast('Camera added successfully!', 'success');
    } catch (error) {
      console.error('Error adding camera:', error);
      showToast('Failed to add camera. Please try again.', 'error');
    }
  };

  const handleDeleteCamera = async (cameraId: string) => {
    if (!confirm('Are you sure you want to delete this camera?')) {
      return;
    }

    try {
      await api.delete(`/cameras/${cameraId}`);
      setCameras(prev => prev.filter(cam => cam.id !== cameraId));
      showToast('Camera deleted successfully!', 'success');
    } catch (error) {
      console.error('Error deleting camera:', error);
      showToast('Failed to delete camera. Please try again.', 'error');
    }
  };

  const handleEditCamera = (camera: CameraState) => {
    setEditingCamera({
      id: camera.id,
      name: camera.name,
      location: camera.location,
      streamUrl: camera.streamUrl,
      protocol: camera.protocol as any,
      frameRate: camera.frameRate,
      isActive: camera.isActive
    });
    setIsEditModalOpen(true);
  };

  const handleSaveCamera = async (config: CameraEditConfig) => {
    try {
      await api.put(`/cameras/${config.id}`, {
        name: config.name,
        location: config.location,
        stream_url: config.streamUrl,
        protocol: config.protocol,
        frame_rate: config.frameRate,
        is_active: config.isActive
      });

      setCameras(prev => prev.map(cam =>
        cam.id === config.id
          ? {
              ...cam,
              name: config.name,
              location: config.location,
              streamUrl: config.streamUrl,
              protocol: config.protocol,
              frameRate: config.frameRate,
              isActive: config.isActive
            }
          : cam
      ));

      showToast('Camera updated successfully!', 'success');
      await loadCameras();
    } catch (error) {
      console.error('Error updating camera:', error);
      showToast('Failed to update camera. Please try again.', 'error');
      throw error;
    }
  };

  const wsUrl = (() => {
    const apiBase = process.env.NEXT_PUBLIC_API_URL ?? `http://${typeof window !== 'undefined' ? window.location.hostname : 'localhost'}:8001`;
    return apiBase.replace('https://', 'wss://').replace('http://', 'ws://') + '/ws/attendance';
  })();

  const { isConnected } = useWebSocket({
    url: wsUrl,
    onMessage: (message) => {
      if (message.type === 'attendance_event') {
        const notification: AttendanceNotification = {
          studentId: message.student_id,
          studentName: message.student_name,
          cameraLocation: message.camera_location,
          timestamp: message.timestamp,
          confidence: message.confidence_score
        };
        
        setNotifications(prev => [notification, ...prev].slice(0, 10));

        // Show live alert banner
        setLiveAlert(notification);
        if (liveAlertTimer.current) clearTimeout(liveAlertTimer.current);
        liveAlertTimer.current = setTimeout(() => setLiveAlert(null), 5000);
        
        const cameraId = cameras.find(c => c.location === message.camera_location)?.id;
        if (cameraId) {
          setCameraDetections(prev => ({
            ...prev,
            [cameraId]: [{
              x: 0,
              y: 0,
              width: 100,
              height: 100,
              student_id: message.student_id,
              student_name: message.student_name,
              confidence: message.confidence_score
            }]
          }));
        }
      } else if (message.type === 'camera_status') {
        setCameras(prev => prev.map(cam =>
          cam.id === String(message.camera_id)
            ? { ...cam, status: message.status }
            : cam
        ));
      } else if (message.type === 'recognition_event') {
        const event = message as unknown as RecognitionEvent;
        setCameraDetections(prev => ({
          ...prev,
          [event.camera_id]: event.detections
        }));
      }
    },
    onConnect: () => console.log('Connected to attendance system'),
    onDisconnect: () => {
      console.log('Disconnected from attendance system');
      setCameras(prev => prev.map(cam => ({ ...cam, status: 'offline' })));
    }
  });

  return (
    <>
      {toast && (
        <Toast
          message={toast.message}
          type={toast.type}
          onClose={() => setToast(null)}
        />
      )}
      
      <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100">
        {/* Hero Header - Full Bleed */}
        <div className="bg-gradient-to-br from-primary-700 via-primary-500 to-cyan-500 text-white py-4 px-6 mb-4">
          <div className="max-w-7xl mx-auto">
            <div className="flex items-center justify-between">
              <div>
                <h1 className="text-h1 font-bold mb-0.5">Live Camera Feeds</h1>
                <p className="text-body opacity-90">Monitor real-time video streams with AI face recognition</p>
              </div>
              <div className="flex items-center gap-2">
                <div className="flex items-center gap-2 bg-white/20 backdrop-blur-sm px-4 py-3 rounded-xl border border-white/30">
                  <div className={`w-3 h-3 rounded-full ${isConnected ? 'bg-success-400' : 'bg-error-400'} animate-pulse`}></div>
                  <span className="text-small font-medium text-white">
                    {isConnected ? 'Connected' : 'Disconnected'}
                  </span>
                </div>
                <button
                  onClick={() => setIsModalOpen(true)}
                  className="px-6 py-3 bg-white text-primary-700 rounded-xl font-medium transition-all duration-300 hover:bg-white/90 transform hover:scale-105 hover:-translate-y-1 flex items-center gap-2 shadow-lg"
                >
                  <span className="text-h3">➕</span>
                  Add Camera
                </button>
              </div>
            </div>
          </div>
        </div>

        <div className="max-w-7xl mx-auto px-6">

        {/* Live Detection Banner */}
        {liveAlert && (
          <div className="fixed top-6 left-1/2 -translate-x-1/2 z-50 animate-bounce-once">
            <div className="flex items-center gap-4 bg-green-500 text-white px-6 py-4 rounded-2xl shadow-2xl border border-green-400">
              <div className="w-12 h-12 bg-white/20 rounded-full flex items-center justify-center text-2xl font-bold">
                {liveAlert.studentName.charAt(0)}
              </div>
              <div>
                <p className="font-bold text-lg">✅ {liveAlert.studentName} checked in!</p>
                <p className="text-green-100 text-sm">{liveAlert.cameraLocation} · {(liveAlert.confidence * 100).toFixed(0)}% confidence</p>
              </div>
              <button onClick={() => setLiveAlert(null)} className="ml-4 text-white/70 hover:text-white text-xl">×</button>
            </div>
          </div>
        )}

        {/* Loading State */}
        {isLoading && (
          <div className="text-center py-12 max-w-md mx-auto">
            <div className="text-display mb-4 animate-bounce">⏳</div>
            <p className="text-h3 text-gray-600">Loading cameras...</p>
          </div>
        )}

        {/* Empty State */}
        {!isLoading && cameras.length === 0 && (
          <div className="bg-white rounded-2xl shadow-lg p-16 text-center border border-gray-200 max-w-2xl mx-auto">
            <div className="text-display mb-6">📹</div>
            <h2 className="text-h1 font-bold text-gray-800 mb-3">No Cameras Added</h2>
            <p className="text-h3 text-gray-600 mb-8">
              Get started by adding your first CCTV camera to begin monitoring
            </p>
            <button
              onClick={() => setIsModalOpen(true)}
              className="px-8 py-4 bg-gradient-to-br from-primary-700 via-primary-500 to-cyan-500 shadow-glow-blue text-white rounded-xl font-medium transition-all duration-300 hover:shadow-glow-blue transform hover:scale-105 hover:-translate-y-1 text-body"
            >
              Add Your First Camera
            </button>
          </div>
        )}

        {/* Camera Grid */}
        {!isLoading && cameras.length > 0 && (
          <>
            {/* Fullscreen View */}
            {selectedCamera && (
              <div className="fixed inset-0 bg-black bg-opacity-95 z-50 flex items-center justify-center p-4">
                <button
                  onClick={() => setSelectedCamera(null)}
                  className="absolute top-6 right-6 bg-white text-gray-800 px-6 py-3 rounded-xl font-medium hover:bg-gray-100 transition-colors z-50 shadow-lg"
                >
                  ✕ Close
                </button>
                {cameras.filter(cam => cam.id === selectedCamera).map((camera) => (
                  <div key={camera.id} className="relative w-full max-w-6xl">
                    <MJPEGCameraFeed
                      cameraId={camera.id}
                      locationName={`${camera.name} - ${camera.location}`}
                      status={camera.status}
                    />
                    {cameraDetections[camera.id] && cameraDetections[camera.id].length > 0 && (
                      <RecognitionOverlay
                        detections={cameraDetections[camera.id]}
                        imageWidth={640}
                        imageHeight={480}
                        autoHideDelay={3000}
                      />
                    )}
                  </div>
                ))}
              </div>
            )}

            {/* Grid View - 6+6 Equal Split (2 cameras per row) */}
            <div className="grid grid-cols-12 gap-3 mb-4">
              {cameras.map((camera) => (
                <div key={camera.id} className="col-span-12 lg:col-span-6 relative group bg-white rounded-2xl shadow-lg overflow-hidden border border-gray-200 hover:shadow-2xl transition-shadow">
                  <div 
                    className="relative cursor-pointer"
                    onClick={() => setSelectedCamera(camera.id)}
                  >
                    <MJPEGCameraFeed
                      cameraId={camera.id}
                      locationName={`${camera.name} - ${camera.location}`}
                      status={camera.status}
                    />
                    {cameraDetections[camera.id] && cameraDetections[camera.id].length > 0 && (
                      <RecognitionOverlay
                        detections={cameraDetections[camera.id]}
                        imageWidth={640}
                        imageHeight={480}
                        autoHideDelay={3000}
                      />
                    )}
                    {/* Click to Expand Hint */}
                    <div className="absolute inset-0 bg-black bg-opacity-0 hover:bg-opacity-20 transition-all flex items-center justify-center opacity-0 group-hover:opacity-100">
                      <div className="bg-white text-gray-800 px-6 py-3 rounded-xl font-medium shadow-lg transform scale-95 group-hover:scale-100 transition-transform">
                        🔍 Click to Enlarge
                      </div>
                    </div>
                  </div>
                  {/* Action Buttons */}
                  <div className="absolute top-4 right-4 flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity z-20">
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        handleEditCamera(camera);
                      }}
                      className="bg-blue-500 text-white p-3 rounded-xl hover:bg-blue-600 shadow-lg transform hover:scale-110 transition-all"
                      title="Edit camera settings"
                    >
                      ⚙️
                    </button>
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        handleDeleteCamera(camera.id);
                      }}
                      className="bg-red-500 text-white p-3 rounded-xl hover:bg-red-600 shadow-lg transform hover:scale-110 transition-all"
                      title="Delete camera"
                    >
                      🗑️
                    </button>
                  </div>
                  {/* Camera Info Badge */}
                  <div className="absolute bottom-4 left-4 bg-black bg-opacity-70 text-white px-4 py-2 rounded-xl text-small z-10 backdrop-blur-sm">
                    <span className="font-semibold">{camera.frameRate} FPS</span>
                    <span className="mx-2">•</span>
                    <span>{camera.isActive ? 'Active' : 'Inactive'}</span>
                  </div>
                </div>
              ))}
            </div>

            {/* Recent Attendance Notifications */}
            {notifications.length > 0 && (
              <div className="bg-white rounded-2xl shadow-lg p-6 border border-gray-200">
                <div className="flex items-center justify-between mb-6">
                  <div>
                    <h2 className="text-h2 text-gray-900">Recent Detections</h2>
                    <p className="text-small text-gray-500 mt-1">Latest face recognition events</p>
                  </div>
                  <span className="px-4 py-2 bg-success-100 text-success-800 rounded-xl text-small font-medium">
                    {notifications.length} recent
                  </span>
                </div>
                <div className="space-y-3">
                  {notifications.map((notif, index) => (
                    <div
                      key={index}
                      className="flex items-center justify-between p-4 bg-gradient-to-r from-success-50 to-primary-50 rounded-xl border border-success-100 hover:shadow-md transition-shadow"
                    >
                      <div className="flex items-center gap-4">
                        <div className="w-12 h-12 bg-gradient-to-br from-success-500 to-primary-500 rounded-full flex items-center justify-center text-white font-bold text-h3 shadow-lg">
                          {notif.studentName.charAt(0)}
                        </div>
                        <div>
                          <p className="font-semibold text-gray-900 text-body">{notif.studentName}</p>
                          <p className="text-small text-gray-600">{notif.cameraLocation}</p>
                        </div>
                      </div>
                      <div className="text-right">
                        <p className="text-small font-medium text-gray-900">
                          {new Date(notif.timestamp).toLocaleTimeString()}
                        </p>
                        <p className="text-caption text-success-600 font-semibold">
                          {(notif.confidence * 100).toFixed(0)}% confidence
                        </p>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </>
        )}

        {/* Modals */}
        <AddCameraModal
          isOpen={isModalOpen}
          onClose={() => setIsModalOpen(false)}
          onAdd={handleAddCamera}
        />

        <EditCameraModal
          isOpen={isEditModalOpen}
          camera={editingCamera}
          onClose={() => {
            setIsEditModalOpen(false);
            setEditingCamera(null);
          }}
          onSave={handleSaveCamera}
        />
        </div>
      </div>
    </>
  );
}

export default function Cameras() {
  return <RouteGuard allowedRoles={['admin','teacher']}><CamerasContent /></RouteGuard>;
}
