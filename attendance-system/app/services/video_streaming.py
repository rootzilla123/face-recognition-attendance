"""
Video streaming services for real-time face recognition attendance system.
Handles video capture, frame processing, face detection/recognition, and streaming.
"""

import asyncio
import cv2
import logging
from typing import Any, Dict, Optional, Tuple, List
from datetime import datetime
from app.models import Camera
from sqlalchemy.orm import Session

logger = logging.getLogger(__name__)


class VideoStreamManager:
    """
    Manages video stream connections from multiple camera sources.
    Supports RTSP, HTTP, and local device protocols with automatic reconnection.
    """
    
    def __init__(self):
        self.cameras: Dict[str, dict] = {}
        self.capture_objects: Dict[str, cv2.VideoCapture] = {}
        self.running = False
        
    async def start_camera(self, camera_id: str, stream_url: str, protocol: str) -> bool:
        """
        Start capturing video from a camera source.
        
        Args:
            camera_id: Unique identifier for the camera
            stream_url: URL or device path for the video stream
            protocol: Protocol type (rtsp, http, local)
            
        Returns:
            bool: True if connection successful, False otherwise
        """
        try:
            logger.info(f"Starting camera {camera_id} with protocol {protocol}")
            
            # Create VideoCapture object
            if protocol == "local":
                # For local devices, stream_url should be device index (e.g., "0")
                device_index = int(stream_url)
                cap = cv2.VideoCapture(device_index)
            else:
                # For RTSP and HTTP streams
                cap = cv2.VideoCapture(stream_url)
            
            # Check if camera opened successfully
            if not cap.isOpened():
                logger.error(f"Failed to open camera {camera_id}")
                return False
            
            # Optimize for real-time streaming (reduce latency)
            cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)  # Minimize buffer to 1 frame
            
            # For RTSP streams, use TCP for more reliable connection
            if protocol == "rtsp":
                cap.set(cv2.CAP_PROP_FOURCC, cv2.VideoWriter_fourcc('H', '2', '6', '4'))
            
            # Store camera info and capture object
            self.cameras[camera_id] = {
                "stream_url": stream_url,
                "protocol": protocol,
                "status": "online",
                "last_seen": datetime.now(),
                "error_message": None
            }
            self.capture_objects[camera_id] = cap
            
            logger.info(f"Camera {camera_id} started successfully with real-time optimizations")
            return True
            
        except Exception as e:
            logger.error(f"Error starting camera {camera_id}: {str(e)}")
            self.cameras[camera_id] = {
                "stream_url": stream_url,
                "protocol": protocol,
                "status": "error",
                "last_seen": datetime.now(),
                "error_message": str(e)
            }
            return False
    
    async def stop_camera(self, camera_id: str) -> bool:
        """
        Stop capturing video from a camera source.
        
        Args:
            camera_id: Unique identifier for the camera
            
        Returns:
            bool: True if stopped successfully, False otherwise
        """
        try:
            if camera_id in self.capture_objects:
                self.capture_objects[camera_id].release()
                del self.capture_objects[camera_id]
                
            if camera_id in self.cameras:
                self.cameras[camera_id]["status"] = "offline"
                
            logger.info(f"Camera {camera_id} stopped")
            return True
            
        except Exception as e:
            logger.error(f"Error stopping camera {camera_id}: {str(e)}")
            return False
    
    def get_camera_status(self, camera_id: str) -> Optional[dict]:
        """
        Get the current status of a camera.
        
        Args:
            camera_id: Unique identifier for the camera
            
        Returns:
            dict: Camera status information or None if not found
        """
        return self.cameras.get(camera_id)
    
    def is_camera_online(self, camera_id: str) -> bool:
        """
        Check if a camera is currently online and capturing.
        
        Args:
            camera_id: Unique identifier for the camera
            
        Returns:
            bool: True if camera is online, False otherwise
        """
        camera = self.cameras.get(camera_id)
        return camera is not None and camera["status"] == "online"
    
    async def reconnect_camera(self, camera_id: str) -> bool:
        """
        Attempt to reconnect a camera that has gone offline.
        
        Args:
            camera_id: Unique identifier for the camera
            
        Returns:
            bool: True if reconnection successful, False otherwise
        """
        camera = self.cameras.get(camera_id)
        if not camera:
            logger.warning(f"Cannot reconnect unknown camera {camera_id}")
            return False
        
        logger.info(f"Attempting to reconnect camera {camera_id}")
        
        # Stop existing connection if any
        await self.stop_camera(camera_id)
        
        # Wait a moment before reconnecting
        await asyncio.sleep(1)
        
        # Attempt to restart
        return await self.start_camera(
            camera_id,
            camera["stream_url"],
            camera["protocol"]
        )
    
    async def monitor_connections(self):
        """
        Background task to monitor camera connections and attempt reconnection.
        Runs every 30 seconds to check offline cameras.
        """
        while self.running:
            try:
                for camera_id, camera_info in list(self.cameras.items()):
                    if camera_info["status"] in ["offline", "error"]:
                        logger.info(f"Attempting reconnection for camera {camera_id}")
                        await self.reconnect_camera(camera_id)
                
                # Wait 30 seconds before next check
                await asyncio.sleep(30)
                
            except Exception as e:
                logger.error(f"Error in connection monitor: {str(e)}")
                await asyncio.sleep(30)
    
    async def start_monitoring(self):
        """Start the connection monitoring background task."""
        self.running = True
        asyncio.create_task(self.monitor_connections())
        logger.info("Camera connection monitoring started")
    
    async def stop_monitoring(self):
        """Stop the connection monitoring background task."""
        self.running = False
        logger.info("Camera connection monitoring stopped")
    
    async def stop_all_cameras(self):
        """Stop all active camera connections."""
        for camera_id in list(self.capture_objects.keys()):
            await self.stop_camera(camera_id)
        logger.info("All cameras stopped")
    
    def read_frame(self, camera_id: str) -> Tuple[bool, Optional[any]]:
        """
        Read a single frame from a camera.
        Always gets the latest frame by clearing the buffer.
        
        Args:
            camera_id: Unique identifier for the camera
            
        Returns:
            Tuple[bool, Optional[frame]]: Success status and frame data
        """
        if camera_id not in self.capture_objects:
            return False, None
        
        try:
            cap = self.capture_objects[camera_id]
            
            # Grab 1 frame to clear buffer and get fresher data
            # Reduced from 2 to 1 for less latency
            cap.grab()
            
            # Now retrieve the latest frame
            ret, frame = cap.retrieve()
            
            if ret:
                # Update last_seen timestamp
                self.cameras[camera_id]["last_seen"] = datetime.now()
                return True, frame
            else:
                # Frame read failed, mark camera as error
                self.cameras[camera_id]["status"] = "error"
                self.cameras[camera_id]["error_message"] = "Failed to read frame"
                return False, None
                
        except Exception as e:
            logger.error(f"Error reading frame from camera {camera_id}: {str(e)}")
            self.cameras[camera_id]["status"] = "error"
            self.cameras[camera_id]["error_message"] = str(e)
            return False, None



