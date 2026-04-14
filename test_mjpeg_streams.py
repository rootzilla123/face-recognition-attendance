"""
Test MJPEG stream endpoints to verify they're working.
"""
import httpx
import asyncio

async def test_mjpeg_streams():
    """Test MJPEG stream endpoints"""
    base_url = "http://localhost:8001"
    
    async with httpx.AsyncClient(timeout=10.0) as client:
        # Get all cameras
        response = await client.get(f"{base_url}/api/v1/cameras")
        cameras = response.json()
        
        print(f"Testing MJPEG streams for {len(cameras)} cameras\n")
        
        for camera in cameras:
            camera_id = camera['id']
            camera_name = camera['name']
            status = camera['status']
            
            print(f"Camera {camera_id}: {camera_name} (status: {status})")
            
            if status != 'online':
                print(f"  ⚠ Camera is {status}, skipping stream test\n")
                continue
            
            # Test MJPEG stream endpoint
            mjpeg_url = f"{base_url}/api/v1/mjpeg/stream/{camera_id}"
            print(f"  Testing: {mjpeg_url}")
            
            try:
                # Just check if we can connect and get the first chunk
                async with client.stream('GET', mjpeg_url, timeout=5.0) as stream:
                    if stream.status_code == 200:
                        # Read first chunk to verify stream is working
                        chunk = await stream.aiter_bytes().__anext__()
                        if chunk:
                            print(f"  ✓ MJPEG stream working (received {len(chunk)} bytes)")
                        else:
                            print(f"  ✗ No data received from stream")
                    else:
                        print(f"  ✗ HTTP {stream.status_code}: {stream.text}")
            except Exception as e:
                print(f"  ✗ Error: {e}")
            
            print()

if __name__ == "__main__":
    asyncio.run(test_mjpeg_streams())
