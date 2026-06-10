from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from app.database import get_db, get_connection_stats
from app.routes import attendance, students, reports, notifications, cameras, websocket, mjpeg_stream, auth, marks
from app.routes.cameras import camera_health_loop
from app.routes import announcements, parent, admin, messages, chatbot, version, monitoring
from app.services.websocket import WebSocketManager
from app.services.video_streaming import VideoStreamingService
from app.services.mjpeg_streaming import MJPEGStreamService
from app.config import settings
import asyncio
import redis
import logging
import httpx
from sqlalchemy import text
import sentry_sdk
from sentry_sdk.integrations.fastapi import FastApiIntegration
from sentry_sdk.integrations.sqlalchemy import SqlalchemyIntegration

if settings.glitchtip_dsn:
    sentry_sdk.init(
        dsn=settings.glitchtip_dsn,
        integrations=[FastApiIntegration(), SqlalchemyIntegration()],
        traces_sample_rate=0.2,
        environment="production",
    )

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Create tables

app = FastAPI(title="Face Recognition Attendance System")

# Rate limiter
limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# Version enforcement middleware
from app.routes.version import VersionEnforcementMiddleware
app.add_middleware(VersionEnforcementMiddleware)

# Security headers middleware
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request as StarletteRequest

class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: StarletteRequest, call_next):
        response = await call_next(request)
        
        # Security headers
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["X-XSS-Protection"] = "1; mode=block"
        response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
        response.headers["Permissions-Policy"] = "geolocation=(), microphone=(), camera=()"
        
        # Content Security Policy
        csp = (
            "default-src 'self'; "
            "script-src 'self' 'unsafe-inline' 'unsafe-eval'; "
            "style-src 'self' 'unsafe-inline'; "
            "img-src 'self' data: https:; "
            "font-src 'self' data:; "
            "connect-src 'self' wss: https:; "
            "frame-ancestors 'none';"
        )
        response.headers["Content-Security-Policy"] = csp
        
        return response

app.add_middleware(SecurityHeadersMiddleware)

# CORS
import os
_origins = [
    "https://shadomfacepro.duckdns.org",
    "https://pb.shadomfacepro.duckdns.org",
    "http://localhost:3000",   # local dev only
]
app.add_middleware(
    CORSMiddleware,
    allow_origins=_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Ensure CORS headers present even on unhandled 500s
from fastapi import Request
from fastapi.responses import JSONResponse

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={"detail": str(exc)},
        headers={"Access-Control-Allow-Origin": "http://localhost:3000"},
    )

# Global instances
websocket_manager = None
video_streaming_service = None
redis_client = None
mjpeg_service = None


async def validate_startup_dependencies():
    """Fail fast on invalid runtime dependencies/configuration."""
    # Database connectivity
    db = next(get_db())
    try:
        db.execute(text("SELECT 1"))
    except Exception as e:
        raise RuntimeError(f"Database connectivity check failed: {e}") from e
    finally:
        db.close()

    # CompreFace API connectivity - Non-blocking (optional service)
    # Container port can open before CompreFace is fully ready
    # If unavailable at startup, face recognition will be unavailable until it's ready
    compreface_url = settings.comprefore_url.rstrip("/")
    compreface_ready = False
    last_error = None
    
    logger.info(f"Checking CompreFace connectivity at {compreface_url}...")
    
    for attempt in range(1, 6):  # Try 5 times (10 seconds total)
        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                # Try multiple endpoints to find one that works
                endpoints = [
                    f"{compreface_url}/status",
                    f"{compreface_url}/api/v1/status",
                    f"{compreface_url}/",
                ]
                
                for endpoint in endpoints:
                    try:
                        resp = await client.get(endpoint)
                        # Any response (2xx, 4xx, 5xx) means CompreFace is responding
                        if resp.status_code < 600:
                            logger.info(f"✓ CompreFace is responding at {endpoint}")
                            compreface_ready = True
                            break
                    except Exception:
                        continue
                
                if compreface_ready:
                    break
                    
        except Exception as e:
            last_error = e

        if attempt < 5 and not compreface_ready:
            logger.warning(
                f"CompreFace not ready yet (attempt {attempt}/5): {last_error}"
            )
            await asyncio.sleep(2)
    
    if not compreface_ready:
        logger.warning(
            f"⚠️  CompreFace not responding at startup (will retry on first use)\n"
            f"    Endpoint: {compreface_url}\n"
            f"    Last error: {last_error}\n"
            f"    Face recognition features will be unavailable until CompreFace is ready."
        )
    else:
        logger.info("✓ CompreFace ready for face recognition")

    # Twilio credentials validation (optional; skip in local development without network)
    if settings.twilio_account_sid and settings.twilio_auth_token:
        try:
            from twilio.rest import Client
            twilio_client = Client(settings.twilio_account_sid, settings.twilio_auth_token)
            twilio_client.api.accounts(settings.twilio_account_sid).fetch()
            logger.info("✓ Twilio credentials validated")
        except Exception as e:
            logger.warning(f"⚠️  Twilio validation skipped (no network or invalid credentials): {e}")
            # Don't crash - SMS/email notifications will fail gracefully if needed


async def connection_monitor_loop():
    """Monitor database connections every 60 seconds and log warnings."""
    while True:
        try:
            await asyncio.sleep(60)
            stats = get_connection_stats()
            if "error" not in stats:
                logger.info(f"DB Connections: {stats['total']}/{stats['max']} ({stats['usage_percent']}%) | Pool: {stats['pool_checked_out']}/{stats['pool_size']}")
        except Exception as e:
            logger.error(f"Connection monitor error: {e}")


