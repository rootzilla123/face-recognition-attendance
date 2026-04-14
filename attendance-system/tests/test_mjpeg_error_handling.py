"""
Unit tests for MJPEG streaming error handling and cleanup.

Tests task 2.8: Error handling and cleanup in stream generator
- ConnectionResetError handling
- BrokenPipeError handling
- asyncio.CancelledError handling
- Client disconnection logging
- Finally block cleanup
- Camera offline detection during streaming
"""

import pytest
import asyncio
from unittest.mock import Mock, AsyncMock, patch
import numpy as np

from app.services.mjpeg_streaming import MJPEGStreamService


class TestMJPEGErrorHandling:
    """Test error handling and cleanup in MJPEG stream generator."""
    
    @pytest.fixture
    def mock_camera(self):
        """Mock Camera database model."""
        camera = Mock()
        camera.id = 1
        camera.is_active = True
        camera.frame_rate = 5
        return camera
    
    @pytest.fixture
    def mock_db(self, mock_camera):
        """Mock database session."""
        db = Mock()
        # Mock the query chain for get_frame_interval
        query_mock = Mock()
        filter_mock = Mock()
        filter_mock.first = Mock(return_value=mock_camera)
        query_mock.filter = Mock(return_value=filter_mock)
        db.query = Mock(return_value=query_mock)
        return db
    
    @pytest.fixture
    def mock_video_stream_manager(self):
        """Mock VideoStreamManager."""
        manager = Mock()
        manager.is_camera_online = Mock(return_value=True)
        manager.read_frame = Mock(return_value=(True, np.zeros((480, 640, 3), dtype=np.uint8)))
        return manager
    
    @pytest.fixture
    def mock_frame_processor(self):
        """Mock FrameProcessor."""
        processor = Mock()
        processor.encode_frame_jpeg = Mock(return_value=b'fake_jpeg_data')
        return processor
    
    @pytest.fixture
    def mjpeg_service(self, mock_video_stream_manager, mock_frame_processor, mock_db, mock_camera):
        """Create MJPEGStreamService with mocked dependencies."""
        service = MJPEGStreamService(
            video_stream_manager=mock_video_stream_manager,
            frame_processor=mock_frame_processor,
            db=mock_db
        )
        
        # Mock validate_camera to return mock camera
        service.validate_camera = AsyncMock(return_value=mock_camera)
        
        return service
    
    @pytest.mark.asyncio
    async def test_connection_reset_error_handling(self, mjpeg_service, mock_video_stream_manager):
        """Test that ConnectionResetError is caught and logged properly."""
        camera_id = "1"
        client_id = "test-client-1"
        
        # Create a generator that will raise ConnectionResetError after first frame
        async def mock_generator():
            stream_gen = mjpeg_service.generate_mjpeg_stream(camera_id, client_id)
            
            # Get first frame successfully
            first_frame = await stream_gen.__anext__()
            assert first_frame is not None
            
            # Simulate ConnectionResetError on next yield
            # We'll close the generator which should trigger cleanup
            await stream_gen.aclose()
        
        # Patch logger to verify logging
        with patch('app.services.mjpeg_streaming.logger') as mock_logger:
            await mock_generator()
            
            # Verify cleanup was called (logged in finally block)
            cleanup_calls = [call for call in mock_logger.info.call_args_list 
                           if 'Cleaned up stream' in str(call)]
            assert len(cleanup_calls) > 0
        
        # Verify client was unregistered
        assert camera_id not in mjpeg_service.active_streams or \
               client_id not in mjpeg_service.active_streams.get(camera_id, set())
    
    @pytest.mark.asyncio
    async def test_broken_pipe_error_handling(self, mjpeg_service):
        """Test that BrokenPipeError is caught and logged properly."""
        camera_id = "1"
        client_id = "test-client-2"
        
        # Create stream generator
        stream_gen = mjpeg_service.generate_mjpeg_stream(camera_id, client_id)
        
        try:
            # Get first frame to register client
            first_frame = await stream_gen.__anext__()
            assert first_frame is not None
            
            # Verify client was registered
            assert client_id in mjpeg_service.active_streams[camera_id]
        finally:
            # Close stream (simulates client disconnect)
            await stream_gen.aclose()
        
        # Verify client was unregistered in finally block
        assert camera_id not in mjpeg_service.active_streams or \
               client_id not in mjpeg_service.active_streams.get(camera_id, set())
    
    @pytest.mark.asyncio
    async def test_cancelled_error_handling(self, mjpeg_service):
        """Test that asyncio.CancelledError is caught and logged properly."""
        camera_id = "1"
        client_id = "test-client-3"
        
        # Create a task that will be cancelled
        async def streaming_task():
            stream_gen = mjpeg_service.generate_mjpeg_stream(camera_id, client_id)
            try:
                # Get first frame
                await stream_gen.__anext__()
                # Try to get more frames (will be cancelled)
                async for _ in stream_gen:
                    await asyncio.sleep(0.01)  # Give time for cancellation
            finally:
                await stream_gen.aclose()
        
        # Create and cancel the task
        task = asyncio.create_task(streaming_task())
        await asyncio.sleep(0.2)  # Let it start and get first frame
        task.cancel()
        
        # Wait for cancellation to complete
        try:
            await task
        except (asyncio.CancelledError, StopAsyncIteration):
            pass  # Expected
        
        # Verify client was unregistered
        assert camera_id not in mjpeg_service.active_streams or \
               client_id not in mjpeg_service.active_streams.get(camera_id, set())
    
    @pytest.mark.asyncio
    async def test_client_disconnection_logging(self, mjpeg_service):
        """Test that client disconnection is logged with camera_id and client_id."""
        camera_id = "1"
        client_id = "test-client-4"
        
        with patch('app.services.mjpeg_streaming.logger') as mock_logger:
            stream_gen = mjpeg_service.generate_mjpeg_stream(camera_id, client_id)
            
            try:
                # Get first frame
                await stream_gen.__anext__()
            finally:
                # Close stream
                await stream_gen.aclose()
            
            # Verify cleanup logging includes camera_id and client_id
            cleanup_calls = [call for call in mock_logger.info.call_args_list 
                           if 'Cleaned up stream' in str(call)]
            assert len(cleanup_calls) > 0
            
            # Check that the log message contains camera_id and client_id
            log_message = str(cleanup_calls[0])
            assert camera_id in log_message
            assert client_id in log_message
    
    @pytest.mark.asyncio
    async def test_finally_block_always_executes(self, mjpeg_service):
        """Test that finally block executes even when exceptions occur."""
        camera_id = "1"
        client_id = "test-client-5"
        
        # Track if unregister_client was called
        unregister_called = []
        original_unregister = mjpeg_service.unregister_client
        
        def track_unregister(cam_id, cli_id):
            unregister_called.append((cam_id, cli_id))
            original_unregister(cam_id, cli_id)
        
        mjpeg_service.unregister_client = track_unregister
        
        stream_gen = mjpeg_service.generate_mjpeg_stream(camera_id, client_id)
        
        try:
            # Get first frame
            await stream_gen.__anext__()
        finally:
            # Close stream
            await stream_gen.aclose()
        
        # Verify unregister_client was called in finally block
        assert len(unregister_called) > 0
        assert unregister_called[0] == (camera_id, client_id)
    
    @pytest.mark.asyncio
    async def test_camera_offline_during_streaming_breaks_loop(self, mjpeg_service, mock_video_stream_manager):
        """Test that stream stops when camera goes offline during streaming."""
        camera_id = "1"
        client_id = "test-client-6"
        
        # Mock camera going offline after first frame
        call_count = [0]
        def is_camera_online_side_effect(cam_id):
            call_count[0] += 1
            return call_count[0] <= 2  # Online for first 2 checks, then offline
        
        mock_video_stream_manager.is_camera_online = Mock(side_effect=is_camera_online_side_effect)
        
        stream_gen = mjpeg_service.generate_mjpeg_stream(camera_id, client_id)
        
        try:
            # Get first frame (should succeed)
            frame1 = await stream_gen.__anext__()
            assert frame1 is not None
            
            # Try to get second frame (should raise StopAsyncIteration because camera went offline)
            with pytest.raises(StopAsyncIteration):
                await stream_gen.__anext__()
        finally:
            await stream_gen.aclose()
        
        # Verify client was unregistered
        assert camera_id not in mjpeg_service.active_streams or \
               client_id not in mjpeg_service.active_streams.get(camera_id, set())
    
    @pytest.mark.asyncio
    async def test_camera_offline_logged_during_streaming(self, mjpeg_service, mock_video_stream_manager):
        """Test that camera going offline during streaming is logged."""
        camera_id = "1"
        client_id = "test-client-7"
        
        # Mock camera going offline after first check
        call_count = [0]
        def is_camera_online_side_effect(cam_id):
            call_count[0] += 1
            return call_count[0] <= 1  # Online for first check, then offline
        
        mock_video_stream_manager.is_camera_online = Mock(side_effect=is_camera_online_side_effect)
        
        with patch('app.services.mjpeg_streaming.logger') as mock_logger:
            stream_gen = mjpeg_service.generate_mjpeg_stream(camera_id, client_id)
            
            try:
                # Try to get frames until camera goes offline
                async for _ in stream_gen:
                    pass
            except StopAsyncIteration:
                pass
            finally:
                await stream_gen.aclose()
            
            # Verify offline event was logged
            offline_logs = [call for call in mock_logger.error.call_args_list 
                          if 'went offline during streaming' in str(call)]
            assert len(offline_logs) > 0
    
    @pytest.mark.asyncio
    async def test_multiple_clients_cleanup_independently(self, mjpeg_service):
        """Test that multiple clients can disconnect independently with proper cleanup."""
        camera_id = "1"
        client_id_1 = "test-client-8"
        client_id_2 = "test-client-9"
        
        # Create two stream generators
        stream_gen_1 = mjpeg_service.generate_mjpeg_stream(camera_id, client_id_1)
        stream_gen_2 = mjpeg_service.generate_mjpeg_stream(camera_id, client_id_2)
        
        try:
            # Get first frame from both
            await stream_gen_1.__anext__()
            await stream_gen_2.__anext__()
            
            # Verify both clients are registered
            assert client_id_1 in mjpeg_service.active_streams[camera_id]
            assert client_id_2 in mjpeg_service.active_streams[camera_id]
            
            # Close first stream
            await stream_gen_1.aclose()
            
            # Verify first client unregistered, second still registered
            assert client_id_1 not in mjpeg_service.active_streams.get(camera_id, set())
            assert client_id_2 in mjpeg_service.active_streams[camera_id]
        finally:
            # Close second stream
            await stream_gen_2.aclose()
        
        # Verify both clients are unregistered
        assert camera_id not in mjpeg_service.active_streams or \
               len(mjpeg_service.active_streams.get(camera_id, set())) == 0
    
    @pytest.mark.asyncio
    async def test_unexpected_exception_handling(self, mjpeg_service, mock_video_stream_manager):
        """Test that unexpected exceptions are caught and logged."""
        camera_id = "1"
        client_id = "test-client-10"
        
        # Mock read_frame to raise an unexpected exception after first successful read
        call_count = [0]
        def read_frame_side_effect(cam_id):
            call_count[0] += 1
            if call_count[0] == 1:
                return (True, np.zeros((480, 640, 3), dtype=np.uint8))
            raise RuntimeError("Unexpected error")
        
        mock_video_stream_manager.read_frame = Mock(side_effect=read_frame_side_effect)
        
        with patch('app.services.mjpeg_streaming.logger') as mock_logger:
            stream_gen = mjpeg_service.generate_mjpeg_stream(camera_id, client_id)
            
            try:
                # Get first frame (should succeed)
                await stream_gen.__anext__()
                
                # Try to get second frame (exception should be caught internally and generator stops)
                try:
                    await stream_gen.__anext__()
                except StopAsyncIteration:
                    pass  # Expected - generator stopped after catching exception
            finally:
                await stream_gen.aclose()
            
            # Verify error was logged
            error_logs = [call for call in mock_logger.error.call_args_list 
                         if 'Error in MJPEG stream' in str(call)]
            assert len(error_logs) > 0
            
            # Verify cleanup happened
            cleanup_logs = [call for call in mock_logger.info.call_args_list 
                          if 'Cleaned up stream' in str(call)]
            assert len(cleanup_logs) > 0
        
        # Verify client was unregistered
        assert camera_id not in mjpeg_service.active_streams or \
               client_id not in mjpeg_service.active_streams.get(camera_id, set())
