"""
Test RTSP URLs with correct credentials
"""
import cv2

DVR_IP = "192.168.0.104"
USERNAME = "admin"
PASSWORD = "Admin1234"
PORT = "554"

# Test all 4 camera channels (main stream and sub stream)
print("=" * 70)
print("Testing RTSP Connections with Correct Credentials")
print("=" * 70)
print()

working_urls = []

# Test channels 1-4 (you have 4 cameras)
for channel in range(1, 5):
    for subtype in [0, 1]:  # 0 = Main Stream (high quality), 1 = Sub Stream (lower quality)
        stream_type = "Main Stream" if subtype == 0 else "Sub Stream"
        url = f"rtsp://{USERNAME}:{PASSWORD}@{DVR_IP}:{PORT}/cam/realmonitor?channel={channel}&subtype={subtype}"
        
        print(f"Testing Channel {channel} ({stream_type})...", end=' ')
        try:
            cap = cv2.VideoCapture(url)
            if cap.isOpened():
                ret, frame = cap.read()
                cap.release()
                if ret:
                    print("✓ WORKS!")
                    working_urls.append({
                        'channel': channel,
                        'stream_type': stream_type,
                        'url': url,
                        'url_safe': url.replace(PASSWORD, '****')
                    })
                else:
                    print("✗ (opened but no frame)")
            else:
                print("✗ (failed to open)")
        except Exception as e:
            print(f"✗ ({str(e)})")

print()
print("=" * 70)
print("RESULTS")
print("=" * 70)

if working_urls:
    print(f"\n✓ Found {len(working_urls)} working camera stream(s)!\n")
    
    for stream in working_urls:
        print(f"📹 Camera {stream['channel']} - {stream['stream_type']}")
        print(f"   URL: {stream['url_safe']}")
        print()
    
    print("=" * 70)
    print("READY TO ADD TO DASHBOARD")
    print("=" * 70)
    print()
    print("Use these RTSP URLs in your dashboard:")
    print()
    
    # Show main streams (high quality) for dashboard
    main_streams = [s for s in working_urls if s['stream_type'] == 'Main Stream']
    for idx, stream in enumerate(main_streams, 1):
        print(f"{idx}. Camera {stream['channel']} (Main Entrance/Location {stream['channel']})")
        print(f"   {stream['url']}")
        print()
    
    print("\n📋 Next Steps:")
    print("1. Open dashboard at http://localhost:3000")
    print("2. Go to Cameras page")
    print("3. Click 'Add Camera'")
    print("4. For each camera:")
    print("   - Name: Camera 1, Camera 2, etc.")
    print("   - Location: Main Gate, Building A, etc.")
    print("   - Protocol: RTSP")
    print("   - Stream URL: Copy from above")
    print("   - Username: admin")
    print("   - Password: Admin1234")
    
else:
    print("\n✗ No working streams found")
    print("\nPossible issues:")
    print("1. Cameras might not be connected to DVR")
    print("2. Check DVR to see which channels have cameras")
    print("3. Verify RTSP is enabled on DVR")
