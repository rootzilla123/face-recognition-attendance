'use client';

import RouteGuard from '../components/RouteGuard';

import { useState, useEffect } from 'react';
import { api } from '@/lib/api';
import Toast from '@/app/components/Toast';
import ConfirmDialog from '@/app/components/ConfirmDialog';

interface Camera {
  id: number;
  name: string;
  location: string;
  stream_url: string;
  protocol: string;
  is_active: boolean;
  frame_rate: number;
  status: string;
  created_at: string;
}

interface EditingCamera {
  id: number;
  name: string;
  location: string;
  frame_rate: number;
}

interface ToastMessage {
  message: string;
  type: 'success' | 'error' | 'info' | 'warning';
}

function SettingsContent() {
  const [cameras, setCameras] = useState<Camera[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [testingCamera, setTestingCamera] = useState<number | null>(null);
  const [editingCamera, setEditingCamera] = useState<EditingCamera | null>(null);
  const [deletingCamera, setDeletingCamera] = useState<number | null>(null);
  const [activeTab, setActiveTab] = useState<'cameras' | 'performance'>('cameras');
  const [error, setError] = useState<string | null>(null);
  const [toast, setToast] = useState<ToastMessage | null>(null);
  const [confirmDialog, setConfirmDialog] = useState<{
    title: string;
    message: string;
    onConfirm: () => void;
  } | null>(null);

  const showToast = (message: string, type: 'success' | 'error' | 'info' | 'warning') => {
    setToast({ message, type });
  };

  useEffect(() => {
    loadCameras();
  }, []);

  const loadCameras = async () => {
    try {
      setIsLoading(true);
      setError(null);
      const response = await api.get('/cameras');
      // api.get returns the data directly, not wrapped in .data
      setCameras(response);
    } catch (error: any) {
      console.error('Error loading cameras:', error);
      const errorMsg = error.response?.data?.detail || error.message || 'Failed to load cameras';
      setError(errorMsg);
      // Set empty array on error so UI doesn't break
      setCameras([]);
    } finally {
      setIsLoading(false);
    }
  };

  const testConnection = async (cameraId: number) => {
    setTestingCamera(cameraId);
    try {
      const response = await api.get(`/cameras/${cameraId}/status`);
      showToast(`Camera Status: ${response.status || response.state || 'responded'}`, 'info');
    } catch (error) {
      showToast('Failed to test camera connection', 'error');
    } finally {
      setTestingCamera(null);
    }
  };

  const toggleCamera = async (cameraId: number, currentStatus: boolean) => {
    // Confirmation dialog when disabling
    if (currentStatus) {
      setConfirmDialog({
        title: 'Disable Camera?',
        message: 'This will:\n• Stop the video stream\n• Stop face recognition\n• Hide the camera from live feeds\n• Stop attendance marking\n\nYou can re-enable it anytime from Settings.',
        onConfirm: async () => {
          setConfirmDialog(null);
          await performToggle(cameraId, currentStatus);
        }
      });
    } else {
      await performToggle(cameraId, currentStatus);
    }
  };

  const performToggle = async (cameraId: number, currentStatus: boolean) => {
    try {
      const action = currentStatus ? 'stop' : 'start';
      
      // Call the start/stop endpoint
      await api.post(`/cameras/${cameraId}/${action}`, {});
      
      // Update local state
      setCameras(prev => prev.map(cam =>
        cam.id === cameraId ? { ...cam, is_active: !currentStatus } : cam
      ));
      
      if (currentStatus) {
        showToast('Camera disabled successfully! It will no longer appear in live feeds.', 'success');
      } else {
        showToast('Camera enabled successfully! It is now streaming and will appear in live feeds.', 'success');
      }
    } catch (error) {
      showToast(`Failed to ${currentStatus ? 'disable' : 'enable'} camera. Please try again.`, 'error');
    }
  };

  const startEdit = (camera: Camera) => {
    setEditingCamera({
      id: camera.id,
      name: camera.name,
      location: camera.location,
      frame_rate: camera.frame_rate
    });
  };

  const cancelEdit = () => {
    setEditingCamera(null);
  };

  const saveEdit = async () => {
    if (!editingCamera) return;

    try {
      await api.put(`/cameras/${editingCamera.id}`, {
        name: editingCamera.name,
        location: editingCamera.location,
        frame_rate: editingCamera.frame_rate
      });
      
      setCameras(prev => prev.map(cam =>
        cam.id === editingCamera.id
          ? { ...cam, name: editingCamera.name, location: editingCamera.location, frame_rate: editingCamera.frame_rate }
          : cam
      ));
      
      setEditingCamera(null);
      showToast('Camera updated successfully!', 'success');
    } catch (error) {
      showToast('Failed to update camera', 'error');
    }
  };

  const confirmDelete = (cameraId: number) => {
    setDeletingCamera(cameraId);
  };

  const cancelDelete = () => {
    setDeletingCamera(null);
  };

  const deleteCamera = async (cameraId: number) => {
    try {
      await api.delete(`/cameras/${cameraId}`);
      setCameras(prev => prev.filter(cam => cam.id !== cameraId));
      setDeletingCamera(null);
      showToast('Camera deleted successfully!', 'success');
    } catch (error) {
      showToast('Failed to delete camera', 'error');
    }
  };

  return (
    <>
      {toast && (
        <Toast
          message={toast.message}
          type={toast.type}
          onClose={() => setToast(null)}
        />
      )}
      {confirmDialog && (
        <ConfirmDialog
          title={confirmDialog.title}
          message={confirmDialog.message}
          confirmText="Yes, Continue"
          cancelText="Cancel"
          onConfirm={confirmDialog.onConfirm}
          onCancel={() => setConfirmDialog(null)}
          type="warning"
        />
      )}
      <div className="p-8">
      <div className="mb-6">
        <h1 className="text-display font-bold text-gray-800">Settings</h1>
        <p className="text-h3 text-gray-600 mt-2">Manage cameras and system configuration</p>
      </div>

      {/* Tabs */}
      <div className="flex gap-4 mb-6 border-b border-gray-200">
        <button
          onClick={() => setActiveTab('cameras')}
          className={`px-4 py-2 font-medium transition-colors text-body ${
            activeTab === 'cameras'
              ? 'text-primary-600 border-b-2 border-primary-600'
              : 'text-gray-600 hover:text-gray-800'
          }`}
        >
          📹 Camera Management
        </button>
        <button
          onClick={() => setActiveTab('performance')}
          className={`px-4 py-2 font-medium transition-colors text-body ${
            activeTab === 'performance'
              ? 'text-primary-600 border-b-2 border-primary-600'
              : 'text-gray-600 hover:text-gray-800'
          }`}
        >
          ⚡ Performance Settings
        </button>
      </div>

      {/* Camera Management Tab */}
      {activeTab === 'cameras' && (
        <>
          {isLoading ? (
            <div className="text-center py-12">
              <div className="text-display mb-4">⏳</div>
              <p className="text-body text-gray-600">Loading cameras...</p>
            </div>
          ) : error ? (
            <div className="bg-error-50 border border-error-200 rounded-lg p-6 text-center">
              <div className="text-display mb-4">❌</div>
              <h2 className="text-h3 font-bold text-error-800 mb-2">Error Loading Cameras</h2>
              <p className="text-body text-error-600 mb-4">{error}</p>
              <button
                onClick={loadCameras}
                className="px-4 py-2 bg-error-600 text-white rounded-lg font-medium hover:bg-error-700 text-body"
              >
                Retry
              </button>
            </div>
          ) : !cameras || cameras.length === 0 ? (
            <div className="bg-white rounded-lg shadow p-12 text-center">
              <div className="text-display mb-4">📹</div>
              <h2 className="text-h2 font-bold text-gray-800 mb-2">No Cameras Configured</h2>
              <p className="text-body text-gray-600">Go to the Cameras page to add your first camera</p>
            </div>
          ) : (
            <div className="space-y-4">
              {cameras.map((camera) => (
                <div key={camera.id} className="bg-white rounded-lg shadow p-6">
                  {editingCamera?.id === camera.id ? (
                    // Edit Mode
                    <div className="space-y-4">
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">
                          Camera Name
                        </label>
                        <input
                          type="text"
                          value={editingCamera.name}
                          onChange={(e) => setEditingCamera({ ...editingCamera, name: e.target.value })}
                          className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                        />
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">
                          Location
                        </label>
                        <input
                          type="text"
                          value={editingCamera.location}
                          onChange={(e) => setEditingCamera({ ...editingCamera, location: e.target.value })}
                          className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                        />
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">
                          Frame Rate (FPS)
                        </label>
                        <input
                          type="number"
                          min="1"
                          max="30"
                          value={editingCamera.frame_rate}
                          onChange={(e) => setEditingCamera({ ...editingCamera, frame_rate: parseInt(e.target.value) })}
                          className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                        />
                        <p className="text-xs text-gray-500 mt-1">Lower frame rate = better performance</p>
                      </div>
                      <div className="flex gap-2">
                        <button
                          onClick={saveEdit}
                          className="px-4 py-2 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700"
                        >
                          Save Changes
                        </button>
                        <button
                          onClick={cancelEdit}
                          className="px-4 py-2 bg-gray-200 text-gray-800 rounded-lg font-medium hover:bg-gray-300"
                        >
                          Cancel
                        </button>
                      </div>
                    </div>
                  ) : deletingCamera === camera.id ? (
                    // Delete Confirmation
                    <div className="space-y-4">
                      <div className="flex items-center gap-3 text-red-600">
                        <span className="text-3xl">⚠️</span>
                        <div>
                          <h3 className="text-lg font-semibold">Delete Camera?</h3>
                          <p className="text-sm text-gray-600">
                            Are you sure you want to delete "{camera.name}"? This action cannot be undone.
                          </p>
                        </div>
                      </div>
                      <div className="flex gap-2">
                        <button
                          onClick={() => deleteCamera(camera.id)}
                          className="px-4 py-2 bg-red-600 text-white rounded-lg font-medium hover:bg-red-700"
                        >
                          Yes, Delete
                        </button>
                        <button
                          onClick={cancelDelete}
                          className="px-4 py-2 bg-gray-200 text-gray-800 rounded-lg font-medium hover:bg-gray-300"
                        >
                          Cancel
                        </button>
                      </div>
                    </div>
                  ) : (
                    // View Mode
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <div className="flex items-center gap-3 mb-2">
                          <h3 className="text-xl font-semibold text-gray-800">{camera.name}</h3>
                          <span className={`px-3 py-1 rounded-full text-xs font-medium ${
                            camera.is_active
                              ? 'bg-green-100 text-green-800'
                              : 'bg-gray-100 text-gray-800'
                          }`}>
                            {camera.is_active ? 'Active' : 'Inactive'}
                          </span>
                          <span className={`px-3 py-1 rounded-full text-xs font-medium ${
                            camera.status === 'online'
                              ? 'bg-blue-100 text-blue-800'
                              : camera.status === 'error'
                              ? 'bg-red-100 text-red-800'
                              : 'bg-gray-100 text-gray-800'
                          }`}>
                            {camera.status || 'offline'}
                          </span>
                        </div>
                        
                        <div className="space-y-2 text-sm">
                          <div className="flex items-center gap-2">
                            <span className="text-gray-500 font-medium w-24">Location:</span>
                            <span className="text-gray-800">{camera.location}</span>
                          </div>
                          <div className="flex items-center gap-2">
                            <span className="text-gray-500 font-medium w-24">Protocol:</span>
                            <span className="text-gray-800 uppercase">{camera.protocol}</span>
                          </div>
                          <div className="flex items-center gap-2">
                            <span className="text-gray-500 font-medium w-24">Frame Rate:</span>
                            <span className="text-gray-800">{camera.frame_rate} FPS</span>
                          </div>
                          <div className="flex items-center gap-2">
                            <span className="text-gray-500 font-medium w-24">Stream URL:</span>
                            <code className="text-gray-800 bg-gray-100 px-2 py-1 rounded text-xs">
                              {camera.stream_url}
                            </code>
                          </div>
                          <div className="flex items-center gap-2">
                            <span className="text-gray-500 font-medium w-24">Added:</span>
                            <span className="text-gray-800">
                              {new Date(camera.created_at).toLocaleString()}
                            </span>
                          </div>
                        </div>
                      </div>

                      <div className="flex flex-col gap-2 ml-4">
                        <button
                          onClick={() => testConnection(camera.id)}
                          disabled={testingCamera === camera.id}
                          className="px-4 py-2 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-700 transition-colors disabled:bg-blue-400"
                        >
                          {testingCamera === camera.id ? 'Testing...' : 'Test'}
                        </button>
                        <button
                          onClick={() => startEdit(camera)}
                          className="px-4 py-2 bg-purple-600 text-white rounded-lg text-sm font-medium hover:bg-purple-700"
                        >
                          Edit
                        </button>
                        <button
                          onClick={() => toggleCamera(camera.id, camera.is_active)}
                          className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                            camera.is_active
                              ? 'bg-gray-200 text-gray-800 hover:bg-gray-300'
                              : 'bg-green-600 text-white hover:bg-green-700'
                          }`}
                        >
                          {camera.is_active ? 'Disable' : 'Enable'}
                        </button>
                        <button
                          onClick={() => confirmDelete(camera.id)}
                          className="px-4 py-2 bg-red-600 text-white rounded-lg text-sm font-medium hover:bg-red-700"
                        >
                          Delete
                        </button>
                      </div>
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}

          {/* Connection Tips */}
          <div className="mt-8 bg-blue-50 border border-blue-200 rounded-lg p-6">
            <h3 className="font-semibold text-blue-900 mb-3">📌 Connection Tips:</h3>
            <ul className="text-sm text-blue-800 space-y-2">
              <li><strong>RTSP Cameras:</strong> Make sure your camera supports RTSP and the URL format is correct</li>
              <li><strong>HTTP Cameras:</strong> Verify the camera provides an MJPEG or similar stream format</li>
              <li><strong>Local Cameras:</strong> Ensure the device is connected and the index is correct (0, 1, 2, etc.)</li>
              <li><strong>Network:</strong> Check that cameras are on the same network or accessible via VPN/port forwarding</li>
              <li><strong>Credentials:</strong> Verify username and password if authentication is required</li>
            </ul>
          </div>
        </>
      )}

      {/* Performance Settings Tab */}
      {activeTab === 'performance' && (
        <div className="space-y-6">
          <div className="bg-white rounded-lg shadow p-6">
            <h2 className="text-2xl font-bold text-gray-800 mb-4">⚡ Performance Optimization</h2>
            
            <div className="space-y-6">
              {/* Current System Status */}
              <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
                <h3 className="font-semibold text-blue-900 mb-2">📊 System Status</h3>
                <p className="text-sm text-blue-800">
                  The system automatically adjusts frame rates based on CPU usage to prevent overload.
                  If you experience delays, try the optimizations below.
                </p>
              </div>

              {/* Frame Rate Recommendations */}
              <div>
                <h3 className="font-semibold text-gray-800 mb-3">🎯 Frame Rate Recommendations</h3>
                <div className="space-y-3">
                  <div className="flex items-start gap-3 p-3 bg-green-50 border border-green-200 rounded-lg">
                    <span className="text-2xl">✅</span>
                    <div>
                      <p className="font-medium text-green-900">2-3 FPS (Recommended)</p>
                      <p className="text-sm text-green-800">Best balance of performance and functionality. Suitable for most systems.</p>
                    </div>
                  </div>
                  <div className="flex items-start gap-3 p-3 bg-yellow-50 border border-yellow-200 rounded-lg">
                    <span className="text-2xl">⚠️</span>
                    <div>
                      <p className="font-medium text-yellow-900">4-5 FPS (High Performance)</p>
                      <p className="text-sm text-yellow-800">Requires powerful CPU. May cause throttling on slower systems.</p>
                    </div>
                  </div>
                  <div className="flex items-start gap-3 p-3 bg-red-50 border border-red-200 rounded-lg">
                    <span className="text-2xl">🔥</span>
                    <div>
                      <p className="font-medium text-red-900">6+ FPS (Very High)</p>
                      <p className="text-sm text-red-800">Not recommended. Will likely cause CPU overload and automatic throttling.</p>
                    </div>
                  </div>
                </div>
              </div>

              {/* Quick Actions */}
              <div>
                <h3 className="font-semibold text-gray-800 mb-3">⚡ Quick Optimizations</h3>
                <div className="space-y-3">
                  <button
                    onClick={() => {
                      if (!cameras || cameras.length === 0) {
                        showToast('No cameras available to update', 'warning');
                        return;
                      }
                      setConfirmDialog({
                        title: 'Set All Cameras to 3 FPS?',
                        message: 'This will update all cameras to 3 FPS for optimal performance.',
                        onConfirm: async () => {
                          setConfirmDialog(null);
                          try {
                            for (const camera of cameras) {
                              await api.put(`/cameras/${camera.id}`, { frame_rate: 3 });
                            }
                            await loadCameras();
                            showToast('All cameras set to 3 FPS!', 'success');
                          } catch (error) {
                            showToast('Failed to update cameras', 'error');
                          }
                        }
                      });
                    }}
                    disabled={!cameras || cameras.length === 0}
                    className="w-full px-4 py-3 bg-green-600 text-white rounded-lg font-medium hover:bg-green-700 text-left flex items-center gap-3 disabled:bg-gray-400 disabled:cursor-not-allowed"
                  >
                    <span className="text-2xl">🎯</span>
                    <div>
                      <p className="font-semibold">Set All Cameras to 3 FPS</p>
                      <p className="text-sm opacity-90">Recommended for most systems</p>
                    </div>
                  </button>
                  
                  <button
                    onClick={() => {
                      if (!cameras || cameras.length === 0) {
                        showToast('No cameras available to update', 'warning');
                        return;
                      }
                      setConfirmDialog({
                        title: 'Set All Cameras to 2 FPS?',
                        message: 'This will update all cameras to 2 FPS for maximum performance.',
                        onConfirm: async () => {
                          setConfirmDialog(null);
                          try {
                            for (const camera of cameras) {
                              await api.put(`/cameras/${camera.id}`, { frame_rate: 2 });
                            }
                            await loadCameras();
                            showToast('All cameras set to 2 FPS!', 'success');
                          } catch (error) {
                            showToast('Failed to update cameras', 'error');
                          }
                        }
                      });
                    }}
                    disabled={!cameras || cameras.length === 0}
                    className="w-full px-4 py-3 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 text-left flex items-center gap-3 disabled:bg-gray-400 disabled:cursor-not-allowed"
                  >
                    <span className="text-2xl">⚡</span>
                    <div>
                      <p className="font-semibold">Set All Cameras to 2 FPS</p>
                      <p className="text-sm opacity-90">Maximum performance, lower CPU usage</p>
                    </div>
                  </button>
                </div>
              </div>

              {/* Performance Tips */}
              <div className="bg-purple-50 border border-purple-200 rounded-lg p-4">
                <h3 className="font-semibold text-purple-900 mb-3">💡 Performance Tips</h3>
                <ul className="text-sm text-purple-800 space-y-2">
                  <li>• Lower frame rates reduce CPU usage significantly</li>
                  <li>• Disable cameras you're not actively monitoring</li>
                  <li>• Close other CPU-intensive applications</li>
                  <li>• Consider upgrading to a more powerful CPU for 4+ cameras</li>
                  <li>• The system will automatically throttle if CPU usage is too high</li>
                </ul>
              </div>

              {/* System Requirements */}
              <div className="bg-gray-50 border border-gray-200 rounded-lg p-4">
                <h3 className="font-semibold text-gray-900 mb-3">💻 System Requirements</h3>
                <div className="text-sm text-gray-800 space-y-2">
                  <p><strong>For 4 cameras @ 3 FPS:</strong></p>
                  <ul className="ml-4 space-y-1">
                    <li>• CPU: 4-core @ 2.5GHz (minimum)</li>
                    <li>• RAM: 8GB (minimum)</li>
                    <li>• Network: 10 Mbps per camera</li>
                  </ul>
                  <p className="mt-3"><strong>For 4 cameras @ 5 FPS:</strong></p>
                  <ul className="ml-4 space-y-1">
                    <li>• CPU: 6-core @ 3.0GHz or GPU acceleration</li>
                    <li>• RAM: 16GB (recommended)</li>
                    <li>• Network: 15 Mbps per camera</li>
                  </ul>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
    </>
  );
}

export default function Settings() {
  return <RouteGuard allowedRoles={['admin']}><SettingsContent /></RouteGuard>;
}
