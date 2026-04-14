'use client';

import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';

interface AddCameraModalProps {
  isOpen: boolean;
  onClose: () => void;
  onAdd: (camera: CameraConfig) => void;
}

export interface CameraConfig {
  name: string;
  location: string;
  protocol: 'rtsp' | 'http' | 'local';
  streamUrl: string;
  username?: string;
  password?: string;
}

export default function AddCameraModal({ isOpen, onClose, onAdd }: AddCameraModalProps) {
  const [formData, setFormData] = useState<CameraConfig>({
    name: '',
    location: '',
    protocol: 'rtsp',
    streamUrl: '',
    username: '',
    password: ''
  });

  const [errors, setErrors] = useState<Record<string, string>>({});

  const validate = () => {
    const newErrors: Record<string, string> = {};

    if (!formData.name.trim()) {
      newErrors.name = 'Camera name is required';
    }

    if (!formData.location.trim()) {
      newErrors.location = 'Location is required';
    }

    if (!formData.streamUrl.trim()) {
      newErrors.streamUrl = 'Stream URL/Device ID is required';
    }

    if (formData.protocol === 'rtsp' && formData.streamUrl && !formData.streamUrl.startsWith('rtsp://')) {
      newErrors.streamUrl = 'RTSP URL must start with rtsp://';
    }

    if (formData.protocol === 'http' && formData.streamUrl && !formData.streamUrl.startsWith('http')) {
      newErrors.streamUrl = 'HTTP URL must start with http:// or https://';
    }

    if (formData.protocol === 'local' && formData.streamUrl && isNaN(Number(formData.streamUrl))) {
      newErrors.streamUrl = 'Local device must be a number (e.g., 0, 1, 2)';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    if (validate()) {
      onAdd(formData);
      setFormData({
        name: '',
        location: '',
        protocol: 'rtsp',
        streamUrl: '',
        username: '',
        password: ''
      });
      setErrors({});
      onClose();
    }
  };

  const getPlaceholder = () => {
    switch (formData.protocol) {
      case 'rtsp':
        return 'rtsp://192.168.1.100:554/stream';
      case 'http':
        return 'http://192.168.1.100:8080/video';
      case 'local':
        return '0';
      default:
        return '';
    }
  };

  const getHelpText = () => {
    switch (formData.protocol) {
      case 'rtsp':
        return 'RTSP URL format: rtsp://[username:password@]host:port/path';
      case 'http':
        return 'HTTP/HTTPS URL to video stream (MJPEG or similar)';
      case 'local':
        return 'Device index (0 for first camera, 1 for second, etc.)';
      default:
        return '';
    }
  };

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          {/* Backdrop with blur */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.2 }}
            className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50"
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
              className="bg-white rounded-2xl shadow-2xl w-full max-w-2xl mx-4 max-h-[90vh] overflow-y-auto"
              onClick={(e) => e.stopPropagation()}
            >
              {/* Header with stagger */}
              <motion.div
                initial={{ opacity: 0, y: -10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.1 }}
                className="p-6 border-b border-gray-200 bg-gradient-to-r from-blue-50 to-purple-50"
              >
                <div className="flex items-center justify-between">
                  <div>
                    <h2 className="text-2xl font-bold text-gray-900">Add New Camera</h2>
                    <p className="text-gray-600 mt-1">Configure your CCTV camera connection</p>
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

              <form onSubmit={handleSubmit} className="p-6 space-y-4">
                {/* Camera Name */}
                <motion.div
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: 0.15 }}
                >
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Camera Name *
                  </label>
                  <input
                    type="text"
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                    placeholder="e.g., Main Entrance Camera"
                  />
                  {errors.name && <p className="text-red-500 text-sm mt-1">{errors.name}</p>}
                </motion.div>

                {/* Location */}
                <motion.div
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: 0.2 }}
                >
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Location *
                  </label>
                  <input
                    type="text"
                    value={formData.location}
                    onChange={(e) => setFormData({ ...formData, location: e.target.value })}
                    className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                    placeholder="e.g., Main Gate, Building A"
                  />
                  {errors.location && <p className="text-red-500 text-sm mt-1">{errors.location}</p>}
                </motion.div>

                {/* Protocol */}
                <motion.div
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: 0.25 }}
                >
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Connection Protocol *
                  </label>
                  <div className="grid grid-cols-3 gap-3">
                    {(['rtsp', 'http', 'local'] as const).map((protocol, index) => (
                      <motion.button
                        key={protocol}
                        type="button"
                        whileHover={{ scale: 1.05, y: -2 }}
                        whileTap={{ scale: 0.95 }}
                        onClick={() => setFormData({ ...formData, protocol, streamUrl: '' })}
                        className={`px-4 py-3 rounded-xl border-2 font-medium transition-all ${
                          formData.protocol === protocol
                            ? 'border-blue-500 bg-gradient-to-br from-blue-50 to-purple-50 text-blue-700 shadow-lg'
                            : 'border-gray-300 bg-white text-gray-700 hover:border-gray-400 hover:shadow-md'
                        }`}
                      >
                        <div className="text-2xl mb-1">
                          {protocol === 'rtsp' ? '📡' : protocol === 'http' ? '🌐' : '💻'}
                        </div>
                        {protocol.toUpperCase()}
                      </motion.button>
                    ))}
                  </div>
                </motion.div>

                {/* Stream URL */}
                <motion.div
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: 0.3 }}
                >
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    {formData.protocol === 'local' ? 'Device Index *' : 'Stream URL *'}
                  </label>
                  <input
                    type="text"
                    value={formData.streamUrl}
                    onChange={(e) => setFormData({ ...formData, streamUrl: e.target.value })}
                    className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent font-mono text-sm transition-all"
                    placeholder={getPlaceholder()}
                  />
                  <p className="text-gray-500 text-xs mt-1">{getHelpText()}</p>
                  {errors.streamUrl && <p className="text-red-500 text-sm mt-1">{errors.streamUrl}</p>}
                </motion.div>

                {/* Authentication */}
                {(formData.protocol === 'rtsp' || formData.protocol === 'http') && (
                  <motion.div
                    initial={{ opacity: 0, height: 0 }}
                    animate={{ opacity: 1, height: 'auto' }}
                    exit={{ opacity: 0, height: 0 }}
                    className="grid grid-cols-2 gap-4"
                  >
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Username (optional)
                      </label>
                      <input
                        type="text"
                        value={formData.username}
                        onChange={(e) => setFormData({ ...formData, username: e.target.value })}
                        className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                        placeholder="admin"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Password (optional)
                      </label>
                      <input
                        type="password"
                        value={formData.password}
                        onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                        className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                        placeholder="••••••••"
                        autoComplete="new-password"
                      />
                    </div>
                  </motion.div>
                )}

                {/* Info Box */}
                <motion.div
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.35 }}
                  className="bg-blue-50 border border-blue-200 rounded-xl p-4"
                >
                  <h4 className="font-semibold text-blue-900 mb-2">📌 Connection Examples:</h4>
                  <ul className="text-sm text-blue-800 space-y-1">
                    <li><strong>RTSP:</strong> rtsp://admin:password@192.168.1.100:554/stream1</li>
                    <li><strong>HTTP:</strong> http://192.168.1.100:8080/video.mjpg</li>
                    <li><strong>Local Webcam:</strong> 0 (built-in), 1 (first USB), 2 (second USB)</li>
                  </ul>
                </motion.div>

                {/* Webcam Help */}
                {formData.protocol === 'local' && (
                  <motion.div
                    initial={{ opacity: 0, scale: 0.95 }}
                    animate={{ opacity: 1, scale: 1 }}
                    exit={{ opacity: 0, scale: 0.95 }}
                    className="bg-green-50 border border-green-200 rounded-xl p-4"
                  >
                    <h4 className="font-semibold text-green-900 mb-2">💡 Webcam Setup Tips:</h4>
                    <ul className="text-sm text-green-800 space-y-1">
                      <li>• <strong>Device 0:</strong> Usually your built-in laptop camera</li>
                      <li>• <strong>Device 1:</strong> Usually your first USB webcam</li>
                      <li>• <strong>Device 2+:</strong> Additional USB webcams</li>
                      <li>• Close other apps using the webcam (Zoom, Teams, etc.)</li>
                      <li>• If one index doesn't work, try the next number</li>
                    </ul>
                  </motion.div>
                )}

                {/* Premium Buttons */}
                <motion.div
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.4 }}
                  className="flex gap-3 pt-4"
                >
                  <motion.button
                    type="button"
                    whileHover={{ scale: 1.02 }}
                    whileTap={{ scale: 0.98 }}
                    onClick={onClose}
                    className="flex-1 px-6 py-3 border-2 border-gray-300 rounded-xl text-gray-700 font-medium hover:bg-gray-50 hover:border-gray-400 transition-all"
                  >
                    Cancel
                  </motion.button>
                  <motion.button
                    type="submit"
                    whileHover={{ scale: 1.02, boxShadow: "0 10px 30px rgba(59, 130, 246, 0.3)" }}
                    whileTap={{ scale: 0.98 }}
                    className="flex-1 px-6 py-3 bg-gradient-to-r from-blue-600 to-purple-600 text-white rounded-xl font-medium hover:from-blue-700 hover:to-purple-700 transition-all shadow-lg"
                  >
                    Add Camera
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
