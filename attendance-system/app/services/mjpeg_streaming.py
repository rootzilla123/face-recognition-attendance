"""
MJPEG streaming service for efficient video delivery via HTTP multipart responses.
Replaces WebSocket-based frame streaming to eliminate browser freezing and connection issues.
"""

import asyncio
import logging
from typing import Dict, Set, Optional, AsyncGenerator
from datetime import datetime
from sqlalchemy.orm import Session
from app.models import Camera
from app.services.video_streaming import VideoStreamManager, FrameProcessor

logger = logging.getLogger(__name__)


class CameraNotFoundError(Exception):
    """Raised when a camera ID does not exist in the database."""
    pass


class CameraInactiveError(Exception):
    """Raised when a camera is not active."""
    pass


class CameraOfflineError(Exception):
    """Raised when a camera is offline."""
    pass


class MJPEGStreamService:
    """
    Core service that generates MJPEG streams from camera sources and manages client connections.
    
    Attributes:
        video_stream_manager: Existing service for camera management
        frame_processor: Existing service for frame encoding
        db: Database session
        active_streams: Dict[str, Set[str]] tracking camera_id -> client_ids
        stream_locks: Dict[str, asyncio.Lock] for per-camera concurrency control
        jpeg_quality: JPEG quality for MJPEG streams (default 70)
    """
    
    def __init__(
        self,
        video_stream_manager: VideoStreamManager,
        frame_processor: FrameProcessor,
        db: Session,
        jpeg_quality: int = 70
    ):
        """
        Initialize the MJPEG streaming service.
        
        Args:
            video_stream_manager: VideoStreamManager instance for camera management
            frame_processor: FrameProcessor instance for frame encoding
            db: SQLAlchemy database session
            jpeg_quality: JPEG quality for encoding (1-100, default 70)
        """
        self.video_stream_manager = video_stream_manager
        self.frame_processor = frame_processor
        self.db = db
        self.active_streams: Dict[str, Set[str]] = {}
        self.stream_locks: Dict[str, asyncio.Lock] = {}
        self.jpeg_quality = jpeg_quality
        
        logger.info(f"MJPEGStreamService initialized with JPEG quality {jpeg_quality}")
    
    async def validate_camera(self, camera_id: str) -> Camera:
        from app.database import SessionLocal
        db = SessionLocal()
        try:
            camera = db.query(Camera).filter(Camera.id == int(camera_id)).first()
            if not camera:
                raise CameraNotFoundError(f"Camera {camera_id} not found")
            if not camera.is_active:
                raise CameraInactiveError(f"Camera {camera_id} is not active")
            return camera
        finally:
            db.close()
    
    def register_client(self, camera_id: str, client_id: str) -> None:
        """
        Register a client connection for a camera stream.
        
        Args:
            camera_id: Camera identifier
            client_id: Unique client connection identifier
        """
        if camera_id not in self.active_streams:
            self.active_streams[camera_id] = set()
        
        self.active_streams[camera_id].add(client_id)
        logger.info(
            f"Client {client_id} registered for camera {camera_id} "
            f"(total clients: {len(self.active_streams[camera_id])})"
        )
    
    def unregister_client(self, camera_id: str, client_id: str) -> None:
        """
        Unregister a client connection and cleanup resources.
        
        Args:
            camera_id: Camera identifier
            client_id: Unique client connection identifier
        """
        if camera_id in self.active_streams:
            self.active_streams[camera_id].discard(client_id)
            
            # Cleanup empty sets
            if len(self.active_streams[camera_id]) == 0:
                del self.active_streams[camera_id]
            
            logger.info(
                f"Client {client_id} unregistered from camera {camera_id} "
                f"at {datetime.now().isoformat()}"
            )
    
    def get_client_count(self, camera_id: str) -> int:
        """
        Get number of active clients for a camera.
        
        Args:
            camera_id: Camera identifier
            
        Returns:
            int: Number of connected clients
        """
        if camera_id not in self.active_streams:
            return 0
        return len(self.active_streams[camera_id])
    
    async def get_frame_interval(self, camera_id: str) -> float:
        from app.database import SessionLocal
        db = SessionLocal()
        try:
            camera = db.query(Camera).filter(Camera.id == int(camera_id)).first()
            if not camera or not camera.frame_rate:
                return 1.0 / 5.0
            return 1.0 / float(camera.frame_rate)
        finally:
            db.close()
    
    async def generate_mjpeg_stream(
        self,
        camera_id: str,
        client_id: str
    ) -> AsyncGenerator[bytes, None]:
        """
        Generate MJPEG stream for a specific camera.
        
        Yields multipart HTTP response chunks with JPEG frames.
        Handles client disconnection and cleanup.
        
        Args:
            camera_id: Camera identifier
            client_id: Unique client connection identifier
            
        Yields:
            bytes: Multipart HTTP chunks with JPEG frames
            
        Raises:
            CameraNotFoundError: If camera doesn't exist
            CameraInactiveError: If camera is not active
            CameraOfflineError: If camera is offline
        """
        # Validate camera using validate_camera method
        camera = await self.validate_camera(camera_id)
        
        # Check if camera is online
        if not self.video_stream_manager.is_camera_online(camera_id):
            logger.error(f"Camera {camera_id} is offline")
            raise CameraOfflineError(f"Camera {camera_id} is offline")
        
        # Register client using register_client method
        self.register_client(camera_id, client_id)
        
        # Get frame interval using get_frame_interval method
        frame_interval = await self.get_frame_interval(camera_id)
        
        logger.info(
            f"Starting MJPEG stream for camera {camera_id}, client {client_id} "
            f"(frame_interval: {frame_interval:.3f}s)"
        )
        
        try:
            # Enter infinite loop to stream frames
            while True:
                # Check if camera goes offline during streaming
                if not self.video_stream_manager.is_camera_online(camera_id):
                    logger.error(f"Camera {camera_id} went offline during streaming")
                    break
                
                # Call video_stream_manager.read_frame(camera_id) to get frame
                success, frame = self.video_stream_manager.read_frame(camera_id)
                
                # If frame read fails, log warning, sleep for frame_interval, and continue
                if not success or frame is None:
                    logger.warning(f"Failed to read frame from camera {camera_id}, skipping")
                    await asyncio.sleep(frame_interval)
                    continue
                
                # Encode frame directly without overlays
                jpeg_bytes = self.frame_processor.encode_frame_jpeg(frame, quality=self.jpeg_quality)
                
                # If encoding fails, log error, sleep for frame_interval, and continue
                if jpeg_bytes is None:
                    logger.error(f"Failed to encode frame for camera {camera_id}, skipping")
                    await asyncio.sleep(frame_interval)
                    continue
                
                # Format each frame as multipart HTTP response
                frame_chunk = (
                    b'--frame\r\n'
                    b'Content-Type: image/jpeg\r\n'
                    + f'Content-Length: {len(jpeg_bytes)}\r\n\r\n'.encode()
                    + jpeg_bytes + b'\r\n'
                )
                
                # Yield formatted bytes to client
                yield frame_chunk
                
                # Sleep for frame_interval between frames
                await asyncio.sleep(frame_interval)
                
        except (ConnectionResetError, BrokenPipeError, asyncio.CancelledError) as e:
            # Log client disconnection with camera_id and client_id
            logger.info(
                f"Client disconnected from camera {camera_id} stream: "
                f"{type(e).__name__} (client_id: {client_id})"
            )
        except Exception as e:
            # Log unexpected exceptions
            logger.error(
                f"Error in MJPEG stream for camera {camera_id}, client {client_id}: {str(e)}"
            )
        finally:
            # Add finally block to call unregister_client
            self.unregister_client(camera_id, client_id)
            logger.info(f"Cleaned up stream for camera {camera_id}, client {client_id}")
