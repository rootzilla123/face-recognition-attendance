"""
Mobile app version enforcement.

Ensures old mobile app versions are blocked if they're incompatible with the API.
"""
from fastapi import APIRouter, HTTPException, Header
from pydantic import BaseModel
from typing import Optional
import logging

logger = logging.getLogger(__name__)
router = APIRouter()

# Minimum supported versions
MIN_ANDROID_VERSION = "1.0.0"
MIN_IOS_VERSION = "1.0.0"

# Current latest versions
LATEST_ANDROID_VERSION = "1.0.0"
LATEST_IOS_VERSION = "1.0.0"


class VersionCheckResponse(BaseModel):
    is_supported: bool
    min_version: str
    latest_version: str
    update_required: bool
    update_url: Optional[str] = None
    message: Optional[str] = None


def parse_version(version_str: str) -> tuple:
    """Parse version string like '1.2.3' into (1, 2, 3)"""
    try:
        return tuple(map(int, version_str.split('.')))
    except:
        return (0, 0, 0)


@router.get("/version/check", response_model=VersionCheckResponse)
def check_version(
    x_app_version: Optional[str] = Header(None),
    x_app_platform: Optional[str] = Header(None, description="android or ios")
):
    """
    Check if the mobile app version is supported.
    
    Headers:
    - X-App-Version: e.g., "1.2.3"
    - X-App-Platform: "android" or "ios"
    """
    if not x_app_version or not x_app_platform:
        raise HTTPException(
            status_code=400,
            detail="Missing required headers: X-App-Version and X-App-Platform"
        )
    
    platform = x_app_platform.lower()
    if platform not in ["android", "ios"]:
        raise HTTPException(status_code=400, detail="Platform must be 'android' or 'ios'")
    
    # Get min and latest versions for platform
    min_version = MIN_ANDROID_VERSION if platform == "android" else MIN_IOS_VERSION
    latest_version = LATEST_ANDROID_VERSION if platform == "android" else LATEST_IOS_VERSION
    
    # Parse versions
    current = parse_version(x_app_version)
    minimum = parse_version(min_version)
    latest = parse_version(latest_version)
    
    # Check if supported
    is_supported = current >= minimum
    update_required = current < minimum
    update_available = current < latest
    
    # Build response
    response = VersionCheckResponse(
        is_supported=is_supported,
        min_version=min_version,
        latest_version=latest_version,
        update_required=update_required,
    )
    
    if update_required:
        response.message = f"Your app version ({x_app_version}) is no longer supported. Please update to version {min_version} or later."
        response.update_url = (
            "https://play.google.com/store/apps/details?id=com.shadomfacepro.attendance"
            if platform == "android"
            else "https://apps.apple.com/app/shadomfacepro/id123456789"
        )
    elif update_available:
        response.message = f"A new version ({latest_version}) is available. Please update for the best experience."
        response.update_url = (
            "https://play.google.com/store/apps/details?id=com.shadomfacepro.attendance"
            if platform == "android"
            else "https://apps.apple.com/app/shadomfacepro/id123456789"
        )
    
    return response


# Middleware to enforce version check on all API calls
from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import JSONResponse

class VersionEnforcementMiddleware(BaseHTTPMiddleware):
    """Middleware to block requests from unsupported app versions."""
    
    # Exempt these paths from version checking
    EXEMPT_PATHS = [
        "/",
        "/docs",
        "/redoc",
        "/openapi.json",
        "/api/v1/health",
        "/api/v1/version/check",
        "/api/v1/auth/login",
        "/api/v1/auth/register",
    ]
    
    async def dispatch(self, request: Request, call_next):
        # Skip version check for exempt paths
        if any(request.url.path.startswith(path) for path in self.EXEMPT_PATHS):
            return await call_next(request)
        
        # Skip for non-mobile clients (web dashboard, etc.)
        x_app_version = request.headers.get("x-app-version")
        x_app_platform = request.headers.get("x-app-platform")
        
        if not x_app_version or not x_app_platform:
            # Not a mobile app request, allow it
            return await call_next(request)
        
        # Check version
        platform = x_app_platform.lower()
        if platform not in ["android", "ios"]:
            return await call_next(request)
        
        min_version = MIN_ANDROID_VERSION if platform == "android" else MIN_IOS_VERSION
        current = parse_version(x_app_version)
        minimum = parse_version(min_version)
        
        if current < minimum:
            return JSONResponse(
                status_code=426,  # Upgrade Required
                content={
                    "detail": f"App version {x_app_version} is no longer supported. Please update to version {min_version} or later.",
                    "min_version": min_version,
                    "update_url": (
                        "https://play.google.com/store/apps/details?id=com.shadomfacepro.attendance"
                        if platform == "android"
                        else "https://apps.apple.com/app/shadomfacepro/id123456789"
                    )
                }
            )
        
        return await call_next(request)
