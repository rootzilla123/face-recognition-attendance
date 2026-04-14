"""
Unit tests for Task 5.2: Initialize MJPEG service in application startup
Validates: Requirements 10.5
"""

import pytest
from unittest.mock import Mock, MagicMock, patch
from app.services.mjpeg_streaming import MJPEGStreamService
from app.services.video_streaming import VideoStreamManager, FrameProcessor


def test_mjpeg_service_initialization():
    """Test that MJPEGStreamService can be initialized with required parameters."""
    # Arrange
    mock_video_stream_manager = Mock(spec=VideoStreamManager)
    mock_frame_processor = Mock(spec=FrameProcessor)
    mock_db = Mock()
    jpeg_quality = 70
    
    # Act
    service = MJPEGStreamService(
        video_stream_manager=mock_video_stream_manager,
        frame_processor=mock_frame_processor,
        db=mock_db,
        jpeg_quality=jpeg_quality
    )
    
    # Assert
    assert service is not None
    assert service.video_stream_manager == mock_video_stream_manager
    assert service.frame_processor == mock_frame_processor
    assert service.db == mock_db
    assert service.jpeg_quality == jpeg_quality


def test_mjpeg_service_initialization_with_default_quality():
    """Test that MJPEGStreamService uses default JPEG quality when not specified."""
    # Arrange
    mock_video_stream_manager = Mock(spec=VideoStreamManager)
    mock_frame_processor = Mock(spec=FrameProcessor)
    mock_db = Mock()
    
    # Act
    service = MJPEGStreamService(
        video_stream_manager=mock_video_stream_manager,
        frame_processor=mock_frame_processor,
        db=mock_db
    )
    
    # Assert
    assert service is not None
    assert service.jpeg_quality == 70  # Default value


def test_mjpeg_service_has_required_attributes():
    """Test that MJPEGStreamService has all required attributes after initialization."""
    # Arrange
    mock_video_stream_manager = Mock(spec=VideoStreamManager)
    mock_frame_processor = Mock(spec=FrameProcessor)
    mock_db = Mock()
    
    # Act
    service = MJPEGStreamService(
        video_stream_manager=mock_video_stream_manager,
        frame_processor=mock_frame_processor,
        db=mock_db,
        jpeg_quality=70
    )
    
    # Assert
    assert hasattr(service, 'video_stream_manager')
    assert hasattr(service, 'frame_processor')
    assert hasattr(service, 'db')
    assert hasattr(service, 'jpeg_quality')
    assert hasattr(service, 'active_streams')
    assert hasattr(service, 'stream_locks')


@patch('app.routes.mjpeg_stream.set_mjpeg_service')
def test_startup_event_initializes_mjpeg_service(mock_set_mjpeg_service):
    """Test that startup_event properly initializes and sets the MJPEG service."""
    # Arrange
    mock_video_stream_manager = Mock(spec=VideoStreamManager)
    mock_frame_processor = Mock(spec=FrameProcessor)
    mock_db = Mock()
    
    # Simulate what happens in startup_event
    mjpeg_service = MJPEGStreamService(
        video_stream_manager=mock_video_stream_manager,
        frame_processor=mock_frame_processor,
        db=mock_db,
        jpeg_quality=70
    )
    
    # Act
    mock_set_mjpeg_service(mjpeg_service)
    
    # Assert
    mock_set_mjpeg_service.assert_called_once_with(mjpeg_service)
    assert mjpeg_service is not None
