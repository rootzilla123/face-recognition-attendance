"""
Test script to verify camera connection and MJPEG streaming.
"""

import cv2
import requests

def test_camera_connection():
    """Test if we can connect to the camera directly."""
    camera_url = "rtsp://admin:Admin1234@192.168.0.104:554/cam/realmonitor?channel=1&subtype=0"
    
    print("Testing camera connection...")
    print(f"URL: {camera_url}")
    
    try:
        cap = cv2.VideoCapture(camera_url)
        
        if not cap.isOpened():
            print("❌ Failed to open camera")
            return False
        
        print("✓ Camera opened successfully")
        
        # Try to read a frame
        ret, frame = cap.read()
        
        if not ret or frame is None:
            print("❌ Failed to read frame from camera")
            cap.release()
            return False
        
        print(f"✓ Successfully read frame: {frame.shape}")
        
        cap.release()
        return True
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return False


def test_mjpeg_endpoint():
    """Test the MJPEG streaming endpoint."""
    print("\nTesting MJPEG endpoint...")
    
    try:
        response = requests.get(
            "http://192.168.0.111:8001/api/v1/cameras/3/stream",
            stream=True,
            timeout=5
        )
        
        print(f"Status code: {response.status_code}")
        print(f"Content-Type: {response.headers.get('content-type')}")
        
        if response.status_code == 200:
            print("✓ MJPEG endpoint is accessible")
            return True
        elif response.status_code == 503:
            print("❌ Camera is offline (503)")
            return False
        else:
            print(f"❌ Unexpected status: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return False


if __name__ == "__main__":
    print("="*50)
    print("Camera Connection Test")
    print("="*50)
    
    # Test 1: Direct camera connection
    camera_ok = test_camera_connection()
    
    # Test 2: MJPEG endpoint
    mjpeg_ok = test_mjpeg_endpoint()
    
    print("\n" + "="*50)
    print("Summary:")
    print(f"  Camera connection: {'✓' if camera_ok else '❌'}")
    print(f"  MJPEG endpoint: {'✓' if mjpeg_ok else '❌'}")
    print("="*50)
