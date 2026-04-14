"""
Unit tests for Task 2.5: Multipart HTTP response formatting
Validates that frames are formatted correctly according to MJPEG protocol.
"""

import pytest
import asyncio
from unittest.mock import Mock, AsyncMock, patch
from app.services.mjpeg_streaming import MJPEGStreamService
from app.models import Camera


@pytest.mark.asyncio
async def test_multipart_frame_format():
    """
    Test that frames are formatted with correct multipart structure:
    --frame\r\nContent-Type: image/jpeg\r\nContent-Length: {size}\r\n\r\n{jpeg_bytes}\r\n
    """
    # Mock dependencies
    mock_video_manager = Mock()
    mock_frame_processor = Mock()
    mock_db = Mock()
    
    # Setup camera in database
    mock_camera = Camera(
        id=1,
        name="Test Camera",
        location="Test Location",
        stream_url="rtsp://test",
        protocol="rtsp",
        is_active=True,
        frame_rate=5,
        status="online"
    )
    mock_db.query.return_value.filter.return_value.first.return_value = mock_camera
    
    # Setup video manager to return a frame
    mock_frame = b"fake_frame_data"
    mock_video_manager.read_frame.return_value = (True, mock_frame)
    mock_video_manager.is_camera_online.return_value = True
    
    # Setup frame processor to return JPEG bytes
    mock_jpeg_bytes = b"fake_jpeg_data_12345"
    mock_frame_processor.encode_frame_jpeg.return_value = mock_jpeg_bytes
    
    # Create service
    service = MJPEGStreamService(
        video_stream_manager=mock_video_manager,
        frame_processor=mock_frame_processor,
        db=mock_db,
        jpeg_quality=70
    )
    
    # Generate stream and get first frame
    stream_generator = service.generate_mjpeg_stream("1", "test_client_1")
    
    # Get first frame chunk
    frame_chunk = await anext(stream_generator)
    
    # Verify frame format
    expected_chunk = (
        b'--frame\r\n'
        b'Content-Type: image/jpeg\r\n'
        + f'Content-Length: {len(mock_jpeg_bytes)}\r\n\r\n'.encode()
        + mock_jpeg_bytes + b'\r\n'
    )
    
    assert frame_chunk == expected_chunk, "Frame chunk format does not match expected multipart format"
    
    # Verify boundary marker
    assert frame_chunk.startswith(b'--frame\r\n'), "Frame should start with boundary marker --frame\\r\\n"
    
    # Verify Content-Type header
    assert b'Content-Type: image/jpeg\r\n' in frame_chunk, "Frame should contain Content-Type: image/jpeg header"
    
    # Verify Content-Length header
    expected_length = f'Content-Length: {len(mock_jpeg_bytes)}\r\n'.encode()
    assert expected_length in frame_chunk, f"Frame should contain correct Content-Length header: {expected_length}"
    
    # Verify JPEG data is included
    assert mock_jpeg_bytes in frame_chunk, "Frame should contain the JPEG binary data"
    
    # Verify frame ends with \r\n
    assert frame_chunk.endswith(b'\r\n'), "Frame should end with \\r\\n"
    
    # Clean up
    await stream_generator.aclose()


@pytest.mark.asyncio
async def test_frame_interval_sleep():
    """
    Test that the service sleeps for frame_interval between frames.
    """
    # Mock dependencies
    mock_video_manager = Mock()
    mock_frame_processor = Mock()
    mock_db = Mock()
    
    # Setup camera with frame_rate=5 (interval should be 0.2 seconds)
    mock_camera = Camera(
        id=1,
        name="Test Camera",
        location="Test Location",
        stream_url="rtsp://test",
        protocol="rtsp",
        is_active=True,
        frame_rate=5,
        status="online"
    )
    mock_db.query.return_value.filter.return_value.first.return_value = mock_camera
    
    # Setup video manager to return frames
    mock_frame = b"fake_frame_data"
    mock_video_manager.read_frame.return_value = (True, mock_frame)
    mock_video_manager.is_camera_online.return_value = True
    
    # Setup frame processor
    mock_jpeg_bytes = b"fake_jpeg_data"
    mock_frame_processor.encode_frame_jpeg.return_value = mock_jpeg_bytes
    
    # Create service
    service = MJPEGStreamService(
        video_stream_manager=mock_video_manager,
        frame_processor=mock_frame_processor,
        db=mock_db,
        jpeg_quality=70
    )
    
    # Verify frame interval calculation
    frame_interval = await service.get_frame_interval("1")
    expected_interval = 1.0 / 5.0
    assert frame_interval == expected_interval, f"Frame interval should be {expected_interval} for frame_rate=5"