import base64
from collections import deque
from PIL import Image
import io
import numpy as np


class FrameProcessor:
    """
    Processes video frames for face detection and streaming.
    Handles frame extraction, JPEG encoding, queue management, and parallel processing.
    """
    
    def __init__(self, frame_rate: int = 5, max_queue_size: int = 100):
        """
        Initialize the frame processor.
        
        Args:
            frame_rate: Frames per second to process (1-10)
            max_queue_size: Maximum frames to queue per camera
        """
        self.frame_rate = max(1, min(10, frame_rate))  # Clamp between 1-10
        self.max_queue_size = max_queue_size
        self.frame_queues: Dict[str, deque] = {}
        self.processing_tasks: Dict[str, asyncio.Task] = {}
        self.running = False
        
    def set_frame_rate(self, frame_rate: int):
        """
        Update the frame rate dynamically.
        
        Args:
            frame_rate: New frames per second (1-10)
        """
        self.frame_rate = max(1, min(10, frame_rate))
        logger.info(f"Frame rate updated to {self.frame_rate} FPS")
    
    def encode_frame_jpeg(self, frame: np.ndarray, quality: int = 85) -> Optional[bytes]:
        """
        Encode a frame as JPEG with specified quality.
        
        Args:
            frame: OpenCV frame (numpy array)
            quality: JPEG quality (1-100)
            
        Returns:
            bytes: JPEG encoded frame or None on error
        """
        try:
            # Convert BGR to RGB (OpenCV uses BGR)
            rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            
            # Convert to PIL Image
            pil_image = Image.fromarray(rgb_frame)
            
            # Encode as JPEG
            buffer = io.BytesIO()
            pil_image.save(buffer, format='JPEG', quality=quality)
            
            return buffer.getvalue()
            
        except Exception as e:
            logger.error(f"Error encoding frame to JPEG: {str(e)}")
            return None
    
    def encode_frame_base64(self, frame: np.ndarray, quality: int = 70) -> Optional[str]:
        """
        Encode a frame as Base64 JPEG for streaming.
        
        Args:
            frame: OpenCV frame (numpy array)
            quality: JPEG quality (1-100)
            
        Returns:
            str: Base64 encoded JPEG or None on error
        """
        jpeg_bytes = self.encode_frame_jpeg(frame, quality)
        if jpeg_bytes:
            return base64.b64encode(jpeg_bytes).decode('utf-8')
        return None
    
    def add_frame_to_queue(self, camera_id: str, frame: np.ndarray) -> bool:
        """
        Add a frame to the processing queue for a camera.
        Drops oldest frame if queue is full.
        
        Args:
            camera_id: Unique identifier for the camera
            frame: OpenCV frame to queue
            
        Returns:
            bool: True if frame added, False if dropped
        """
        if camera_id not in self.frame_queues:
            self.frame_queues[camera_id] = deque(maxlen=self.max_queue_size)
        
        queue = self.frame_queues[camera_id]
        
        # Check if queue is at capacity
        if len(queue) >= self.max_queue_size:
            # Drop oldest frame
            queue.popleft()
            logger.warning(f"Frame queue full for camera {camera_id}, dropped oldest frame")
        
        # Add new frame with timestamp
        queue.append({
            "frame": frame,
            "timestamp": datetime.now()
        })
        
        return True
    
    def get_frame_from_queue(self, camera_id: str) -> Optional[dict]:
        """
        Get the next frame from a camera's queue.
        
        Args:
            camera_id: Unique identifier for the camera
            
        Returns:
            dict: Frame data with timestamp or None if queue empty
        """
        if camera_id not in self.frame_queues:
            return None
        
        queue = self.frame_queues[camera_id]
        
        if len(queue) > 0:
            return queue.popleft()
        
        return None
    
    def get_queue_size(self, camera_id: str) -> int:
        """
        Get the current size of a camera's frame queue.
        
        Args:
            camera_id: Unique identifier for the camera
            
        Returns:
            int: Number of frames in queue
        """
        if camera_id not in self.frame_queues:
            return 0
        return len(self.frame_queues[camera_id])
    
    async def process_camera_frames(
        self,
        camera_id: str,
        video_stream_manager: VideoStreamManager,
        on_frame_processed: callable = None
    ):
        """
        Continuously process frames from a camera at the configured frame rate.
        
        Args:
            camera_id: Unique identifier for the camera
            video_stream_manager: VideoStreamManager instance to read frames from
            on_frame_processed: Optional callback function called with each processed frame
        """
        logger.info(f"Started frame processing for camera {camera_id}")
        
        frame_interval = 1.0 / self.frame_rate  # Time between frames
        
        while self.running:
            try:
                # Read frame from camera
                success, frame = video_stream_manager.read_frame(camera_id)
                
                if success and frame is not None:
                    # Add to processing queue
                    self.add_frame_to_queue(camera_id, frame)
                    
                    # Call callback if provided
                    if on_frame_processed:
                        await on_frame_processed(camera_id, frame)
                
                # Wait for next frame based on frame rate
                await asyncio.sleep(frame_interval)
                
            except Exception as e:
                logger.error(f"Error processing frames for camera {camera_id}: {str(e)}")
                await asyncio.sleep(1)  # Wait before retrying
    
    async def start_processing(
        self,
        camera_id: str,
        video_stream_manager: VideoStreamManager,
        on_frame_processed: callable = None
    ):
        """
        Start processing frames for a camera in the background.
        
        Args:
            camera_id: Unique identifier for the camera
            video_stream_manager: VideoStreamManager instance
            on_frame_processed: Optional callback for processed frames
        """
        if camera_id in self.processing_tasks:
            logger.warning(f"Frame processing already running for camera {camera_id}")
            return
        
        self.running = True
        task = asyncio.create_task(
            self.process_camera_frames(camera_id, video_stream_manager, on_frame_processed)
        )
        self.processing_tasks[camera_id] = task
        logger.info(f"Frame processing started for camera {camera_id}")
    
    async def stop_processing(self, camera_id: str):
        """
        Stop processing frames for a camera.
        
        Args:
            camera_id: Unique identifier for the camera
        """
        if camera_id in self.processing_tasks:
            task = self.processing_tasks[camera_id]
            task.cancel()
            try:
                await task
            except asyncio.CancelledError:
                pass
            del self.processing_tasks[camera_id]
            logger.info(f"Frame processing stopped for camera {camera_id}")
    
    async def stop_all_processing(self):
        """Stop processing frames for all cameras."""
        self.running = False
        for camera_id in list(self.processing_tasks.keys()):
            await self.stop_processing(camera_id)
        logger.info("All frame processing stopped")
    
    def clear_queue(self, camera_id: str):
        """
        Clear all frames from a camera's queue.
        
        Args:
            camera_id: Unique identifier for the camera
        """
        if camera_id in self.frame_queues:
            self.frame_queues[camera_id].clear()
            logger.info(f"Frame queue cleared for camera {camera_id}")



