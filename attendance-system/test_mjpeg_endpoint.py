"""
Simple test script to verify MJPEG streaming endpoint is working.
Run this after starting the backend server.
"""

import requests
import time

def test_mjpeg_endpoint():
    """Test the MJPEG streaming endpoint."""
    base_url = "http://192.168.0.111:8001"
    
    # Test 1: Check health endpoint
    print("Test 1: Checking health endpoint...")
    try:
        response = requests.get(f"{base_url}/api/v1/health")
        print(f"✓ Health check: {response.status_code} - {response.json()}")
    except Exception as e:
        print(f"✗ Health check failed: {e}")
        return
    
    # Test 2: Get list of cameras
    print("\nTest 2: Getting camera list...")
    try:
        response = requests.get(f"{base_url}/api/v1/cameras")
        cameras = response.json()
        print(f"✓ Found {len(cameras)} cameras")
        
        if len(cameras) == 0:
            print("⚠ No cameras found. Please add a camera first.")
            return
        
        # Use first camera for testing
        camera_id = cameras[0]['id']
        print(f"  Using camera ID: {camera_id}")
        
    except Exception as e:
        print(f"✗ Failed to get cameras: {e}")
        return
    
    # Test 3: Test MJPEG stream endpoint (just check headers, don't download full stream)
    print(f"\nTest 3: Testing MJPEG stream endpoint for camera {camera_id}...")
    try:
        response = requests.get(
            f"{base_url}/api/v1/cameras/{camera_id}/stream",
            stream=True,
            timeout=5
        )
        
        print(f"  Status code: {response.status_code}")
        print(f"  Content-Type: {response.headers.get('content-type')}")
        
        if response.status_code == 200:
            content_type = response.headers.get('content-type', '')
            if 'multipart/x-mixed-replace' in content_type:
                print("✓ MJPEG stream endpoint is working correctly!")
                print("  Receiving first few bytes...")
                
                # Read first chunk to verify stream is working
                chunk_count = 0
                for chunk in response.iter_content(chunk_size=1024):
                    if chunk:
                        chunk_count += 1
                        if chunk_count >= 3:  # Read 3 chunks then stop
                            break
                
                print(f"  Successfully received {chunk_count} chunks")
            else:
                print(f"✗ Wrong content type: {content_type}")
        elif response.status_code == 404:
            print("✗ Camera not found (404)")
        elif response.status_code == 400:
            print("✗ Camera not active (400)")
        elif response.status_code == 503:
            print("✗ Camera offline (503)")
        else:
            print(f"✗ Unexpected status code: {response.status_code}")
            
    except requests.exceptions.Timeout:
        print("✗ Request timed out - camera might be offline")
    except Exception as e:
        print(f"✗ Stream test failed: {e}")
    
    # Test 4: Test non-existent camera (should return 404)
    print("\nTest 4: Testing error handling (non-existent camera)...")
    try:
        response = requests.get(f"{base_url}/api/v1/cameras/99999/stream", timeout=2)
        if response.status_code == 404:
            print("✓ Correctly returns 404 for non-existent camera")
        else:
            print(f"✗ Expected 404, got {response.status_code}")
    except Exception as e:
        print(f"✗ Error test failed: {e}")
    
    print("\n" + "="*50)
    print("MJPEG endpoint testing complete!")
    print("="*50)

if __name__ == "__main__":
    print("MJPEG Streaming Endpoint Test")
    print("="*50)
    test_mjpeg_endpoint()
