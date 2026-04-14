"""Add all 4 cameras from the DVR to the system."""

import requests

API_BASE = "http://localhost:8001/api/v1"

cameras = [
    {
        "name": "Camera 1",
        "location": "Entrance",
        "stream_url": "rtsp://admin:Admin1234@192.168.0.104:554/cam/realmonitor?channel=1&subtype=0",
        "protocol": "rtsp",
        "is_active": True,
        "frame_rate": 10
    },
    {
        "name": "Camera 2",
        "location": "Hallway",
        "stream_url": "rtsp://admin:Admin1234@192.168.0.104:554/cam/realmonitor?channel=2&subtype=0",
        "protocol": "rtsp",
        "is_active": True,
        "frame_rate": 10
    },
    {
        "name": "Camera 3",
        "location": "Classroom",
        "stream_url": "rtsp://admin:Admin1234@192.168.0.104:554/cam/realmonitor?channel=3&subtype=0",
        "protocol": "rtsp",
        "is_active": True,
        "frame_rate": 10
    },
    {
        "name": "Camera 4",
        "location": "Exit",
        "stream_url": "rtsp://admin:Admin1234@192.168.0.104:554/cam/realmonitor?channel=4&subtype=0",
        "protocol": "rtsp",
        "is_active": True,
        "frame_rate": 10
    }
]

print("Adding cameras to the system...")
print("="*50)

for camera in cameras:
    try:
        response = requests.post(f"{API_BASE}/cameras", json=camera)
        if response.status_code == 200:
            result = response.json()
            print(f"✓ Added {camera['name']} (ID: {result['id']}) - {camera['location']}")
        else:
            print(f"✗ Failed to add {camera['name']}: {response.status_code}")
    except Exception as e:
        print(f"✗ Error adding {camera['name']}: {e}")

print("="*50)
print("Done! Refresh your browser to see all cameras.")
