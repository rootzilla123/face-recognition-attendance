import requests
import json

url = "http://localhost:8001/api/v1/cameras"
data = {
    "name": "Test Camera 2",
    "location": "Test Location 2",
    "stream_url": "rtsp://admin:Admin1234@192.168.0.104:554/cam/realmonitor?channel=2&subtype=0",
    "protocol": "rtsp",
    "username": "admin",
    "password": "Admin1234",
    "is_active": True
}

print("Sending request to:", url)
print("Data:", json.dumps(data, indent=2))
print()

try:
    response = requests.post(url, json=data)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {response.text}")
    
    if response.status_code == 201:
        print("\n✓ Camera added successfully!")
        print(json.dumps(response.json(), indent=2))
    else:
        print(f"\n✗ Error: {response.status_code}")
        
except Exception as e:
    print(f"✗ Exception: {e}")