import psutil


class ResourceMonitor:
    """
    Monitors system resources (CPU, memory) and adjusts frame processing dynamically.
    """
    
    def __init__(self, cpu_threshold: float = 80.0, memory_threshold: float = 90.0):
        """
        Initialize the resource monitor.
        
        Args:
            cpu_threshold: CPU usage percentage to trigger frame rate reduction (default 80%)
            memory_threshold: Memory usage percentage to trigger frame rate reduction (default 90%)
        """
        self.cpu_threshold = cpu_threshold
        self.memory_threshold = memory_threshold
        self.original_frame_rate = None
        
    def get_cpu_usage(self) -> float:
        """
        Get current CPU usage percentage.
        
        Returns:
            float: CPU usage percentage (0-100)
        """
        return psutil.cpu_percent(interval=1)
    
    def get_memory_usage(self) -> float:
        """
        Get current memory usage percentage.
        
        Returns:
            float: Memory usage percentage (0-100)
        """
        memory = psutil.virtual_memory()
        return memory.percent
    
    def get_memory_usage_mb(self) -> float:
        """
        Get current memory usage in MB.
        
        Returns:
            float: Memory usage in megabytes
        """
        process = psutil.Process()
        return process.memory_info().rss / (1024 * 1024)  # Convert bytes to MB
    
    def should_reduce_frame_rate(self) -> Tuple[bool, str]:
        """
        Check if frame rate should be reduced based on resource usage.
        
        Returns:
            Tuple[bool, str]: (should_reduce, reason)
        """
        cpu_usage = self.get_cpu_usage()
        memory_usage = self.get_memory_usage()
        memory_mb = self.get_memory_usage_mb()
        
        # Check CPU threshold (reduce by 50% if >80%)
        if cpu_usage > self.cpu_threshold:
            return True, f"CPU usage high: {cpu_usage:.1f}%"
        
        # Check memory threshold (reduce by 25% if >90% or >1800MB)
        if memory_usage > self.memory_threshold or memory_mb > 1800:
            return True, f"Memory usage high: {memory_usage:.1f}% ({memory_mb:.0f}MB)"
        
        return False, ""
    
    async def adjust_frame_rate(
        self,
        frame_processor: FrameProcessor,
        check_interval: int = 10
    ):
        """
        Continuously monitor resources and adjust frame rate dynamically.
        
        Args:
            frame_processor: FrameProcessor instance to adjust
            check_interval: Seconds between resource checks
        """
        self.original_frame_rate = frame_processor.frame_rate
        
        while True:
            try:
                should_reduce, reason = self.should_reduce_frame_rate()
                
                if should_reduce:
                    current_rate = frame_processor.frame_rate
                    
                    # Determine reduction amount based on reason
                    if "CPU" in reason:
                        # Reduce by 50% for CPU
                        new_rate = max(1, int(current_rate * 0.5))
                    else:
                        # Reduce by 25% for memory
                        new_rate = max(1, int(current_rate * 0.75))
                    
                    if new_rate != current_rate:
                        frame_processor.set_frame_rate(new_rate)
                        logger.warning(f"Reduced frame rate to {new_rate} FPS due to: {reason}")
                else:
                    # Resources are good, restore original frame rate if reduced
                    if frame_processor.frame_rate < self.original_frame_rate:
                        frame_processor.set_frame_rate(self.original_frame_rate)
                        logger.info(f"Restored frame rate to {self.original_frame_rate} FPS")
                
                await asyncio.sleep(check_interval)
                
            except Exception as e:
                logger.error(f"Error in resource monitoring: {str(e)}")
                await asyncio.sleep(check_interval)



import requests
from typing import List


