"""
Reconnect all cameras after IP address update.
This will stop and restart all camera streams.
"""
import asyncio
import httpx

async def reconnect_all_cameras():
    """Reconnect all cameras via the API"""
    base_url = "http://localhost:8001/api/v1"
    
    async with httpx.AsyncClient(timeout=30.0) as client:
        # Get all cameras
        response = await client.get(f"{base_url}/cameras")
        cameras = response.json()
        
        print(f"Found {len(cameras)} cameras")
        
        for camera in cameras:
            camera_id = camera['id']
            camera_name = camera['name']
            
            print(f"\nReconnecting camera {camera_id}: {camera_name}")
            
            try:
                # Stop the camera first
                stop_response = await client.post(f"{base_url}/cameras/{camera_id}/stop")
                if stop_response.status_code == 200:
                    print(f"  ✓ Stopped camera {camera_id}")
                
                # Wait a moment
                await asyncio.sleep(1)
                
                # Start the camera
                start_response = await client.post(f"{base_url}/cameras/{camera_id}/start")
                if start_response.status_code == 200:
                    print(f"  ✓ Started camera {camera_id}")
                else:
                    print(f"  ✗ Failed to start camera {camera_id}: {start_response.text}")
                    
            except Exception as e:
                print(f"  ✗ Error reconnecting camera {camera_id}: {e}")
        
        print("\n✓ Reconnection complete!")

if __name__ == "__main__":
    asyncio.run(reconnect_all_cameras())
