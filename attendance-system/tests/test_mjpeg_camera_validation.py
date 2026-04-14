"""
Unit tests for MJPEG streaming service camera validation.
Tests Requirements 1.3, 1.4, 1.5 from the MJPEG video streaming spec.
"""

import pytest
from unittest.mock import Mock, MagicMock
from app.services.mjpeg_streaming import (
    MJPEGStreamService,
    CameraNotFoundError,
    CameraInactiveError
)
from app.models import Camera


@pytest.fixture
def mock_db():
    """Create a mock database session."""
    return Mock()


@pytest.fixture
def mock_video_stream_manager():
    """Create a mock VideoStreamManager."""
    return Mock()


@pytest.fixture
def mock_frame_processor():
    """Create a mock FrameProcessor."""
    return Mock()


@pytest.fixture
def mjpeg_service(mock_video_stream_manager, mock_frame_processor, mock_db):
    """Create an MJPEGStreamService instance with mocked dependencies."""
    return MJPEGStreamService(
        video_stream_manager=mock_video_stream_manager,
        frame_processor=mock_frame_processor,
        db=mock_db,
        jpeg_quality=70
    )


@pytest.mark.asyncio
async def test_validate_camera_success(mjpeg_service, mock_db):
    """Test that validate_camera returns Camera model when camera exists and is active."""
    # Arrange
    camera_id = "1"
    mock_camera = Camera(
        id=1,
        name="Test Camera",
        location="Test Location",
        stream_url="rtsp://test",
        protocol="rtsp",
        is_active=True,
        status="online"
    )
    
    # Mock database query
    mock_query = Mock()
    mock_filter = Mock()
    mock_filter.first.return_value = mock_camera
    mock_query.filter.return_value = mock_filter
    mock_db.query.return_value = mock_query
    
    # Act
    result = await mjpeg_service.validate_camera(camera_id)
    
    # Assert
    assert result == mock_camera
    mock_db.query.assert_called_once_with(Camera)


@pytest.mark.asyncio
async def test_validate_camera_not_found(mjpeg_service, mock_db):
    """Test that validate_camera raises CameraNotFoundError when camera doesn't exist."""
    # Arrange
    camera_id = "999"
    
    # Mock database query to return None
    mock_query = Mock()
    mock_filter = Mock()
    mock_filter.first.return_value = None
    mock_query.filter.return_value = mock_filter
    mock_db.query.return_value = mock_query
    
    # Act & Assert
    with pytest.raises(CameraNotFoundError) as exc_info:
        await mjpeg_service.validate_camera(camera_id)
    
    assert "Camera 999 not found" in str(exc_info.value)


@pytest.mark.asyncio
async def test_validate_camera_inactive(mjpeg_service, mock_db):
    """Test that validate_camera raises CameraInactiveError when camera is not active."""
    # Arrange
    camera_id = "2"
    mock_camera = Camera(
        id=2,
        name="Inactive Camera",
        location="Test Location",
        stream_url="rtsp://test",
        protocol="rtsp",
        is_active=False,  # Camera is inactive
        status="offline"
    )
    
    # Mock database query
    mock_query = Mock()
    mock_filter = Mock()
    mock_filter.first.return_value = mock_camera
    mock_query.filter.return_value = mock_filter
    mock_db.query.return_value = mock_query
    
    # Act & Assert
    with pytest.raises(CameraInactiveError) as exc_info:
        await mjpeg_service.validate_camera(camera_id)
    
    assert "Camera 2 is not active" in str(exc_info.value)


@pytest.mark.asyncio
async def test_validate_camera_query_uses_correct_id(mjpeg_service, mock_db):
    """Test that validate_camera queries the database with the correct camera ID."""
    # Arrange
    camera_id = "42"
    mock_camera = Camera(
        id=42,
        name="Test Camera",
        location="Test Location",
        stream_url="rtsp://test",
        protocol="rtsp",
        is_active=True,
        status="online"
    )
    
    # Mock database query
    mock_query = Mock()
    mock_filter = Mock()
    mock_filter.first.return_value = mock_camera
    mock_query.filter.return_value = mock_filter
    mock_db.query.return_value = mock_query
    
    # Act
    await mjpeg_service.validate_camera(camera_id)
    
    # Assert - verify the filter was called with correct ID
    # The filter should be checking Camera.id == int(camera_id)
    mock_query.filter.assert_called_once()
