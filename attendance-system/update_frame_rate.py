"""Update camera frame rate to 10 FPS for real-time streaming."""

import requests

# Update camera 3 frame rate to 10 FPS
response = requests.put(
    "http://localhost:8001/api/v1/cameras/3",
    json={"frame_rate": 10}
)

print(f"Status: {response.status_code}")
print(f"Response: {response.json()}")
