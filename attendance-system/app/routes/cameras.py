"""
Camera management API routes.
"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from pydantic import BaseModel
from app.database import get_db
from app.models import Camera, Teacher, TeacherCamera, User, UserRole
from app.dependencies import require_admin, require_teacher_or_admin, get_current_user
from datetime import datetime

router = APIRouter()


# Pydantic schemas for request/response
class CameraCreate(BaseModel):
    name: str  # Frontend sends 'name'
    location: str  # Frontend sends 'location'
    stream_url: str
    protocol: str  # rtsp, http, local
    username: str = None  # Frontend sends username
    password: str = None  # Frontend sends password
    is_active: bool = True
    frame_rate: int = 5


class CameraUpdate(BaseModel):
    name: str = None
    location: str = None
    stream_url: str = None
    protocol: str = None
    is_active: bool = None
    frame_rate: int = None


class CameraResponse(BaseModel):
    id: int  # Frontend expects integer ID
    name: str  # Frontend expects 'name'
    location: str  # Frontend expects 'location'
    stream_url: str
    protocol: str
    status: str = "offline"
    is_active: bool
    frame_rate: int
    last_seen: datetime | None = None
    error_message: str | None = None
    created_at: datetime
    updated_at: datetime | None = None
    
    class Config:
        from_attributes = True


@router.post("/cameras", response_model=CameraResponse, status_code=201)
async def register_camera(camera_data: CameraCreate, db: Session = Depends(get_db), _=Depends(require_admin)):
    """
    Register a new camera source.
    
    Args:
        camera_data: Camera configuration data
        db: Database session
        
    Returns:
        CameraResponse: Created camera data
    """
    # Validate protocol
    valid_protocols = ["rtsp", "http", "local"]
    if camera_data.protocol not in valid_protocols:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid protocol. Must be one of: {', '.join(valid_protocols)}"
        )
    
    # Build stream URL with credentials if provided
    stream_url = camera_data.stream_url
    if camera_data.username and camera_data.password and camera_data.protocol in ["rtsp", "http"]:
        # Insert credentials into URL if not already present
        if "@" not in stream_url:
            protocol_prefix = f"{camera_data.protocol}://"
            if stream_url.startswith(protocol_prefix):
                stream_url = f"{protocol_prefix}{camera_data.username}:{camera_data.password}@{stream_url[len(protocol_prefix):]}"
    
    # Create camera
    camera = Camera(
        name=camera_data.name,
        location=camera_data.location,
        stream_url=stream_url,
        protocol=camera_data.protocol,
        username=camera_data.username,
        password=camera_data.password,
        frame_rate=camera_data.frame_rate,
        is_active=camera_data.is_active,
        status="offline"
    )
    
    db.add(camera)
    db.commit()
    db.refresh(camera)
    
    return camera


@router.get("/cameras", response_model=List[CameraResponse])
async def list_cameras(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Admins see all cameras. Teachers see only their assigned cameras."""
    if current_user.role not in [UserRole.admin, UserRole.teacher]:
        raise HTTPException(status_code=403, detail="Access denied")

    if current_user.role == UserRole.admin:
        return db.query(Camera).all()

    # Teacher - get only assigned cameras
    teacher = db.query(Teacher).filter(Teacher.id == current_user.profile_id).first()
    if not teacher:
        return []
    assigned_ids = [tc.camera_id for tc in db.query(TeacherCamera).filter(TeacherCamera.teacher_id == teacher.id).all()]
    if not assigned_ids:
        return []
    return db.query(Camera).filter(Camera.id.in_(assigned_ids)).all()


@router.get("/cameras/{camera_id}", response_model=CameraResponse)
async def get_camera(camera_id: int, db: Session = Depends(get_db)):
    """
    Get details of a specific camera.
    
    Args:
        camera_id: Camera ID (integer)
        db: Database session
        
    Returns:
        CameraResponse: Camera data
    """
    camera = db.query(Camera).filter(Camera.id == camera_id).first()
    
    if not camera:
        raise HTTPException(status_code=404, detail=f"Camera with ID {camera_id} not found")
    
    return camera