class FaceDetector:
    """
    Detects faces in video frames using CompreFace detection API.
    """
    
    def __init__(self, comprefore_url: str, api_key: str):
        """
        Initialize the face detector.
        
        Args:
            comprefore_url: Base URL for CompreFace API
            api_key: API key for CompreFace recognition service
        """
        self.comprefore_url = comprefore_url.rstrip('/')
        self.api_key = api_key
        self.detection_endpoint = f"{self.comprefore_url}/api/v1/detection/detect"
        
    async def detect_faces(self, frame_jpeg: bytes, max_retries: int = 2) -> List[dict]:
        """
        Detect faces in a JPEG encoded frame.
        
        Args:
            frame_jpeg: JPEG encoded frame bytes
            max_retries: Maximum number of retry attempts on failure
            
        Returns:
            List[dict]: List of detected faces with bounding boxes
                Each face dict contains: x, y, width, height, probability
        """
        headers = {
            "x-api-key": self.api_key
        }
        
        files = {
            "file": ("frame.jpg", frame_jpeg, "image/jpeg")
        }
        
        for attempt in range(max_retries + 1):
            try:
                response = requests.post(
                    self.detection_endpoint,
                    headers=headers,
                    files=files,
                    timeout=30
                )
                
                if response.status_code == 200:
                    data = response.json()
                    faces = []
                    
                    # Parse detection results
                    if "result" in data:
                        for face_data in data["result"]:
                            if "box" in face_data:
                                box = face_data["box"]
                                faces.append({
                                    "x": box.get("x_min", 0),
                                    "y": box.get("y_min", 0),
                                    "width": box.get("x_max", 0) - box.get("x_min", 0),
                                    "height": box.get("y_max", 0) - box.get("y_min", 0),
                                    "probability": box.get("probability", 0.0)
                                })
                    
                    if len(faces) == 0:
                        logger.debug("No faces detected in frame")
                    else:
                        logger.debug(f"Detected {len(faces)} face(s) in frame")
                    
                    return faces
                else:
                    logger.error(f"CompreFace detection API error: {response.status_code} - {response.text}")
                    
            except requests.exceptions.Timeout:
                logger.warning(f"CompreFace detection API timeout (attempt {attempt + 1}/{max_retries + 1})")
            except Exception as e:
                logger.error(f"Error calling CompreFace detection API: {str(e)}")
            
            # Wait before retry
            if attempt < max_retries:
                await asyncio.sleep(1)
        
        # All retries failed
        logger.error(f"Failed to detect faces after {max_retries + 1} attempts")
        return []
    
    async def detect_faces_from_frame(self, frame: np.ndarray, max_retries: int = 2) -> List[dict]:
        """
        Detect faces in an OpenCV frame (convenience method).
        
        Args:
            frame: OpenCV frame (numpy array)
            max_retries: Maximum number of retry attempts on failure
            
        Returns:
            List[dict]: List of detected faces with bounding boxes
        """
        # Encode frame as JPEG
        frame_processor = FrameProcessor()
        frame_jpeg = frame_processor.encode_frame_jpeg(frame, quality=85)
        
        if frame_jpeg is None:
            logger.error("Failed to encode frame for face detection")
            return []
        
        return await self.detect_faces(frame_jpeg, max_retries)



class FaceRecognizer:
    """
    Recognizes faces using CompreFace recognition API.
    Matches detected faces against enrolled students.
    """
    
    def __init__(self, comprefore_url: str, api_key: str, confidence_threshold: float = 0.85):
        """
        Initialize the face recognizer.
        
        Args:
            comprefore_url: Base URL for CompreFace API
            api_key: API key for CompreFace recognition service
            confidence_threshold: Minimum confidence score to accept recognition (0.0-1.0)
        """
        self.comprefore_url = comprefore_url.rstrip('/')
        self.api_key = api_key
        self.confidence_threshold = confidence_threshold
        self.recognition_endpoint = f"{self.comprefore_url}/api/v1/recognition/recognize"
        
    async def recognize_face(
        self,
        frame_jpeg: bytes,
        camera_location: str,
        timestamp: datetime
    ) -> Optional[dict]:
        """
        Recognize a face in a JPEG encoded frame.
        
        Args:
            frame_jpeg: JPEG encoded frame bytes
            camera_location: Location of the camera
            timestamp: Timestamp of the frame
            
        Returns:
            dict: Recognition result with student_id, confidence, camera_location, timestamp
                  or None if no confident match found
        """
        headers = {
            "x-api-key": self.api_key
        }
        
        files = {
            "file": ("frame.jpg", frame_jpeg, "image/jpeg")
        }
        
        try:
            response = requests.post(
                self.recognition_endpoint,
                headers=headers,
                files=files,
                timeout=30
            )
            
            if response.status_code == 200:
                data = response.json()
                
                # Parse recognition results
                if "result" in data and len(data["result"]) > 0:
                    # Get the first (best) match
                    result = data["result"][0]
                    
                    if "subjects" in result and len(result["subjects"]) > 0:
                        subject = result["subjects"][0]
                        
                        confidence = subject.get("similarity", 0.0)
                        subject_name = subject.get("subject", "")
                        
                        # Check confidence threshold
                        if confidence >= self.confidence_threshold:
                            logger.info(
                                f"Recognized student: {subject_name} "
                                f"(confidence: {confidence:.2f}) at {camera_location}"
                            )
                            
                            return {
                                "student_id": subject_name,  # CompreFace uses subject name as ID
                                "student_name": subject_name,  # Will be replaced with full name in pipeline
                                "confidence": confidence,
                                "camera_location": camera_location,
                                "timestamp": timestamp
                            }
                        else:
                            logger.debug(
                                f"Recognition confidence too low: {confidence:.2f} "
                                f"(threshold: {self.confidence_threshold})"
                            )
                    else:
                        # No matching student found
                        logger.info(f"Unknown face detected at {camera_location}")
                        self._log_unknown_face(camera_location, timestamp)
                else:
                    logger.debug("No faces recognized in frame")
                    
            else:
                logger.error(f"CompreFace recognition API error: {response.status_code} - {response.text}")
                
        except requests.exceptions.Timeout:
            logger.warning("CompreFace recognition API timeout")
        except Exception as e:
            logger.error(f"Error calling CompreFace recognition API: {str(e)}")
        
        return None
    
    async def recognize_face_from_frame(
        self,
        frame: np.ndarray,
        camera_location: str,
        timestamp: datetime
    ) -> Optional[dict]:
        """
        Recognize a face in an OpenCV frame (convenience method).
        
        Args:
            frame: OpenCV frame (numpy array)
            camera_location: Location of the camera
            timestamp: Timestamp of the frame
            
        Returns:
            dict: Recognition result or None if no confident match
        """
        # Encode frame as JPEG
        frame_processor = FrameProcessor()
        frame_jpeg = frame_processor.encode_frame_jpeg(frame, quality=85)
        
        if frame_jpeg is None:
            logger.error("Failed to encode frame for face recognition")
            return None
        
        return await self.recognize_face(frame_jpeg, camera_location, timestamp)
    
    def _log_unknown_face(self, camera_location: str, timestamp: datetime):
        """
        Log an unknown face event.
        
        Args:
            camera_location: Location where unknown face was detected
            timestamp: Timestamp of detection
        """
        logger.info(
            f"Unknown face event - Location: {camera_location}, "
            f"Time: {timestamp.isoformat()}"
        )



import redis
from app.config import settings


