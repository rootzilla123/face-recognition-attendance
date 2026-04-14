"""
Unit tests for MJPEG client connection management methods.
Tests task 1.5: register_client, unregister_client, get_client_count
"""

import pytest
from unittest.mock import Mock, MagicMock
from app.services.mjpeg_streaming import MJPEGStreamService


class TestClientConnectionManagement:
    """Test suite for client connection management methods."""
    
    @pytest.fixture
    def mjpeg_service(self):
        """Create a MJPEGStreamService instance with mocked dependencies."""
        video_stream_manager = Mock()
        frame_processor = Mock()
        db = Mock()
        
        service = MJPEGStreamService(
            video_stream_manager=video_stream_manager,
            frame_processor=frame_processor,
            db=db,
            jpeg_quality=70
        )
        return service
    
    def test_register_client_adds_to_active_streams(self, mjpeg_service):
        """Test that register_client adds client to active_streams."""
        camera_id = "1"
        client_id = "client-123"
        
        mjpeg_service.register_client(camera_id, client_id)
        
        assert camera_id in mjpeg_service.active_streams
        assert client_id in mjpeg_service.active_streams[camera_id]
    
    def test_register_multiple_clients_same_camera(self, mjpeg_service):
        """Test that multiple clients can register for the same camera."""
        camera_id = "1"
        client_id_1 = "client-123"
        client_id_2 = "client-456"
        
        mjpeg_service.register_client(camera_id, client_id_1)
        mjpeg_service.register_client(camera_id, client_id_2)
        
        assert len(mjpeg_service.active_streams[camera_id]) == 2
        assert client_id_1 in mjpeg_service.active_streams[camera_id]
        assert client_id_2 in mjpeg_service.active_streams[camera_id]
    
    def test_unregister_client_removes_from_active_streams(self, mjpeg_service):
        """Test that unregister_client removes client from active_streams."""
        camera_id = "1"
        client_id = "client-123"
        
        # Register then unregister
        mjpeg_service.register_client(camera_id, client_id)
        mjpeg_service.unregister_client(camera_id, client_id)
        
        # Camera should be removed from active_streams when no clients remain
        assert camera_id not in mjpeg_service.active_streams
    
    def test_unregister_client_keeps_other_clients(self, mjpeg_service):
        """Test that unregistering one client doesn't affect other clients."""
        camera_id = "1"
        client_id_1 = "client-123"
        client_id_2 = "client-456"
        
        # Register two clients
        mjpeg_service.register_client(camera_id, client_id_1)
        mjpeg_service.register_client(camera_id, client_id_2)
        
        # Unregister one client
        mjpeg_service.unregister_client(camera_id, client_id_1)
        
        # Camera should still be in active_streams
        assert camera_id in mjpeg_service.active_streams
        # Only client_id_2 should remain
        assert client_id_2 in mjpeg_service.active_streams[camera_id]
        assert client_id_1 not in mjpeg_service.active_streams[camera_id]
        assert len(mjpeg_service.active_streams[camera_id]) == 1
    
    def test_unregister_nonexistent_client_no_error(self, mjpeg_service):
        """Test that unregistering a non-existent client doesn't raise an error."""
        camera_id = "1"
        client_id = "client-123"
        
        # Should not raise an error
        mjpeg_service.unregister_client(camera_id, client_id)
    
    def test_get_client_count_returns_zero_for_no_clients(self, mjpeg_service):
        """Test that get_client_count returns 0 when no clients are connected."""
        camera_id = "1"
        
        count = mjpeg_service.get_client_count(camera_id)
        
        assert count == 0
    
    def test_get_client_count_returns_correct_count(self, mjpeg_service):
        """Test that get_client_count returns the correct number of clients."""
        camera_id = "1"
        client_id_1 = "client-123"
        client_id_2 = "client-456"
        client_id_3 = "client-789"
        
        mjpeg_service.register_client(camera_id, client_id_1)
        mjpeg_service.register_client(camera_id, client_id_2)
        mjpeg_service.register_client(camera_id, client_id_3)
        
        count = mjpeg_service.get_client_count(camera_id)
        
        assert count == 3
    
    def test_get_client_count_updates_after_unregister(self, mjpeg_service):
        """Test that get_client_count updates correctly after unregistering clients."""
        camera_id = "1"
        client_id_1 = "client-123"
        client_id_2 = "client-456"
        
        mjpeg_service.register_client(camera_id, client_id_1)
        mjpeg_service.register_client(camera_id, client_id_2)
        
        assert mjpeg_service.get_client_count(camera_id) == 2
        
        mjpeg_service.unregister_client(camera_id, client_id_1)
        
        assert mjpeg_service.get_client_count(camera_id) == 1
        
        mjpeg_service.unregister_client(camera_id, client_id_2)
        
        assert mjpeg_service.get_client_count(camera_id) == 0
    
    def test_multiple_cameras_independent_client_tracking(self, mjpeg_service):
        """Test that client tracking is independent for different cameras."""
        camera_id_1 = "1"
        camera_id_2 = "2"
        client_id_1 = "client-123"
        client_id_2 = "client-456"
        
        mjpeg_service.register_client(camera_id_1, client_id_1)
        mjpeg_service.register_client(camera_id_2, client_id_2)
        
        assert mjpeg_service.get_client_count(camera_id_1) == 1
        assert mjpeg_service.get_client_count(camera_id_2) == 1
        
        mjpeg_service.unregister_client(camera_id_1, client_id_1)
        
        assert mjpeg_service.get_client_count(camera_id_1) == 0
        assert mjpeg_service.get_client_count(camera_id_2) == 1
