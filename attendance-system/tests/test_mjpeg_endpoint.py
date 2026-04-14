"""
Unit tests for MJPEG stream endpoint (Task 4.2).
Tests the stream_camera endpoint implementation.
"""

import pytest
import uuid
from unittest.mock import Mock, AsyncMock, patch
from fastapi import HTTPException
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session

from app.routes.mjpeg_stream import stream_camera, get_mjpeg_service, set_mjpeg_service
from app.services.mjpeg_streaming import (
    MJPEGStreamService,
    CameraNotFoundError,
    CameraInactiveError,
    CameraOfflineError
)


class TestStreamCameraEndpoint:
    """Test suite for stream_camera endpoint (Task 4.2)."""
    
    @pytest.mark.asyncio
    async def test_stream_camera_success(self):
        """Test successful stream request returns StreamingResponse with correct content type."""
        # Arrange
        camera_id = 1
        mock_request = Mock()
        mock_db = Mock(spec=Session)
        mock_mjpeg_service = Mock(spec=MJPEGStreamService)
        
        # Create async generator mock
        async def mock_generator():
            yield b"--frame\r\n"
            yield b"Content-Type: image/jpeg\r\n\r\n"
            yield b"fake_jpeg_data"
        
        mock_mjpeg_service.generate_mjpeg_stream = Mock(return_value=mock_generator())
        
        # Act
        response = await stream_camera(
            camera_id=camera_id,
            request=mock_request,
            db=mock_db,
            mjpeg_service=mock_mjpeg_service
        )
        
        # Assert
        assert isinstance(response, StreamingResponse)
        assert response.media_type == "multipart/x-mixed-replace; boundary=frame"
        mock_mjpeg_service.generate_mjpeg_stream.assert_called_once()
        
        # Verify camera_id is converted to string
        call_args = mock_mjpeg_service.generate_mjpeg_stream.call_args
        assert call_args[0][0] == str(camera_id)
        
        # Verify client_id is a valid UUID string
        client_id = call_args[0][1]
        assert isinstance(client_id, str)
        # Verify it's a valid UUID by trying to parse it
        uuid.UUID(client_id)
    
    @pytest.mark.asyncio
    async def test_stream_camera_not_found(self):
        """Test stream request for non-existent camera returns 404."""
        # Arrange
        camera_id = 999
        mock_request = Mock()
        mock_db = Mock(spec=Session)
        mock_mjpeg_service = Mock(spec=MJPEGStreamService)
        
        mock_mjpeg_service.generate_mjpeg_stream = Mock(
            side_effect=CameraNotFoundError("Camera not found")
        )
        
        # Act & Assert
        with pytest.raises(HTTPException) as exc_info:
            await stream_camera(
                camera_id=camera_id,
                request=mock_request,
                db=mock_db,
                mjpeg_service=mock_mjpeg_service
            )
        
        assert exc_info.value.status_code == 404
        assert exc_info.value.detail == "Camera not found"
    
    @pytest.mark.asyncio
    async def test_stream_camera_inactive(self):
        """Test stream request for inactive camera returns 400."""
        # Arrange
        camera_id = 1
        mock_request = Mock()
        mock_db = Mock(spec=Session)
        mock_mjpeg_service = Mock(spec=MJPEGStreamService)
        
        mock_mjpeg_service.generate_mjpeg_stream = Mock(
            side_effect=CameraInactiveError("Camera is not active")
        )
        
        # Act & Assert
        with pytest.raises(HTTPException) as exc_info:
            await stream_camera(
                camera_id=camera_id,
                request=mock_request,
                db=mock_db,
                mjpeg_service=mock_mjpeg_service
            )
        
        assert exc_info.value.status_code == 400
        assert exc_info.value.detail == "Camera is not active"
    
    @pytest.mark.asyncio
    async def test_stream_camera_offline(self):
        """Test stream request for offline camera returns 503."""
        # Arrange
        camera_id = 1
        mock_request = Mock()
        mock_db = Mock(spec=Session)
        mock_mjpeg_service = Mock(spec=MJPEGStreamService)
        
        mock_mjpeg_service.generate_mjpeg_stream = Mock(
            side_effect=CameraOfflineError("Camera is offline")
        )
        
        # Act & Assert
        with pytest.raises(HTTPException) as exc_info:
            await stream_camera(
                camera_id=camera_id,
                request=mock_request,
                db=mock_db,
                mjpeg_service=mock_mjpeg_service
            )
        
        assert exc_info.value.status_code == 503
        assert exc_info.value.detail == "Camera is offline"
    
    @pytest.mark.asyncio
    async def test_stream_camera_unexpected_error(self):
        """Test stream request with unexpected error returns 500."""
        # Arrange
        camera_id = 1
        mock_request = Mock()
        mock_db = Mock(spec=Session)
        mock_mjpeg_service = Mock(spec=MJPEGStreamService)
        
        mock_mjpeg_service.generate_mjpeg_stream = Mock(
            side_effect=Exception("Unexpected error")
        )
        
        # Act & Assert
        with pytest.raises(HTTPException) as exc_info:
            await stream_camera(
                camera_id=camera_id,
                request=mock_request,
                db=mock_db,
                mjpeg_service=mock_mjpeg_service
            )
        
        assert exc_info.value.status_code == 500
        assert exc_info.value.detail == "Internal server error"
    
    def test_get_mjpeg_service_not_initialized(self):
        """Test get_mjpeg_service raises error when service not initialized."""
        # Arrange
        import app.routes.mjpeg_stream as mjpeg_module
        original_service = mjpeg_module._mjpeg_service
        mjpeg_module._mjpeg_service = None
        
        try:
            # Act & Assert
            with pytest.raises(HTTPException) as exc_info:
                get_mjpeg_service()
            
            assert exc_info.value.status_code == 500
            assert exc_info.value.detail == "MJPEG service not initialized"
        finally:
            # Restore original service
            mjpeg_module._mjpeg_service = original_service
    
    def test_set_and_get_mjpeg_service(self):
        """Test set_mjpeg_service and get_mjpeg_service work correctly."""
        # Arrange
        mock_service = Mock(spec=MJPEGStreamService)
        
        # Act
        set_mjpeg_service(mock_service)
        retrieved_service = get_mjpeg_service()
        
        # Assert
        assert retrieved_service is mock_service