class DuplicateFilter:
    """
    Prevents duplicate attendance entries using Redis caching.
    Checks if a student has been marked present at a camera location within the time window.
    """
    
    def __init__(self, redis_client: redis.Redis, time_window_minutes: int = None):
        """
        Initialize the duplicate filter.
        
        Args:
            redis_client: Redis client instance
            time_window_minutes: Time window in minutes to prevent duplicates (from config if None)
        """
        self.redis_client = redis_client
        self.time_window_minutes = time_window_minutes or settings.duplicate_window_minutes
        self.ttl_seconds = self.time_window_minutes * 60
        
    def _get_cache_key(self, student_id: str, camera_location: str) -> str:
        """
        Generate Redis cache key for attendance event.
        
        Args:
            student_id: Student identifier
            camera_location: Camera location name
            
        Returns:
            str: Cache key in format "attendance:recent:{student_id}:{camera_location}"
        """
        return f"attendance:recent:{student_id}:{camera_location}"
    
    async def is_duplicate(self, student_id: str, camera_location: str) -> bool:
        """
        Check if attendance for this student at this location is a duplicate.
        
        Args:
            student_id: Student identifier
            camera_location: Camera location name
            
        Returns:
            bool: True if duplicate (already marked within time window), False otherwise
        """
        try:
            cache_key = self._get_cache_key(student_id, camera_location)
            
            # Check if key exists in Redis
            exists = self.redis_client.exists(cache_key)
            
            if exists:
                logger.debug(
                    f"Duplicate attendance detected for student {student_id} "
                    f"at {camera_location} (within {self.time_window_minutes} minutes)"
                )
                return True
            
            return False
            
        except redis.RedisError as e:
            logger.error(f"Redis error checking duplicate: {str(e)}")
            # Fallback: allow attendance if Redis fails
            return False
        except Exception as e:
            logger.error(f"Error checking duplicate: {str(e)}")
            return False
    
    async def cache_attendance(self, student_id: str, camera_location: str, timestamp: datetime) -> bool:
        """
        Cache an attendance event to prevent duplicates.
        
        Args:
            student_id: Student identifier
            camera_location: Camera location name
            timestamp: Timestamp of attendance
            
        Returns:
            bool: True if cached successfully, False otherwise
        """
        try:
            cache_key = self._get_cache_key(student_id, camera_location)
            
            # Store timestamp as value with TTL
            self.redis_client.setex(
                cache_key,
                self.ttl_seconds,
                timestamp.isoformat()
            )
            
            logger.debug(
                f"Cached attendance for student {student_id} at {camera_location} "
                f"(TTL: {self.time_window_minutes} minutes)"
            )
            return True
            
        except redis.RedisError as e:
            logger.error(f"Redis error caching attendance: {str(e)}")
            return False
        except Exception as e:
            logger.error(f"Error caching attendance: {str(e)}")
            return False
    
    async def get_time_since_last_attendance(
        self,
        student_id: str,
        camera_location: str
    ) -> Optional[int]:
        """
        Get the time in seconds since last attendance for this student at this location.
        
        Args:
            student_id: Student identifier
            camera_location: Camera location name
            
        Returns:
            int: Seconds since last attendance, or None if no recent attendance
        """
        try:
            cache_key = self._get_cache_key(student_id, camera_location)
            
            # Get cached timestamp
            cached_timestamp = self.redis_client.get(cache_key)
            
            if cached_timestamp:
                last_time = datetime.fromisoformat(cached_timestamp.decode('utf-8'))
                time_diff = (datetime.now() - last_time).total_seconds()
                return int(time_diff)
            
            return None
            
        except Exception as e:
            logger.error(f"Error getting time since last attendance: {str(e)}")
            return None



from app.models import AttendanceRecord, Student
from sqlalchemy.orm import Session
from decimal import Decimal


class AttendanceMarker:
    """
    Marks attendance automatically when students are recognized.
    Uses a fresh DB session per operation to avoid stale data.
    """
    
    def __init__(self, db: Session, duplicate_filter: DuplicateFilter):
        # Keep reference for backward compat but use fresh sessions per operation
        self.db = db
        self.duplicate_filter = duplicate_filter
        self.event_callbacks = []
        
    def add_event_callback(self, callback: callable):
        self.event_callbacks.append(callback)
        
    async def mark_attendance(
        self,
        student_id: str,
        camera_location: str,
        timestamp: datetime,
        confidence: float,
        frame=None,
        camera_id: int = None
    ) -> Optional[dict]:
        try:
            # Check for duplicate first (uses Redis, no DB needed)
            is_duplicate = await self.duplicate_filter.is_duplicate(student_id, camera_location)
            if is_duplicate:
                return None

            # Use a fresh session for each attendance write
            from app.database import SessionLocal
            db = SessionLocal()
            try:
                student = db.query(Student).filter(Student.student_id == student_id).first()
                if not student:
                    logger.warning(f"Student not found in database: {student_id}")
                    return None

                attendance_record = AttendanceRecord(
                    student_id=student.id,
                    camera_location=camera_location,
                    timestamp=timestamp,
                    confidence_score=Decimal(str(confidence))
                )
                db.add(attendance_record)
                db.commit()
                db.refresh(attendance_record)

                # Save face snapshot
                try:
                    import os
                    from pathlib import Path
                    snap_dir = Path("/var/attendance_clips") / "snapshots" / datetime.now().strftime("%Y-%m-%d")
                    snap_dir.mkdir(parents=True, exist_ok=True)
                    snap_path = snap_dir / f"{attendance_record.id}.jpg"
                    import cv2 as _cv2
                    _cv2.imwrite(str(snap_path), frame)
                    attendance_record.face_image_url = str(snap_path)
                    db.commit()
                except Exception as snap_err:
                    logger.warning(f"Could not save face snapshot: {snap_err}")

                # Save video clip
                if frame is not None and camera_id is not None and hasattr(self, 'clip_service'):
                    try:
                        clip_path = await self.clip_service.save_clip(
                            camera_id=camera_id,
                            attendance_id=str(attendance_record.id),
                            detection_frame=frame
                        )
                        if clip_path:
                            attendance_record.clip_path = clip_path
                            db.commit()
                    except Exception as e:
                        logger.error(f"Failed to save video clip: {e}")

                # Notify parents
                try:
                    from app.services.notification_service import notify_parents_of_attendance, NotificationService
                    notify_parents_of_attendance(db, student, attendance_record, NotificationService())
                except Exception as e:
                    logger.error(f"Notification failed: {e}")

                await self.duplicate_filter.cache_attendance(student_id, camera_location, timestamp)

                logger.info(f"Attendance marked: {student.full_name} at {camera_location} ({confidence:.2f})")

                attendance_event = {
                    "attendance_id": str(attendance_record.id),
                    "student_id": student_id,
                    "student_name": student.full_name,
                    "camera_location": camera_location,
                    "timestamp": timestamp.isoformat(),
                    "confidence_score": confidence
                }
                await self.publish_attendance_event(attendance_event)
                return attendance_event

            except Exception as e:
                logger.error(f"Error marking attendance: {str(e)}")
                db.rollback()
                return None
            finally:
                db.close()

        except Exception as e:
            logger.error(f"Error in mark_attendance: {str(e)}")
            return None
    
    async def publish_attendance_event(self, attendance_event: dict):
        """
        Publish attendance event to all registered callbacks.
        
        Args:
            attendance_event: Attendance event data dictionary
        """
        for callback in self.event_callbacks:
            try:
                await callback(attendance_event)
            except Exception as e:
                logger.error(f"Error in attendance event callback: {str(e)}")



