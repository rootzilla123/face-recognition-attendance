"""
Tests for MJPEG frame rate calculation functionality.

Validates Requirements 3.1, 3.2, 3.5 from the MJPEG streaming spec.
"""

import pytest
from unittest.mock import Mock, MagicMock
from app.services.mjpeg_streaming import MJPEGStreamService
from app.models import Camera


@pytest.fixture
def mock_db():
    """Create a mock database session."""
    return Mock()


@pytest.fixture
def mock_video_stream_manager():
    """Create a mock video stream manager."""
    return Mock()


@pytest.fixture
def mock_frame_processor():
    """Create a mock frame processor."""
    return Mock()


@pytest.fixture
def mjpeg_service(mock_db, mock_video_stream_manager, mock_frame_processor):
    """Create an MJPEG service instance with mocked dependencies."""
    return MJPEGStreamService(
        video_stream_manager=mock_video_stream_manager,
        frame_processor=mock_frame_processor,
        db=mock_db
    )


@pytest.mark.asyncio
async def test_get_frame_interval_with_valid_frame_rate(mjpeg_service, mock_db):
    """
    Test that get_frame_interval correctly calculates interval from frame rate.
    
    Validates: Requirements 3.1, 3.2, 3.5
    - Reads Frame_Rate from Camera database record
    - Calculates interval as 1.0 / Frame_Rate
    - Returns float representing seconds between frames
    """
    # Arrange
    camera_id = "1"
    frame_rate = 5
    expected_interval = 1.0 / 5.0  # 0.2 seconds
    
    mock_camera = Mock(spec=Camera)
    mock_camera.id = 1
    mock_camera.frame_rate = frame_rate
    
    mock_query = MagicMock()
    mock_db.query.return_value = mock_query
    mock_query.filter.return_value = mock_query
    mock_query.first.return_value = mock_camera
    
    # Act
    result = await mjpeg_service.get_frame_interval(camera_id)
    
    # Assert
    assert result == expected_interval
    assert isinstance(result, float)
    mock_db.query.assert_called_once()


@pytest.mark.asyncio
async def test_get_frame_interval_with_different_frame_rates(mjpeg_service, mock_db):
    """
    Test frame interval calculation with various frame rates.
    
    Validates: Requirement 3.2 - Support Frame_Rate values between 1 and 10 FPS
    """
    test_cases = [
        (1, 1.0),      # 1 FPS -> 1.0 second interval
        (2, 0.5),      # 2 FPS -> 0.5 second interval
        (5, 0.2),      # 5 FPS -> 0.2 second interval
        (10, 0.1),     # 10 FPS -> 0.1 second interval
    ]
    
    for frame_rate, expected_interval in test_cases:
        # Arrange
        camera_id = "1"
        mock_camera = Mock(spec=Camera)
        mock_camera.id = 1
        mock_camera.frame_rate = frame_rate
        
        mock_query = MagicMock()
        mock_db.query.return_value = mock_query
        mock_query.filter.return_value = mock_query
        mock_query.first.return_value = mock_camera
        
        # Act
        result = await mjpeg_service.get_frame_interval(camera_id)
        
        # Assert
        assert result == pytest.approx(expected_interval, rel=1e-9), \
            f"Frame rate {frame_rate} should produce interval {expected_interval}, got {result}"


@pytest.mark.asyncio
async def test_get_frame_interval_with_no_camera(mjpeg_service, mock_db):
    """
    Test that get_frame_interval returns default interval when camera not found.
    
    Validates: Graceful handling when camera doesn't exist
    """
    # Arrange
    camera_id = "999"
    expected_default_interval = 1.0 / 5.0  # Default 5 FPS
    
    mock_query = MagicMock()
    mock_db.query.return_value = mock_query
    mock_query.filter.return_value = mock_query
    mock_query.first.return_value = None  # Camera not found
    
    # Act
    result = await mjpeg_service.get_frame_interval(camera_id)
    
    # Assert
    assert result == expected_default_interval
    assert isinstance(result, float)


@pytest.mark.asyncio
async def test_get_frame_interval_with_no_frame_rate_configured(mjpeg_service, mock_db):
    """
    Test that get_frame_interval returns default interval when frame_rate is None.
    
    Validates: Graceful handling when frame_rate is not configured
    """
    # Arrange
    camera_id = "1"
    expected_default_interval = 1.0 / 5.0  # Default 5 FPS
    
    mock_camera = Mock(spec=Camera)
    mock_camera.id = 1
    mock_camera.frame_rate = None  # Not configured
    
    mock_query = MagicMock()
    mock_db.query.return_value = mock_query
    mock_query.filter.return_value = mock_query
    mock_query.first.return_value = mock_camera
    
    # Act
    result = await mjpeg_service.get_frame_interval(camera_id)
    
    # Assert
    assert result == expected_default_interval
    assert isinstance(result, float)


@pytest.mark.asyncio
async def test_get_frame_interval_calculation_precision(mjpeg_service, mock_db):
    """
    Test that frame interval calculation maintains precision.
    
    Validates: Requirement 3.5 - Calculate frame interval as 1.0 / Frame_Rate
    """
    # Arrange
    camera_id = "1"
    frame_rate = 3
    
    mock_camera = Mock(spec=Camera)
    mock_camera.id = 1
    mock_camera.frame_rate = frame_rate
    
    mock_query = MagicMock()
    mock_db.query.return_value = mock_query
    mock_query.filter.return_value = mock_query
    mock_query.first.return_value = mock_camera
    
    # Act
    result = await mjpeg_service.get_frame_interval(camera_id)
    
    # Assert
    # Verify the calculation is exactly 1.0 / frame_rate
    expected = 1.0 / float(frame_rate)
    assert result == expected
    # Verify it's a proper float division result
    assert result == pytest.approx(0.3333333333333333, rel=1e-9)
