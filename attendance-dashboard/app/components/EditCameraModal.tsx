'use client';

import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';

export interface CameraEditConfig {
  id: string;
  name: string;
  location: string;
  streamUrl: string;
  protocol: 'rtsp' | 'http' | 'local';
  username?: string;
  password?: string;
  frameRate: number;
  isActive: boolean;
}

interface EditCameraModalProps {
  isOpen: boolean;
  camera: CameraEditConfig | null;
  onClose: () => void;
  onSave: (config: CameraEditConfig) => Promise<void>;
}

export default function EditCameraModal({ isOpen, camera, onClose, onSave }: EditCameraModalProps) {
  const [formData, setFormData] = useState<CameraEditConfig>({
    id: '',
    name: '',
    location: '',
    streamUrl: '',
    protocol: 'rtsp',
    username: '',
    password: '',
    frameRate: 5,
    isActive: true
  });
  const [isSaving, setIsSaving] = useState(false);

  useEffect(() => {
    if (camera) {
      setFormData(camera);
    }
  }, [camera]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSaving(true);
    
    try {
      await onSave(formData);
      onClose();
    } catch (error) {
      console.error('Error saving camera:', error);
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <AnimatePresence>
      {isOpen && camera && (
        <>
          {/* Premium Backdrop with blur */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.2 }}
            className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-4"
            onClick={onClose}
          >
            {/* Modal with spring animation */}
            <motion.div
              initial={{ scale: 0.9, opacity: 0, y: 20 }}
              animate={{ scale: 1, opacity: 1, y: 0 }}
              exit={{ scale: 0.95, opacity: 0, y: 10 }}
              transition={{ 
                type: "spring", 
                damping: 25, 
                stiffness: 300,
                mass: 0.8
              }}
              className="bg-white rounded-2xl shadow-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto"
              onClick={(e) => e.stopPropagation()}
            >
              {/* Header with stagger */}
              <motion.div
                initial={{ opacity: 0, y: -10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.1 }}
                className="p-6 border-b border-gray-200 bg-gradient-to-r from-purple-50 to-blue-50"
              >
                <div className="flex items-center justify-between">
                  <div>
                    <h2 className="text-2xl font-bold text-gray-900">Edit Camera Settings</h2>
                    <p className="text-gray-600 mt-1">Update camera configuration and performance settings</p>
                  </div>
                  {/* Premium close button */}
                  <motion.button
                    whileHover={{ scale: 1.1, rotate: 90 }}
                    whileTap={{ scale: 0.9 }}
                    onClick={onClose}
                    className="w-10 h-10 rounded-full bg-gray-100 hover:bg-gray-200 flex items-center justify-center text-gray-600 hover:text-gray-900 transition-colors"
                  >
                    ✕
                  </motion.button>
                </div>
              </motion.div>

              <form onSubmit={handleSubmit} className="p-6 space-y-6">
                {/* Basic Information */}
                <motion.div
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: 0.15 }}
                  className="space-y-4"
                >
                  <h3 className="text-lg font-semibold text-gray-800 flex items-center gap-2">
                    <span className="text-xl">📝</span>
                    Basic Information
                  </h3>
                  
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Camera Name *
                    </label>
                    <input
                      type="text"
                      value={formData.name}
                      onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                      className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                      placeholder="e.g., Main Entrance"
                      required
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Location *
                    </label>
                    <input
                      type="text"
                      value={formData.location}
                      onChange={(e) => setFormData({ ...formData, location: e.target.value })}
                      className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                      placeholder="e.g., Building A - Floor 1"
                      required
                    />
                  </div>
                </motion.div>

                {/* Performance Settings */}
                <motion.div
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: 0.2 }}
                  className="space-y-4 bg-gradient-to-br from-blue-50 to-purple-50 p-6 rounded-2xl border border-blue-100"
                >
                  <h3 className="text-lg font-semibold text-gray-800 flex items-center gap-2">
                    <span className="text-xl">⚡</span>
                    Performance Settings
                  </h3>
                  
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Frame Rate (FPS) *
                    </label>
                    <select
                      value={formData.frameRate}
                      onChange={(e) => setFormData({ ...formData, frameRate: parseInt(e.target.value) })}
                      className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                    >
                      <option value={1}>1 FPS (Low CPU - Minimal)</option>
                      <option value={2}>2 FPS (Low CPU - Basic)</option>
                      <option value={3}>3 FPS (Medium CPU - Balanced)</option>
                      <option value={5}>5 FPS (High CPU - Recommended)</option>
                      <option value={10}>10 FPS (Very High CPU - Premium)</option>
                      <option value={15}>15 FPS (Maximum CPU - Real-time)</option>
                    </select>
                    <p className="text-xs text-gray-600 mt-2">
                      Lower frame rates reduce CPU usage. Recommended: 3-5 FPS for face recognition.
                    </p>
                  </div>

                  <motion.div 
                    whileHover={{ scale: 1.02 }}
                    className="flex items-center gap-3 bg-white p-4 rounded-xl border border-gray-200"
                  >
                    <input
                      type="checkbox"
                      id="isActive"
                      checked={formData.isActive}
                      onChange={(e) => setFormData({ ...formData, isActive: e.target.checked })}
                      className="w-5 h-5 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
                    />
                    <label htmlFor="isActive" className="text-sm font-medium text-gray-700">
                      Camera Active (Enable face recognition processing)
                    </label>
                  </motion.div>
                </motion.div>

                {/* Stream Configuration */}
                <motion.div
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: 0.25 }}
                  className="space-y-4"
                >
                  <h3 className="text-lg font-semibold text-gray-800 flex items-center gap-2">
                    <span className="text-xl">📡</span>
                    Stream Configuration
                  </h3>
                  
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Protocol *
                    </label>
                    <select
                      value={formData.protocol}
                      onChange={(e) => setFormData({ ...formData, protocol: e.target.value as any })}
                      className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                    >
                      <option value="rtsp">RTSP (IP Cameras)</option>
                      <option value="http">HTTP (Web Cameras)</option>
                      <option value="local">Local (USB/Webcam)</option>
                    </select>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Stream URL *
                    </label>
                    <input
                      type="text"
                      value={formData.streamUrl}
                      onChange={(e) => setFormData({ ...formData, streamUrl: e.target.value })}
                      className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent font-mono text-sm transition-all"
                      placeholder="rtsp://192.168.1.100:554/stream"
                      required
                    />
                  </div>

                  {formData.protocol !== 'local' && (
                    <motion.div
                      initial={{ opacity: 0, height: 0 }}
                      animate={{ opacity: 1, height: 'auto' }}
                      exit={{ opacity: 0, height: 0 }}
                      className="grid grid-cols-2 gap-4"
                    >
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-2">
                          Username
                        </label>
                        <input
                          type="text"
                          value={formData.username || ''}
                          onChange={(e) => setFormData({ ...formData, username: e.target.value })}
                          className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                          placeholder="admin"
                        />
                      </div>

                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-2">
                          Password
                        </label>
                        <input
                          type="password"
                          value={formData.password || ''}
                          onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                          className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                          placeholder="••••••••"
                          autoComplete="new-password"
                        />
                      </div>
                    </motion.div>
                  )}
                </motion.div>

                {/* Premium Action Buttons */}
                <motion.div
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.3 }}
                  className="flex gap-3 pt-4 border-t border-gray-200"
                >
                  <motion.button
                    type="button"
                    whileHover={{ scale: 1.02 }}
                    whileTap={{ scale: 0.98 }}
                    onClick={onClose}
                    disabled={isSaving}
                    className="flex-1 px-6 py-3 border-2 border-gray-300 text-gray-700 rounded-xl font-medium hover:bg-gray-50 hover:border-gray-400 transition-all disabled:opacity-50"
                  >
                    Cancel
                  </motion.button>
                  <motion.button
                    type="submit"
                    whileHover={{ 
                      scale: 1.02, 
                      boxShadow: "0 10px 30px rgba(59, 130, 246, 0.3)" 
                    }}
                    whileTap={{ scale: 0.98 }}
                    disabled={isSaving}
                    className="flex-1 px-6 py-3 bg-gradient-to-r from-blue-600 to-purple-600 text-white rounded-xl font-medium hover:from-blue-700 hover:to-purple-700 transition-all shadow-lg disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {isSaving ? (
                      <span className="flex items-center justify-center gap-2">
                        <motion.span
                          animate={{ rotate: 360 }}
                          transition={{ duration: 1, repeat: Infinity, ease: "linear" }}
                        >
                          ⏳
                        </motion.span>
                        Saving...
                      </span>
                    ) : (
                      'Save Changes'
                    )}
                  </motion.button>
                </motion.div>
              </form>
            </motion.div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
}