from app.services.websocket import WebSocketManager
import time


class StreamBroadcaster:
    """
    Broadcasts video frames and events to WebSocket clients.
    Handles frame encoding, rate limiting, and event distribution.
    """
    
    def __init__(self, websocket_manager: WebSocketManager, max_fps: int = 5):
        """
        Initialize the stream broadcaster.
        
        Args:
            websocket_manager: WebSocketManager instance
            max_fps: Maximum frames per second to broadcast to clients
        """
        self.websocket_manager = websocket_manager
        self.max_fps = max_fps
        self.frame_interval = 1.0 / max_fps
        self.last_broadcast_time: Dict[str, float] = {}
        
    async def broadcast_frame(
        self,
        camera_id: str,
        frame: np.ndarray,
        detections: List[dict] = None,
        timestamp: datetime = None
    ):
        """
        Broadcast a video frame to all connected clients.
        Applies professional face mask overlays and rate limiting per camera.
        
        Args:
            camera_id: Unique identifier for the camera
            frame: OpenCV frame (numpy array)
            detections: Optional list of face detections with bounding boxes
            timestamp: Optional timestamp for the frame
        """
        # Check if we have any connected clients
        if self.websocket_manager.get_connection_count() == 0:
            return
        
        # Rate limiting: check if enough time has passed since last broadcast
        current_time = time.time()
        last_time = self.last_broadcast_time.get(camera_id, 0)
        
        if current_time - last_time < self.frame_interval:
            return  # Skip this frame to maintain rate limit
        
        self.last_broadcast_time[camera_id] = current_time
        
        try:
            # Make a copy to avoid modifying the original frame
            display_frame = frame.copy()
            
            # Resize frame to reduce bandwidth (640x480 max)
            height, width = display_frame.shape[:2]
            max_width = 640
            if width > max_width:
                scale = max_width / width
                new_width = max_width
                new_height = int(height * scale)
                display_frame = cv2.resize(display_frame, (new_width, new_height))
            
            # Encode frame as Base64 JPEG (30% quality for streaming - lower quality, smaller size)
            frame_processor = FrameProcessor()
            frame_base64 = frame_processor.encode_frame_base64(display_frame, quality=30)
            
            if frame_base64 is None:
                logger.error(f"Failed to encode frame for camera {camera_id}")
                return
            
            # Prepare frame message
            message = {
                "type": "frame_update",
                "camera_id": camera_id,
                "frame": frame_base64,
                "timestamp": (timestamp or datetime.now()).isoformat(),
                "detections": detections or []
            }
            
            # Broadcast to all clients
            await self.websocket_manager.broadcast(message)
            
        except Exception as e:
            logger.error(f"Error broadcasting frame for camera {camera_id}: {str(e)}")
    
    async def broadcast_attendance_event(self, attendance_event: dict):
        """
        Broadcast an attendance event to all connected clients.
        
        Args:
            attendance_event: Attendance event data dictionary
                Expected keys: attendance_id, student_id, student_name,
                              camera_location, timestamp, confidence_score
        """
        try:
            message = {
                "type": "attendance_event",
                "data": attendance_event
            }
            
            await self.websocket_manager.broadcast(message)
            
            logger.info(
                f"Broadcasted attendance event for student {attendance_event.get('student_name')} "
                f"at {attendance_event.get('camera_location')}"
            )
            
        except Exception as e:
            logger.error(f"Error broadcasting attendance event: {str(e)}")
    
    async def broadcast_camera_status(self, camera_id: str, status: str, error_message: str = None):
        """
        Broadcast camera status update to all connected clients.
        
        Args:
            camera_id: Unique identifier for the camera
            status: Camera status (online, offline, error)
            error_message: Optional error message if status is error
        """
        try:
            message = {
                "type": "camera_status",
                "camera_id": camera_id,
                "status": status,
                "error_message": error_message,
                "timestamp": datetime.now().isoformat()
            }
            
            await self.websocket_manager.broadcast(message)
            
            logger.info(f"Broadcasted camera status: {camera_id} - {status}")
            
        except Exception as e:
            logger.error(f"Error broadcasting camera status: {str(e)}")
    
    async def broadcast_recognition_event(self, camera_id: str, detections: List[dict], timestamp: datetime):
        """
        Broadcast face detection/recognition event to all connected clients.
        
        Args:
            camera_id: Unique identifier for the camera
            detections: List of detected faces with bounding boxes and recognition data
            timestamp: Timestamp of the detection
        """
        try:
            message = {
                "type": "recognition_event",
                "camera_id": camera_id,
                "detections": detections,
                "timestamp": timestamp.isoformat()
            }
            
            await self.websocket_manager.broadcast(message)
            
            logger.debug(f"Broadcasted recognition event for camera {camera_id} with {len(detections)} detection(s)")
            
        except Exception as e:
            logger.error(f"Error broadcasting recognition event: {str(e)}")
    
    def should_broadcast(self, camera_id: str) -> bool:
        """
        Check if a frame should be broadcast based on rate limiting.
        
        Args:
            camera_id: Unique identifier for the camera
            
        Returns:
            bool: True if frame should be broadcast, False otherwise
        """
        if self.websocket_manager.get_connection_count() == 0:
            return False
        
        current_time = time.time()
        last_time = self.last_broadcast_time.get(camera_id, 0)
        
        return (current_time - last_time) >= self.frame_interval