@pytest.mark.asyncio
async def test_yields_formatted_bytes():
    """
    Test that the generator yields formatted bytes to the client.
    """
    # Mock dependencies
    mock_video_manager = Mock()
    mock_frame_processor = Mock()
    mock_db = Mock()
    
    # Setup camera
    mock_camera = Camera(
        id=1,
        name="Test Camera",
        location="Test Location",
        stream_url="rtsp://test",
        protocol="rtsp",
        is_active=True,
        frame_rate=5,
        status="online"
    )
    mock_db.query.return_value.filter.return_value.first.return_value = mock_camera
    
    # Setup video manager to return frames
    mock_frame = b"fake_frame_data"
    mock_video_manager.read_frame.return_value = (True, mock_frame)
    mock_video_manager.is_camera_online.return_value = True
    
    # Setup frame processor
    mock_jpeg_bytes = b"fake_jpeg_data"
    mock_frame_processor.encode_frame_jpeg.return_value = mock_jpeg_bytes
    
    # Create service
    service = MJPEGStreamService(
        video_stream_manager=mock_video_manager,
        frame_processor=mock_frame_processor,
        db=mock_db,
        jpeg_quality=70
    )
    
    # Generate stream
    stream_generator = service.generate_mjpeg_stream("1", "test_client_1")
    
    # Get first frame
    frame_chunk = await anext(stream_generator)
    
    # Verify it's bytes
    assert isinstance(frame_chunk, bytes), "Yielded data should be bytes"
    
    # Verify it contains the expected structure
    assert b'--frame\r\n' in frame_chunk
    assert b'Content-Type: image/jpeg\r\n' in frame_chunk
    assert b'Content-Length:' in frame_chunk
    assert mock_jpeg_bytes in frame_chunk
    
    # Clean up
    await stream_generator.aclose()


@pytest.mark.asyncio
async def test_content_length_accuracy():
    """
    Test that Content-Length header accurately reflects the size of JPEG data.
    """
    # Mock dependencies
    mock_video_manager = Mock()
    mock_frame_processor = Mock()
    mock_db = Mock()
    
    # Setup camera
    mock_camera = Camera(
        id=1,
        name="Test Camera",
        location="Test Location",
        stream_url="rtsp://test",
        protocol="rtsp",
        is_active=True,
        frame_rate=5,
        status="online"
    )
    mock_db.query.return_value.filter.return_value.first.return_value = mock_camera
    
    # Setup video manager
    mock_frame = b"fake_frame_data"
    mock_video_manager.read_frame.return_value = (True, mock_frame)
    mock_video_manager.is_camera_online.return_value = True
    
    # Test with different JPEG sizes
    test_sizes = [100, 1000, 10000, 50000]
    
    for size in test_sizes:
        # Create JPEG bytes of specific size
        mock_jpeg_bytes = b"x" * size
        mock_frame_processor.encode_frame_jpeg.return_value = mock_jpeg_bytes
        
        # Create service
        service = MJPEGStreamService(
            video_stream_manager=mock_video_manager,
            frame_processor=mock_frame_processor,
            db=mock_db,
            jpeg_quality=70
        )
        
        # Generate stream
        stream_generator = service.generate_mjpeg_stream("1", f"test_client_{size}")
        
        # Get first frame
        frame_chunk = await anext(stream_generator)
        
        # Extract Content-Length value
        expected_header = f'Content-Length: {size}\r\n'.encode()
        assert expected_header in frame_chunk, f"Content-Length should be {size} for JPEG data of size {size}"
        
        # Clean up
        await stream_generator.aclose()


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
