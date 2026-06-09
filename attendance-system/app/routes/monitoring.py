"""
Comprehensive monitoring and health check endpoints.
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from pydantic import BaseModel
from typing import Dict, Any
import psutil
import httpx
import logging
from datetime import datetime

from app.database import get_db
from app.config import settings
from app.dependencies import require_admin

logger = logging.getLogger(__name__)
router = APIRouter()


class HealthStatus(BaseModel):
    status: str
    timestamp: str
    services: Dict[str, Any]
    system: Dict[str, Any]


class MetricsResponse(BaseModel):
    database: Dict[str, Any]
    redis: Dict[str, Any]
    system: Dict[str, Any]
    services: Dict[str, Any]


@router.get("/health/detailed", response_model=HealthStatus)
async def detailed_health_check(db: Session = Depends(get_db)):
    """
    Comprehensive health check for all services.
    Used by monitoring tools like Uptime Kuma.
    """
    timestamp = datetime.utcnow().isoformat()
    services = {}
    
    # Check database
    try:
        db.execute(text("SELECT 1"))
        services["database"] = {"status": "healthy", "type": "postgresql"}
    except Exception as e:
        services["database"] = {"status": "unhealthy", "error": str(e)}
    
    # Check Redis
    try:
        from app.main import redis_client
        if redis_client:
            redis_client.ping()
            services["redis"] = {"status": "healthy"}
        else:
            services["redis"] = {"status": "unknown", "error": "Not initialized"}
    except Exception as e:
        services["redis"] = {"status": "unhealthy", "error": str(e)}
    
    # Check CompreFace
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(f"{settings.comprefore_url}/api/v1/recognition/subjects")
            if response.status_code in [200, 401]:  # 401 is ok, means service is up
                services["compreface"] = {"status": "healthy"}
            else:
                services["compreface"] = {"status": "degraded", "status_code": response.status_code}
    except Exception as e:
        services["compreface"] = {"status": "unhealthy", "error": str(e)}
    
    # Check Ollama
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(f"{settings.ollama_url}/api/tags")
            if response.status_code == 200:
                services["ollama"] = {"status": "healthy"}
            else:
                services["ollama"] = {"status": "degraded", "status_code": response.status_code}
    except Exception as e:
        services["ollama"] = {"status": "unhealthy", "error": str(e)}
    
    # Check PocketBase
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(f"{settings.pb_url}/api/health")
            if response.status_code == 200:
                services["pocketbase"] = {"status": "healthy"}
            else:
                services["pocketbase"] = {"status": "degraded", "status_code": response.status_code}
    except Exception as e:
        services["pocketbase"] = {"status": "unhealthy", "error": str(e)}
    
    # System metrics
    system = {
        "cpu_percent": psutil.cpu_percent(interval=1),
        "memory_percent": psutil.virtual_memory().percent,
        "disk_percent": psutil.disk_usage('/').percent,
    }
    
    # Overall status
    unhealthy_services = [k for k, v in services.items() if v.get("status") == "unhealthy"]
    overall_status = "unhealthy" if unhealthy_services else "healthy"
    
    return HealthStatus(
        status=overall_status,
        timestamp=timestamp,
        services=services,
        system=system,
    )


@router.get("/metrics", response_model=MetricsResponse)
async def get_metrics(
    db: Session = Depends(get_db),
    _=Depends(require_admin)
):
    """
    Detailed metrics for monitoring dashboards.
    Admin only.
    """
    from app.models import AttendanceRecord, Student, Camera, Notification
    from app.database import get_connection_stats
    from datetime import date, timedelta
    
    # Database metrics
    db_stats = get_connection_stats()
    today = date.today()
    
    database_metrics = {
        "connections": db_stats,
        "total_students": db.query(Student).filter(Student.is_active == True).count(),
        "total_attendance_today": db.query(AttendanceRecord).filter(
            AttendanceRecord.timestamp >= datetime.combine(today, datetime.min.time())
        ).count(),
        "total_attendance_week": db.query(AttendanceRecord).filter(
            AttendanceRecord.timestamp >= datetime.combine(today - timedelta(days=7), datetime.min.time())
        ).count(),
        "active_cameras": db.query(Camera).filter(
            Camera.is_active == True,
            Camera.status == "online"
        ).count(),
        "pending_notifications": db.query(Notification).filter(
            Notification.status == "pending"
        ).count(),
    }
    
    # Redis metrics
    redis_metrics = {}
    try:
        from app.main import redis_client
        if redis_client:
            info = redis_client.info()
            redis_metrics = {
                "used_memory_human": info.get("used_memory_human"),
                "connected_clients": info.get("connected_clients"),
                "total_commands_processed": info.get("total_commands_processed"),
                "keyspace_hits": info.get("keyspace_hits", 0),
                "keyspace_misses": info.get("keyspace_misses", 0),
            }
    except Exception as e:
        redis_metrics = {"error": str(e)}
    
    # System metrics
    system_metrics = {
        "cpu": {
            "percent": psutil.cpu_percent(interval=1),
            "count": psutil.cpu_count(),
        },
        "memory": {
            "total": psutil.virtual_memory().total,
            "available": psutil.virtual_memory().available,
            "percent": psutil.virtual_memory().percent,
        },
        "disk": {
            "total": psutil.disk_usage('/').total,
            "used": psutil.disk_usage('/').used,
            "free": psutil.disk_usage('/').free,
            "percent": psutil.disk_usage('/').percent,
        },
    }
    
    # Service metrics
    service_metrics = {
        "websocket_connections": 0,
        "video_streams_active": 0,
    }
    
    try:
        from app.main import websocket_manager, video_streaming_service
        if websocket_manager:
            service_metrics["websocket_connections"] = websocket_manager.get_connection_count()
        if video_streaming_service:
            service_metrics["video_streams_active"] = len(video_streaming_service.video_stream_manager.streams)
    except Exception as e:
        logger.warning(f"Could not get service metrics: {e}")
    
    return MetricsResponse(
        database=database_metrics,
        redis=redis_metrics,
        system=system_metrics,
        services=service_metrics,
    )


@router.get("/health/storage")
async def check_storage(_=Depends(require_admin)):
    """
    Check storage usage for critical directories.
    Alerts if disk space is low.
    """
    import os
    from pathlib import Path
    
    checks = {}
    
    # Check clips directory
    clips_dir = Path(settings.clips_dir)
    if clips_dir.exists():
        total_size = sum(f.stat().st_size for f in clips_dir.rglob('*') if f.is_file())
        checks["clips_directory"] = {
            "path": str(clips_dir),
            "size_bytes": total_size,
            "size_human": f"{total_size / (1024**3):.2f} GB",
            "file_count": len(list(clips_dir.rglob('*'))),
        }
    
    # Check root disk
    disk = psutil.disk_usage('/')
    checks["root_disk"] = {
        "total": disk.total,
        "used": disk.used,
        "free": disk.free,
        "percent": disk.percent,
        "alert": disk.percent > 85,
    }
    
    return checks
