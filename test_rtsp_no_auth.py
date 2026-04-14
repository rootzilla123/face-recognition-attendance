"""
Test RTSP URLs without authentication
"""
import cv2

DVR_IP = "192.168.0.104"

# Common RTSP URLs without authentication
RTSP_URLS = [
    f"rtsp://{DVR_IP}:554/cam/realmonitor?channel=1&subtype=0",
    f"rtsp://{DVR_IP}:554/cam/realmonitor?channel=2&subtype=0",
    f"rtsp://{DVR_IP}:554/cam/realmonitor?channel=3&subtype=0",
    f"rtsp://{DVR_IP}:554/cam/realmonitor?channel=4&subtype=0",
    f"rtsp://{DVR_IP}:554/Streaming/Channels/101",
    f"rtsp://{DVR_IP}:554/Streaming/Channels/201",
    f"rtsp://{DVR_IP}:554/Streaming/Channels/301",
    f"rtsp://{DVR_IP}:554/Streaming/Channels/401",
    f"rtsp://{DVR_IP}:554/stream1",
    f"rtsp://{DVR_IP}:554/stream2",
    f"rtsp://{DVR_IP}:554/stream3",
    f"rtsp://{DVR_IP}:554/stream4",
]

print("=" * 70)
print("Testing RTSP URLs WITHOUT Authentication")
print("=" * 70)
print()

working_urls = []

for url in RTSP_URLS:
    print(f"Testing: {url}...", end=' ')
    try:
        cap = cv2.VideoCapture(url)
        if cap.isOpened():
            ret, frame = cap.read()
            cap.release()
            if ret:
                print("✓ WORKS!")
                working_urls.append(url)
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
    print(f"\n✓ Found {len(working_urls)} working stream(s)!\n")
    for idx, url in enumerate(working_urls, 1):
        print(f"{idx}. {url}")
    print("\n📋 Use these URLs in your dashboard (no username/password needed)")
else:
    print("\n✗ No working streams found")
    print("\nYou need to enable RTSP authentication on your DVR:")
    print("1. Go to DVR Menu → Network → RTSP")
    print("2. Enable RTSP Authentication")
    print("3. Save and reboot DVR")