@app.on_event("startup")
async def startup_event():
    """Initialize services on application startup."""
    global websocket_manager, video_streaming_service, redis_client, mjpeg_service
    
    try:
        logger.info("Starting Face Recognition Attendance System...")
        await validate_startup_dependencies()
        logger.info("Startup dependency validation passed")

        # Auto-run DB migrations on startup
        import subprocess
        from pathlib import Path
        import sys
        logger.info("Running database migrations...")
        
        # Use alembic from venv if available
        venv_alembic = Path(__file__).parent.parent / "venv" / "bin" / "alembic"
        alembic_cmd = str(venv_alembic) if venv_alembic.exists() else "alembic"
        
        result = subprocess.run(
            [alembic_cmd, "upgrade", "head"],
            capture_output=True, text=True,
            cwd=str(Path(__file__).parent.parent)
        )
        if result.returncode == 0:
            logger.info("Migrations complete")
        else:
            logger.warning(f"Migration output: {result.stderr or result.stdout}")
        
        # Initialize Redis client
        redis_client = redis.Redis.from_url(settings.redis_url, decode_responses=False)
        redis_client.ping()  # Test connection
        logger.info("Redis connection established")
        
        # Initialize WebSocket manager
        websocket_manager = WebSocketManager()
        websocket.set_websocket_manager(websocket_manager)
        logger.info("WebSocket manager initialized")
        
        # Initialize video streaming service
        db = next(get_db())
        video_streaming_service = VideoStreamingService(
            db=db,
            redis_client=redis_client,
            websocket_manager=websocket_manager,
            comprefore_url=settings.comprefore_url,
            comprefore_api_key=settings.comprefore_api_key,
            comprefore_detection_api_key=settings.comprefore_detection_api_key
        )
        
        # Start video streaming
        await video_streaming_service.start()
        logger.info("Video streaming service started")
        
        # Initialize MJPEG streaming service
        mjpeg_service = MJPEGStreamService(
            video_stream_manager=video_streaming_service.video_stream_manager,
            frame_processor=video_streaming_service.frame_processor,
            db=db,
            jpeg_quality=settings.mjpeg_quality
        )
        mjpeg_stream.set_mjpeg_service(mjpeg_service)
        logger.info("MJPEG streaming service initialized")
        
        logger.info("System startup complete!")
        asyncio.create_task(camera_health_loop(websocket_manager))
        asyncio.create_task(connection_monitor_loop())
        asyncio.create_task(video_streaming_service.clip_service.cleanup_loop())
        from app.services.notification_service import notification_cleanup_loop
        asyncio.create_task(notification_cleanup_loop(retention_days=30))
        
    except Exception as e:
        logger.error(f"Error during startup: {str(e)}")
        raise


@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup services on application shutdown."""
    global video_streaming_service, redis_client
    
    try:
        logger.info("Shutting down Face Recognition Attendance System...")
        
        # Stop video streaming
        if video_streaming_service:
            await video_streaming_service.stop()
            logger.info("Video streaming service stopped")
        
        # Close Redis connection
        if redis_client:
            redis_client.close()
            logger.info("Redis connection closed")
        
        logger.info("System shutdown complete")
        
    except Exception as e:
        logger.error(f"Error during shutdown: {str(e)}")


# Include routers
app.include_router(auth.router, prefix="/api/v1/auth", tags=["auth"])
app.include_router(attendance.router, prefix="/api/v1/attendance", tags=["attendance"])
app.include_router(students.router, prefix="/api/v1/students", tags=["students"])
app.include_router(reports.router, prefix="/api/v1/reports", tags=["reports"])
app.include_router(notifications.router, prefix="/api/v1/notifications", tags=["notifications"])
app.include_router(announcements.router, prefix="/api/v1/announcements", tags=["announcements"])
app.include_router(marks.router, prefix="/api/v1", tags=["marks"])
app.include_router(admin.router, prefix="/api/v1/admin", tags=["admin"])
app.include_router(parent.router, prefix="/api/v1/parent", tags=["parent"])
app.include_router(messages.router, prefix="/api/v1/messages", tags=["messages"])
app.include_router(chatbot.router, prefix="/api/v1", tags=["chatbot"])
app.include_router(cameras.router, prefix="/api/v1", tags=["cameras"])
app.include_router(mjpeg_stream.router, prefix="/api/v1", tags=["streaming"])
app.include_router(websocket.router, tags=["websocket"])
app.include_router(version.router, prefix="/api/v1", tags=["version"])
app.include_router(monitoring.router, prefix="/api/v1", tags=["monitoring"])

@app.get("/")
def root():
    return {"message": "Face Recognition Attendance System API"}

@app.get("/api/v1/health")
async def health_check():
    import httpx
    pb_status = "unknown"
    try:
        async with httpx.AsyncClient(timeout=2.0) as client:
            r = await client.get("http://localhost:8092/api/health")
            pb_status = "healthy" if r.status_code == 200 else "unhealthy"
    except Exception:
        pb_status = "unreachable"

    return {
        "status": "healthy",
        "websocket_connections": websocket_manager.get_connection_count() if websocket_manager else 0,
        "video_streaming": "running" if video_streaming_service and video_streaming_service.running else "stopped",
        "pocketbase": pb_status,
    }
