"""Optimize all cameras for real-time streaming with minimal delay."""

import requests

API_BASE = "http://localhost:8001/api/v1"

# Get all cameras
response = requests.get(f"{API_BASE}/cameras")
cameras = response.json()

print("Optimizing cameras for real-time streaming...")
print("="*60)

for camera in cameras:
    camera_id = camera['id']
    
    # Update camera settings for real-time streaming
    update_data = {
        "frame_rate": 15  # Increase to 15 FPS for smoother video
    }
    
    try:
        response = requests.put(
            f"{API_BASE}/cameras/{camera_id}",
            json=update_data
        )
        
        if response.status_code == 200:
            print(f"✓ Optimized Camera {camera_id} ({camera['name']}) - 15 FPS")
        else:
            print(f"✗ Failed to optimize Camera {camera_id}: {response.status_code}")
    except Exception as e:
        print(f"✗ Error optimizing Camera {camera_id}: {e}")

print("="*60)
print("Done! Restart the backend to apply changes:")
print("  python -m uvicorn app.main:app --host 127.0.0.1 --port 8001 --reload")
