"""
Webcam Device Finder
This script helps you find the correct device index for your webcams.
Run this before adding webcams to the attendance system.
"""

import cv2
import sys

def test_webcam(device_index):
    """Test if a webcam is available at the given device index."""
    print(f"\nTesting device index {device_index}...")
    
    cap = cv2.VideoCapture(device_index)
    
    if not cap.isOpened():
        print(f"  ❌ No camera found at index {device_index}")
        return False
    
    # Try to read a frame
    ret, frame = cap.read()
    
    if not ret or frame is None:
        print(f"  ❌ Camera at index {device_index} cannot read frames")
        cap.release()
        return False
    
    # Get camera properties
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    fps = int(cap.get(cv2.CAP_PROP_FPS))
    
    print(f"  ✅ Camera found at index {device_index}")
    print(f"     Resolution: {width}x{height}")
    print(f"     FPS: {fps}")
    print(f"     Frame shape: {frame.shape}")
    
    cap.release()
    return True

def find_all_webcams(max_devices=10):
    """Find all available webcams up to max_devices."""
    print("=" * 60)
    print("WEBCAM DEVICE FINDER")
    print("=" * 60)
    print(f"\nScanning for webcams (checking indices 0-{max_devices-1})...\n")
    
    found_devices = []
    
    for i in range(max_devices):
        if test_webcam(i):
            found_devices.append(i)
    
    print("\n" + "=" * 60)
    print("SUMMARY")
    print("=" * 60)
    
    if found_devices:
        print(f"\n✅ Found {len(found_devices)} webcam(s):")
        for idx in found_devices:
            print(f"   • Device Index: {idx}")
        
        print("\n📝 To use these webcams in the attendance system:")
        print("   1. Go to the Cameras page")
        print("   2. Click 'Add Camera'")
        print("   3. Select 'Local' protocol")
        print("   4. Enter the device index from above")
        
        if len(found_devices) == 1:
            print(f"\n💡 Quick tip: Use device index {found_devices[0]} for your webcam")
    else:
        print("\n❌ No webcams found!")
        print("\nTroubleshooting:")
        print("  • Make sure your webcam is connected")
        print("  • Close other applications using the webcam (Zoom, Teams, etc.)")
        print("  • Check if the webcam works in other applications")
        print("  • On Linux: Make sure you're in the 'video' group")
        print("  • On Windows: Check Privacy Settings → Camera permissions")
    
    print("\n" + "=" * 60)

def test_specific_device(device_index):
    """Test a specific device and show a preview window."""
    print("=" * 60)
    print(f"TESTING DEVICE {device_index}")
    print("=" * 60)
    
    cap = cv2.VideoCapture(device_index)
    
    if not cap.isOpened():
        print(f"\n❌ Cannot open camera at index {device_index}")
        print("\nTroubleshooting:")
        print("  • Try a different device index")
        print("  • Make sure the webcam is connected")
        print("  • Close other applications using the webcam")
        return
    
    print(f"\n✅ Camera opened successfully!")
    print(f"   Resolution: {int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))}x{int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))}")
    print(f"   FPS: {int(cap.get(cv2.CAP_PROP_FPS))}")
    print("\n📹 Opening preview window...")
    print("   Press 'q' or ESC to close the preview")
    
    frame_count = 0
    
    while True:
        ret, frame = cap.read()
        
        if not ret:
            print(f"\n⚠️  Failed to read frame {frame_count}")
            break
        
        frame_count += 1
        
        # Add text overlay
        cv2.putText(frame, f"Device {device_index} - Frame {frame_count}", 
                    (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
        cv2.putText(frame, "Press 'q' or ESC to exit", 
                    (10, 60), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)
        
        cv2.imshow(f'Webcam Test - Device {device_index}', frame)
        
        # Wait for key press (1ms)
        key = cv2.waitKey(1) & 0xFF
        if key == ord('q') or key == 27:  # 'q' or ESC
            break
    
    cap.release()
    cv2.destroyAllWindows()
    
    print(f"\n✅ Successfully captured {frame_count} frames")
    print(f"   This device is working correctly!")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        # Test specific device
        try:
            device_index = int(sys.argv[1])
            test_specific_device(device_index)
        except ValueError:
            print("Error: Device index must be a number")
            print("Usage: python test_webcam.py [device_index]")
            print("Example: python test_webcam.py 0")
    else:
        # Find all devices
        find_all_webcams()
        
        print("\n💡 To test a specific device with preview:")
        print("   python test_webcam.py <device_index>")
        print("   Example: python test_webcam.py 0")
