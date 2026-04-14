"""
FastAPI router for MJPEG video streaming endpoints.
Serves individual camera streams via HTTP multipart responses.
"""

import uuid
import logging
from fastapi import APIRouter, Request, Depends, HTTPException
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session
from app.database import get_db
from app.services.mjpeg_streaming import (
    MJPEGStreamService,
    CameraNotFoundError,
    CameraInactiveError,
    CameraOfflineError
)

logger = logging.getLogger(__name__)

router = APIRouter()

# Global MJPEG service instance (will be set during app startup)
_mjpeg_service: MJPEGStreamService = None


def set_mjpeg_service(service: MJPEGStreamService):
    """
    Set the global MJPEG service instance.
    Called during application startup.
    
    Args:
        service: MJPEGStreamService instance
    """
    global _mjpeg_service
    _mjpeg_service = service
    logger.info("MJPEG service registered with router")


def get_mjpeg_service() -> MJPEGStreamService:
    """
    Dependency injection function for MJPEG service.
    
    Returns:
        MJPEGStreamService: Global MJPEG service instance
    """
    if _mjpeg_service is None:
        raise HTTPException(status_code=500, detail="MJPEG service not initialized")
    return _mjpeg_service


@router.get("/cameras/{camera_id}/stream")
async def stream_camera(
    camera_id: int,
    request: Request,
    db: Session = Depends(get_db),
    mjpeg_service: MJPEGStreamService = Depends(get_mjpeg_service)
):
    """
    Stream MJPEG video from a camera.
    
    Args:
        camera_id: Camera identifier
        request: FastAPI request object (for disconnect detection)
        db: Database session
        mjpeg_service: MJPEG streaming service
        
    Returns:
        StreamingResponse: HTTP response with multipart/x-mixed-replace content
        
    Raises:
        HTTPException 404: Camera not found
        HTTPException 400: Camera not active
        HTTPException 503: Camera offline
    """
    # Generate unique client_id using uuid.uuid4()
    client_id = str(uuid.uuid4())
    
    logger.info(f"Stream request for camera {camera_id} from client {client_id}")
    
    try:
        # Call mjpeg_service.generate_mjpeg_stream(camera_id, client_id)
        stream_generator = mjpeg_service.generate_mjpeg_stream(
            str(camera_id),
            client_id
        )
        
        # Return StreamingResponse with content_type="multipart/x-mixed-replace; boundary=frame"
        return StreamingResponse(
            stream_generator,
            media_type="multipart/x-mixed-replace; boundary=frame"
        )
        
    except CameraNotFoundError:
        # Catch CameraNotFoundError and return HTTPException(404, "Camera not found")
        logger.warning(f"Camera not found: {camera_id}")
        raise HTTPException(status_code=404, detail="Camera not found")
    
    except CameraInactiveError:
        # Catch CameraInactiveError and return HTTPException(400, "Camera is not active")
        logger.warning(f"Camera not active: {camera_id}")
        raise HTTPException(status_code=400, detail="Camera is not active")
    
    except CameraOfflineError:
        # Check if camera is offline and return HTTPException(503, "Camera is offline")
        logger.warning(f"Camera offline: {camera_id}")
        raise HTTPException(status_code=503, detail="Camera is offline")
    
    except Exception as e:
        # Log unexpected errors
        logger.error(f"Error streaming camera {camera_id}: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")
