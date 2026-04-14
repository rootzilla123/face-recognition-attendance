"""
Unit tests for MJPEG stream generation functionality.
Tests the generate_mjpeg_stream async generator method.
"""

import pytest
import asyncio
from unittest.mock import Mock, AsyncMock, MagicMock
from app.services.mjpeg_streaming import (
    MJPEGStreamService,
    CameraNotFoundError,
    CameraInactiveError,
    CameraOfflineError
)
from app.models import Camera


class TestGenerateMJPEGStream:
    """Test suite for generate_mjpeg_stream method."""
    
    @pytest.fixture
    def mock_db(self):
        """Create mock database session."""
        db = Mock()
        return db
    
    @pytest.fixture
    def mock_video_stream_manager(self):
        """Create mock VideoStreamManager."""
        manager = Mock()
        manager.is_camera_online = Mock(return_value=True)
        manager.read_frame = Mock(return_value=(True, b'fake_frame_data'))
        return manager
    
    @pytest.fixture
    def mock_frame_processor(self):
        """Create mock FrameProcessor."""
        processor = Mock()
        processor.encode_frame_jpeg = Mock(return_value=b'fake_jpeg_data')
        return processor
    
    @pytest.fixture
    def mock_camera(self):
        """Create mock Camera model."""
        camera = Mock(spec=Camera)
        camera.id = 1
        camera.is_active = True
        camera.frame_rate = 5
        return camera
    
    @pytest.fixture
    def mjpeg_service(self, mock_video_stream_manager, mock_frame_processor, mock_db, mock_camera):
        """Create MJPEGStreamService instance with mocks."""
        # Mock database query
        mock_query = Mock()
        mock_query.filter = Mock(return_value=mock_query)
        mock_query.first = Mock(return_value=mock_camera)
        mock_db.query = Mock(return_value=mock_query)
        
        service = MJPEGStreamService(
            video_stream_manager=mock_video_stream_manager,
            frame_processor=mock_frame_processor,
            db=mock_db,
            jpeg_quality=70
        )
        return service
    
    @pytest.mark.asyncio
    async def test_generate_mjpeg_stream_validates_camera(self, mjpeg_service, mock_db):
        """Test that generate_mjpeg_stream validates camera exists and is active."""
        camera_id = "1"
        client_id = "test-client-1"
        
        # Create async generator
        stream_gen = mjpeg_service.generate_mjpeg_stream(camera_id, client_id)
        
        # Get first frame to trigger validation
        try:
            first_frame = await stream_gen.__anext__()
            # If we get here, validation passed
            assert first_frame is not None
        finally:
            # Cleanup
            await stream_gen.aclose()
        
        # Verify database was queried for camera
        mock_db.query.assert_called()
    
    @pytest.mark.asyncio
    async def test_generate_mjpeg_stream_raises_camera_not_found(self, mjpeg_service, mock_db):
        """Test that generate_mjpeg_stream raises CameraNotFoundError for non-existent camera."""
        # Mock camera not found
        mock_query = Mock()
        mock_query.filter = Mock(return_value=mock_query)
        mock_query.first = Mock(return_value=None)
        mock_db.query = Mock(return_value=mock_query)
        
        camera_id = "999"
        client_id = "test-client-1"
        
        # Should raise CameraNotFoundError
        with pytest.raises(CameraNotFoundError):
            stream_gen = mjpeg_service.generate_mjpeg_stream(camera_id, client_id)
            await stream_gen.__anext__()
    
    @pytest.mark.asyncio
    async def test_generate_mjpeg_stream_raises_camera_inactive(self, mjpeg_service, mock_db, mock_camera):
        """Test that generate_mjpeg_stream raises CameraInactiveError for inactive camera."""
        # Mock inactive camera
        mock_camera.is_active = False
        mock_query = Mock()
        mock_query.filter = Mock(return_value=mock_query)
        mock_query.first = Mock(return_value=mock_camera)
        mock_db.query = Mock(return_value=mock_query)
        
        camera_id = "1"
        client_id = "test-client-1"
        
        # Should raise CameraInactiveError
        with pytest.raises(CameraInactiveError):
            stream_gen = mjpeg_service.generate_mjpeg_stream(camera_id, client_id)
            await stream_gen.__anext__()
    
    @pytest.mark.asyncio
    async def test_generate_mjpeg_stream_raises_camera_offline(self, mjpeg_service, mock_video_stream_manager):
        """Test that generate_mjpeg_stream raises CameraOfflineError for offline camera."""
        # Mock camera offline
        mock_video_stream_manager.is_camera_online = Mock(return_value=False)
        
        camera_id = "1"
        client_id = "test-client-1"
        
        # Should raise CameraOfflineError
        with pytest.raises(CameraOfflineError):
            stream_gen = mjpeg_service.generate_mjpeg_stream(camera_id, client_id)
            await stream_gen.__anext__()
    
    @pytest.mark.asyncio
    async def test_generate_mjpeg_stream_registers_client(self, mjpeg_service):
        """Test that generate_mjpeg_stream registers client."""
        camera_id = "1"
        client_id = "test-client-1"
        
        # Create async generator
        stream_gen = mjpeg_service.generate_mjpeg_stream(camera_id, client_id)
        
        try:
            # Get first frame to trigger registration
            await stream_gen.__anext__()
            
            # Verify client was registered
            assert camera_id in mjpeg_service.active_streams
            assert client_id in mjpeg_service.active_streams[camera_id]
        finally:
            # Cleanup
            await stream_gen.aclose()
    
    @pytest.mark.asyncio
    async def test_generate_mjpeg_stream_uses_frame_interval(self, mjpeg_service, mock_camera):
        """Test that generate_mjpeg_stream uses correct frame interval."""
        camera_id = "1"
        client_id = "test-client-1"
        
        # Camera has frame_rate = 5, so interval should be 0.2 seconds
        expected_interval = 1.0 / 5.0
        
        # Create async generator
        stream_gen = mjpeg_service.generate_mjpeg_stream(camera_id, client_id)
        
        try:
            # Get first frame
            await stream_gen.__anext__()
            
            # Verify frame interval was calculated correctly
            frame_interval = await mjpeg_service.get_frame_interval(camera_id)
            assert frame_interval == expected_interval
        finally:
            # Cleanup
            await stream_gen.aclose()
    
    @pytest.mark.asyncio
    async def test_generate_mjpeg_stream_yields_multipart_format(self, mjpeg_service, mock_frame_processor):
        """Test that generate_mjpeg_stream yields frames in correct multipart format."""
        camera_id = "1"
        client_id = "test-client-1"
        
        # Mock JPEG data
        fake_jpeg = b'fake_jpeg_data'
        mock_frame_processor.encode_frame_jpeg = Mock(return_value=fake_jpeg)
        
        # Create async generator
        stream_gen = mjpeg_service.generate_mjpeg_stream(camera_id, client_id)
        
        try:
            # Get first frame
            frame_chunk = await stream_gen.__anext__()
            
            # Verify multipart format
            assert b'--frame\r\n' in frame_chunk
            assert b'Content-Type: image/jpeg\r\n' in frame_chunk
            assert f'Content-Length: {len(fake_jpeg)}\r\n\r\n'.encode() in frame_chunk
            assert fake_jpeg in frame_chunk
        finally:
            # Cleanup
            await stream_gen.aclose()
    
    @pytest.mark.asyncio
    async def test_generate_mjpeg_stream_calls_read_frame(self, mjpeg_service, mock_video_stream_manager):
        """Test that generate_mjpeg_stream calls video_stream_manager.read_frame."""
        camera_id = "1"
        client_id = "test-client-1"
        
        # Create async generator
        stream_gen = mjpeg_service.generate_mjpeg_stream(camera_id, client_id)
        
        try:
            # Get first frame
            await stream_gen.__anext__()
            
            # Verify read_frame was called
            mock_video_stream_manager.read_frame.assert_called_with(camera_id)
        finally:
            # Cleanup
            await stream_gen.aclose()
    
    @pytest.mark.asyncio
    async def test_generate_mjpeg_stream_calls_encode_frame_jpeg(self, mjpeg_service, mock_frame_processor):
        """Test that generate_mjpeg_stream calls frame_processor.encode_frame_jpeg with correct quality."""
        camera_id = "1"
        client_id = "test-client-1"
        
        # Create async generator
        stream_gen = mjpeg_service.generate_mjpeg_stream(camera_id, client_id)
        
        try:
            # Get first frame
            await stream_gen.__anext__()
            
            # Verify encode_frame_jpeg was called with quality=70
            mock_frame_processor.encode_frame_jpeg.assert_called()
            call_args = mock_frame_processor.encode_frame_jpeg.call_args
            assert call_args[1]['quality'] == 70
        finally:
            # Cleanup
            await stream_gen.aclose()
    
    @pytest.mark.asyncio
    async def test_generate_mjpeg_stream_skips_failed_frame_read(self, mjpeg_service, mock_video_stream_manager):
        """Test that generate_mjpeg_stream skips frames when read_frame fails."""
        camera_id = "1"
        client_id = "test-client-1"
        
        # Mock frame read failure followed by success
        mock_video_stream_manager.read_frame = Mock(side_effect=[
            (False, None),  # First call fails
            (True, b'fake_frame_data')  # Second call succeeds
        ])
        
        # Create async generator
        stream_gen = mjpeg_service.generate_mjpeg_stream(camera_id, client_id)
        
        try:
            # Get first frame (should skip failed read and return second frame)
            frame_chunk = await stream_gen.__anext__()
            
            # Verify we got a frame
            assert frame_chunk is not None
            assert b'--frame\r\n' in frame_chunk
            
            # Verify read_frame was called twice
            assert mock_video_stream_manager.read_frame.call_count == 2
        finally:
            # Cleanup
            await stream_gen.aclose()
    
    @pytest.mark.asyncio
    async def test_generate_mjpeg_stream_skips_failed_encoding(self, mjpeg_service, mock_frame_processor):
        """Test that generate_mjpeg_stream skips frames when encoding fails."""
        camera_id = "1"
        client_id = "test-client-1"
        
        # Mock encoding failure followed by success
        mock_frame_processor.encode_frame_jpeg = Mock(side_effect=[
            None,  # First call fails
            b'fake_jpeg_data'  # Second call succeeds
        ])
        
        # Create async generator
        stream_gen = mjpeg_service.generate_mjpeg_stream(camera_id, client_id)
        
        try:
            # Get first frame (should skip failed encoding and return second frame)
            frame_chunk = await stream_gen.__anext__()
            
            # Verify we got a frame
            assert frame_chunk is not None
            assert b'--frame\r\n' in frame_chunk
            
            # Verify encode_frame_jpeg was called twice
            assert mock_frame_processor.encode_frame_jpeg.call_count == 2
        finally:
            # Cleanup
            await stream_gen.aclose()
    
    @pytest.mark.asyncio
    async def test_generate_mjpeg_stream_unregisters_client_on_close(self, mjpeg_service):
        """Test that generate_mjpeg_stream unregisters client when stream closes."""
        camera_id = "1"
        client_id = "test-client-1"
        
        # Create async generator
        stream_gen = mjpeg_service.generate_mjpeg_stream(camera_id, client_id)
        
        # Get first frame to trigger registration
        await stream_gen.__anext__()
        
        # Verify client was registered
        assert client_id in mjpeg_service.active_streams[camera_id]
        
        # Close stream
        await stream_gen.aclose()
        
        # Verify client was unregistered
        assert camera_id not in mjpeg_service.active_streams or \
               client_id not in mjpeg_service.active_streams.get(camera_id, set())
    
    @pytest.mark.asyncio
    async def test_generate_mjpeg_stream_stops_when_camera_goes_offline(self, mjpeg_service, mock_video_stream_manager):
        """Test that generate_mjpeg_stream stops when camera goes offline during streaming."""
        camera_id = "1"
        client_id = "test-client-1"
        
        # Mock camera going offline after first frame
        call_count = [0]
        def is_camera_online_side_effect(cam_id):
            call_count[0] += 1
            return call_count[0] <= 2  # Online for first 2 checks, then offline
        
        mock_video_stream_manager.is_camera_online = Mock(side_effect=is_camera_online_side_effect)
        
        # Create async generator
        stream_gen = mjpeg_service.generate_mjpeg_stream(camera_id, client_id)
        
        try:
            # Get first frame (should succeed)
            frame1 = await stream_gen.__anext__()
            assert frame1 is not None
            
            # Try to get second frame (should raise StopAsyncIteration because camera went offline)
            with pytest.raises(StopAsyncIteration):
                await stream_gen.__anext__()
        finally:
            # Cleanup
            await stream_gen.aclose()