class VideoStreamingService:
    """
    Main orchestrator for the video streaming and face recognition system.
    Wires together all components and manages the complete pipeline.
    """
    
    def __init__(
        self,
        db: Session,
        redis_client: redis.Redis,
        websocket_manager: WebSocketManager,
        comprefore_url: str,
        comprefore_api_key: str,
        comprefore_detection_api_key: str,
        cpu_threshold: float = 80.0,
        memory_threshold: float = 90.0,
        frame_resize_width: int = 0,
        frame_resize_height: int = 0
    ):
        """
        Initialize the video streaming service.
        
        Args:
            db: SQLAlchemy database session
            redis_client: Redis client instance
            websocket_manager: WebSocket manager instance
            comprefore_url: CompreFace API URL
            comprefore_api_key: CompreFace Recognition API key
            comprefore_detection_api_key: CompreFace Detection API key
            cpu_threshold: CPU usage threshold for frame rate reduction (default 80%)
            memory_threshold: Memory usage threshold for frame rate reduction (default 90%)
            frame_resize_width: Resize frame width before processing (0 = no resize)
            frame_resize_height: Resize frame height before processing (0 = no resize)
        """
        self.db = db
        self.redis_client = redis_client
        self.websocket_manager = websocket_manager
        self.frame_resize_width = frame_resize_width
        self.frame_resize_height = frame_resize_height
        
        # Initialize all components
        self.video_stream_manager = VideoStreamManager()
        self.frame_processor = FrameProcessor(frame_rate=5)
        self.resource_monitor = ResourceMonitor(cpu_threshold=cpu_threshold, memory_threshold=memory_threshold)
        self.face_detector = FaceDetector(comprefore_url, comprefore_detection_api_key)
        self.face_recognizer = FaceRecognizer(comprefore_url, comprefore_api_key)
        self.duplicate_filter = DuplicateFilter(redis_client)
        self.attendance_marker = AttendanceMarker(db, self.duplicate_filter)
        self.stream_broadcaster = StreamBroadcaster(websocket_manager, max_fps=2)
        
        # Initialize video clip service
        from app.services.video_clip_service import VideoClipService
        from app.config import settings as _settings
        clips_dir = getattr(_settings, "clips_dir", "/var/attendance_clips")
        retention_days = getattr(_settings, "clips_retention_days", 7)
        self.clip_service = VideoClipService(clips_dir=clips_dir, retention_days=retention_days)
        self.attendance_marker.clip_service = self.clip_service
        
        # API request throttling - limit concurrent CompreFace API requests to 8
        self.api_semaphore = asyncio.Semaphore(8)
        
        # Register attendance event callback
        self.attendance_marker.add_event_callback(self._on_attendance_event)
        
        self.running = False
        self.processing_tasks = {}
        
    async def _on_attendance_event(self, attendance_event: dict):
        """
        Callback for attendance events - broadcasts to WebSocket clients.
        
        Args:
            attendance_event: Attendance event data
        """
        await self.stream_broadcaster.broadcast_attendance_event(attendance_event)
    
    def _detect_local_faces(self, frame: np.ndarray) -> List[dict]:
        """
        Detect faces locally using OpenCV Haar cascades as a fallback.
        
        Args:
            frame: OpenCV BGR frame
        
        Returns:
            List[dict]: Detected face boxes with x/y/width/height
        """
        try:
            gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
            cascade_path = cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'
            face_cascade = cv2.CascadeClassifier(cascade_path)
            faces = face_cascade.detectMultiScale(gray, scaleFactor=1.1, minNeighbors=5, minSize=(80, 80))
            return [
                {
                    "x": int(x),
                    "y": int(y),
                    "width": int(w),
                    "height": int(h)
                }
                for (x, y, w, h) in faces
            ]
        except Exception as e:
            logger.error(f"Local face detection failed: {str(e)}")
            return []

    async def _process_camera_pipeline(self, camera_id: str, camera_location: str):
        """
        Complete processing pipeline for a single camera:
        capture → process → detect → recognize → mark attendance → broadcast
        
        Args:
            camera_id: Unique identifier for the camera
            camera_location: Location name of the camera
        """
        logger.info(f"Started processing pipeline for camera {camera_id}")
        
        while self.running:
            try:
                # Read frame from camera
                success, frame = self.video_stream_manager.read_frame(camera_id)
                
                if not success or frame is None:
                    await asyncio.sleep(0.1)
                    continue

                timestamp = datetime.now()

                # Feed frame into the rolling clip buffer (pre-detection window)
                self.clip_service.add_frame(camera_id, frame)

                # Use Recognition API which includes detection + recognition in one call
                # This is more efficient and gives us bounding boxes with recognition results
                async with self.api_semaphore:
                    # Encode frame as JPEG
                    frame_jpeg = self.frame_processor.encode_frame_jpeg(frame, quality=85)
                    
                    if frame_jpeg is None:
                        await asyncio.sleep(0.1)
                        continue
                    
                    # Call Recognition API (includes detection)
                    headers = {"x-api-key": self.face_recognizer.api_key}
                    files = {"file": ("frame.jpg", frame_jpeg, "image/jpeg")}
                    detection_data = []
                    
                    try:
                        loop = asyncio.get_event_loop()
                        response = await asyncio.wait_for(
                            loop.run_in_executor(
                                None,
                                lambda: requests.post(
                                    self.face_recognizer.recognition_endpoint,
                                    headers=headers,
                                    files=files,
                                    timeout=8
                                )
                            ),
                            timeout=10
                        )
                        
                        if response.status_code == 200:
                            data = response.json()
                            
                            # Parse all detected faces
                            if "result" in data:
                                for face_result in data["result"]:
                                    # Get bounding box
                                    box = face_result.get("box", {})
                                    x_min = box.get("x_min", 0)
                                    y_min = box.get("y_min", 0)
                                    x_max = box.get("x_max", 100)
                                    y_max = box.get("y_max", 100)
                                    
                                    # Check if face is recognized
                                    subjects = face_result.get("subjects", [])
                                    
                                    if subjects and len(subjects) > 0:
                                        # Face recognized
                                        subject = subjects[0]
                                        confidence = subject.get("similarity", 0.0)
                                        student_id = subject.get("subject", "")
                                        
                                        if confidence >= self.face_recognizer.confidence_threshold:
                                            # Get student full name from database (fresh session)
                                            from app.models import Student
                                            from app.database import SessionLocal as _SL
                                            _db = _SL()
                                            try:
                                                student = _db.query(Student).filter(
                                                    Student.student_id == student_id
                                                ).first()
                                                student_name = student.full_name if student else student_id
                                            finally:
                                                _db.close()
                                            
                                            # Add recognized face
                                            detection_data.append({
                                                "x": x_min,
                                                "y": y_min,
                                                "width": x_max - x_min,
                                                "height": y_max - y_min,
                                                "student_id": student_id,
                                                "student_name": student_name,
                                                "confidence": confidence
                                            })
                                            
                                            # Mark attendance
                                            await self.attendance_marker.mark_attendance(
                                                student_id=student_id,
                                                camera_location=camera_location,
                                                timestamp=timestamp,
                                                confidence=confidence,
                                                frame=frame,
                                                camera_id=camera_id
                                            )
                                        else:
                                            # Low confidence - treat as unknown
                                            detection_data.append({
                                                "x": x_min,
                                                "y": y_min,
                                                "width": x_max - x_min,
                                                "height": y_max - y_min
                                            })
                                    else:
                                        # Unknown face
                                        detection_data.append({
                                            "x": x_min,
                                            "y": y_min,
                                            "width": x_max - x_min,
                                            "height": y_max - y_min
                                        })
                        else:
                            if response.status_code == 400 and "No face is found" in response.text:
                                logger.debug(f"CompreFace recognition returned no face for camera {camera_id}")
                            else:
                                logger.error(f"CompreFace recognition API error: {response.status_code} - {response.text}")
                    except Exception as e:
                        logger.error(f"Error in recognition API call: {str(e)}")
                    
                    # Fallback to local detection when no recognized or detected faces are returned
                    if not detection_data:
                        detection_data = self._detect_local_faces(frame)
                        if detection_data:
                            logger.info(f"Local fallback detection found {len(detection_data)} face(s) for camera {camera_id}")

                    # Broadcast recognition events to frontend if faces detected
                    if detection_data:
                        await self.stream_broadcaster.broadcast_recognition_event(
                            camera_id=camera_id,
                            detections=detection_data,
                            timestamp=timestamp
                        )
                
                # Control frame rate
                await asyncio.sleep(1.0 / self.frame_processor.frame_rate)
                
            except Exception as e:
                logger.error(f"Error in processing pipeline for camera {camera_id}: {str(e)}")
                await asyncio.sleep(1)
    
    async def start_camera(self, camera_id: str, stream_url: str, protocol: str, location_name: str):
        """
        Start processing a camera stream.
        
        Args:
            camera_id: Unique identifier for the camera
            stream_url: URL or device path for the video stream
            protocol: Protocol type (rtsp, http, local)
            location_name: Location name of the camera
        """
        # Start camera connection
        success = await self.video_stream_manager.start_camera(camera_id, stream_url, protocol)
        
        if not success:
            logger.error(f"Failed to start camera {camera_id}")
            from app.database import SessionLocal as _SL
            _db = _SL()
            try:
                camera = _db.query(Camera).filter(Camera.id == int(camera_id)).first()
                if camera:
                    camera.status = "error"
                    camera.error_message = "Failed to connect to camera"
                    _db.commit()
            finally:
                _db.close()
            await self.stream_broadcaster.broadcast_camera_status(
                camera_id, "error", "Failed to connect to camera"
            )
            return False
        
        # Update database status to online
        from app.database import SessionLocal as _SL2
        _db2 = _SL2()
        try:
            camera = _db2.query(Camera).filter(Camera.id == int(camera_id)).first()
            if camera:
                camera.status = "online"
                camera.error_message = None
                camera.last_seen = datetime.now()
                _db2.commit()
        finally:
            _db2.close()

        # Initialise clip buffer and register live stream for post-detection capture
        self.clip_service.init_camera_buffer(camera_id)
        self.clip_service.register_stream_manager(camera_id, self.video_stream_manager)

        # Start processing pipeline
        task = asyncio.create_task(self._process_camera_pipeline(camera_id, location_name))
        self.processing_tasks[camera_id] = task
        
        # Broadcast camera online status
        await self.stream_broadcaster.broadcast_camera_status(camera_id, "online")
        
        logger.info(f"Camera {camera_id} started successfully")
        return True
    
    async def stop_camera(self, camera_id: str):
        """
        Stop processing a camera stream.
        
        Args:
            camera_id: Unique identifier for the camera
        """
        # Stop processing task
        if camera_id in self.processing_tasks:
            task = self.processing_tasks[camera_id]
            task.cancel()
            try:
                await task
            except asyncio.CancelledError:
                pass
            del self.processing_tasks[camera_id]
        
        # Stop camera connection
        await self.video_stream_manager.stop_camera(camera_id)
        
        # Update database status to offline
        from app.database import SessionLocal as _SL
        _db = _SL()
        try:
            camera = _db.query(Camera).filter(Camera.id == int(camera_id)).first()
            if camera:
                camera.status = "offline"
                _db.commit()
        finally:
            _db.close()
        
        # Broadcast camera offline status
        await self.stream_broadcaster.broadcast_camera_status(camera_id, "offline")
        
        logger.info(f"Camera {camera_id} stopped")
    
    async def start(self):
        """Start the video streaming service and load cameras from database."""
        self.running = True
        await self.video_stream_manager.start_monitoring()
        asyncio.create_task(self.resource_monitor.adjust_frame_rate(self.frame_processor))

        from app.database import SessionLocal as _SL
        _db = _SL()
        try:
            cameras = _db.query(Camera).filter(Camera.is_active == True).all()
            camera_list = [(str(c.id), c.stream_url, c.protocol, c.location) for c in cameras]
        finally:
            _db.close()

        async def _start_cameras():
            for cam_id, url, protocol, location in camera_list:
                await self.start_camera(cam_id, url, protocol, location)

        asyncio.create_task(_start_cameras())
        logger.info(f"Video streaming service started, loading {len(camera_list)} cameras in background")
    
    async def stop(self):
        """Stop the video streaming service and all cameras."""
        self.running = False
        
        # Stop all cameras
        for camera_id in list(self.processing_tasks.keys()):
            await self.stop_camera(camera_id)
        
        # Stop monitoring
        await self.video_stream_manager.stop_monitoring()
        await self.video_stream_manager.stop_all_cameras()
        
        logger.info("Video streaming service stopped")
