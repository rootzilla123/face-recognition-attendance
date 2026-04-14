"""Test which DVR cameras are accessible."""

import cv2

cameras = [
    ("Camera 1", "rtsp://admin:Admin1234@192.168.0.104:554/cam/realmonitor?channel=1&subtype=0"),
    ("Camera 2", "rtsp://admin:Admin1234@192.168.0.104:554/cam/realmonitor?channel=2&subtype=0"),
    ("Camera 3", "rtsp://admin:Admin1234@192.168.0.104:554/cam/realmonitor?channel=3&subtype=0"),
    ("Camera 4", "rtsp://admin:Admin1234@192.168.0.104:554/cam/realmonitor?channel=4&subtype=0"),
]

print("Testing DVR cameras...")
print("="*60)

for name, url in cameras:
    print(f"\nTesting {name}...")
    print(f"URL: {url}")
    
    try:
        cap = cv2.VideoCapture(url)
        
        if not cap.isOpened():
            print(f"  ❌ Failed to open {name}")
            continue
        
        print(f"  ✓ {name} opened successfully")
        
        # Try to read a frame
        ret, frame = cap.read()
        
        if not ret or frame is None:
            print(f"  ❌ Failed to read frame from {name}")
            cap.release()
            continue
        
        print(f"  ✓ Successfully read frame: {frame.shape}")
        print(f"  ✅ {name} is working!")
        
        cap.release()
        
    except Exception as e:
        print(f"  ❌ Error: {e}")

print("\n" + "="*60)
print("Test complete!")