@router.get("/cameras/{camera_id}/status")
async def get_camera_status(camera_id: int, db: Session = Depends(get_db)):
    """
    Get the current status of a camera.
    
    Args:
        camera_id: Camera ID (integer)
        db: Database session
        
    Returns:
        dict: Camera status information
    """
    camera = db.query(Camera).filter(Camera.id == camera_id).first()
    
    if not camera:
        raise HTTPException(status_code=404, detail=f"Camera with ID {camera_id} not found")
    
    return {
        "camera_id": camera.id,
        "name": camera.name,
        "location": camera.location,
        "status": camera.status,
        "is_active": camera.is_active,
        "last_seen": camera.last_seen.isoformat() if camera.last_seen else None,
        "error_message": camera.error_message,
        "message": f"Camera is {camera.status}"
    }


@router.put("/cameras/{camera_id}", response_model=CameraResponse)
async def update_camera(
    camera_id: int,
    camera_data: CameraUpdate,
    db: Session = Depends(get_db),
    _=Depends(require_admin)
):
    """
    Update camera configuration.
    
    Args:
        camera_id: Camera ID (integer)
        camera_data: Updated camera data
        db: Database session
        
    Returns:
        CameraResponse: Updated camera data
    """
    camera = db.query(Camera).filter(Camera.id == camera_id).first()
    
    if not camera:
        raise HTTPException(status_code=404, detail=f"Camera with ID {camera_id} not found")
    
    # Update fields if provided
    if camera_data.name is not None:
        camera.name = camera_data.name
    
    if camera_data.location is not None:
        camera.location = camera_data.location
    
    if camera_data.stream_url is not None:
        camera.stream_url = camera_data.stream_url
    
    if camera_data.protocol is not None:
        valid_protocols = ["rtsp", "http", "local"]
        if camera_data.protocol not in valid_protocols:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid protocol. Must be one of: {', '.join(valid_protocols)}"
            )
        camera.protocol = camera_data.protocol
    
    if camera_data.is_active is not None:
        camera.is_active = camera_data.is_active
    
    if camera_data.frame_rate is not None:
        camera.frame_rate = camera_data.frame_rate
    
    camera.updated_at = datetime.now()
    
    db.commit()
    db.refresh(camera)
    
    return camera


@router.delete("/cameras/{camera_id}", status_code=204)
async def delete_camera(camera_id: int, db: Session = Depends(get_db), _=Depends(require_admin)):
    """
    Remove a camera from the system.
    
    Args:
        camera_id: Camera ID (integer)
        db: Database session
    """
    camera = db.query(Camera).filter(Camera.id == camera_id).first()
    
    if not camera:
        raise HTTPException(status_code=404, detail=f"Camera with ID {camera_id} not found")
    
    db.delete(camera)
    db.commit()
    
    return None


@router.post("/cameras/{camera_id}/start")
async def start_camera(camera_id: int, db: Session = Depends(get_db)):
    """
    Start a camera stream.
    
    Args:
        camera_id: Camera ID (integer)
        db: Database session
        
    Returns:
        dict: Success message
    """
    from app.main import video_streaming_service
    
    camera = db.query(Camera).filter(Camera.id == camera_id).first()
    
    if not camera:
        raise HTTPException(status_code=404, detail=f"Camera with ID {camera_id} not found")
    
    if not video_streaming_service:
        raise HTTPException(status_code=503, detail="Video streaming service not available")
    
    # Update camera to active
    camera.is_active = True
    db.commit()
    
    # Start the camera in video service
    try:
        await video_streaming_service.start_camera(
            camera_id=str(camera.id),
            stream_url=camera.stream_url,
            protocol=camera.protocol,
            location_name=camera.location
        )
        return {"message": f"Camera {camera_id} started successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to start camera: {str(e)}")


@router.post("/cameras/{camera_id}/stop")
async def stop_camera(camera_id: int, db: Session = Depends(get_db)):
    """
    Stop a camera stream.
    
    Args:
        camera_id: Camera ID (integer)
        db: Database session
        
    Returns:
        dict: Success message
    """
    from app.main import video_streaming_service
    
    camera = db.query(Camera).filter(Camera.id == camera_id).first()
    
    if not camera:
        raise HTTPException(status_code=404, detail=f"Camera with ID {camera_id} not found")
    
    if not video_streaming_service:
        raise HTTPException(status_code=503, detail="Video streaming service not available")
    
    # Update camera to inactive
    camera.is_active = False
    db.commit()
    
    # Stop the camera in video service
    try:
        await video_streaming_service.stop_camera(str(camera.id))
        return {"message": f"Camera {camera_id} stopped successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to stop camera: {str(e)}")
