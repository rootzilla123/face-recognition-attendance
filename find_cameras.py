"""
Script to find CCTV cameras/DVR on the network.
Tests common RTSP ports and web interfaces.
"""

import socket
import requests
from requests.auth import HTTPBasicAuth

# Devices found on network
devices = [
    "192.168.0.100",
    "192.168.0.103",
    "192.168.0.104"
]

# Common ports for cameras/DVR
ports_to_check = {
    80: "HTTP Web Interface",
    8080: "HTTP Alt Port",
    554: "RTSP Stream",
    8000: "Hikvision Web",
    37777: "Dahua TCP",
    9000: "DVR Web Interface"
}

print("=" * 60)
print("SCANNING FOR CCTV CAMERAS/DVR ON YOUR NETWORK")
print("=" * 60)
print()

for device_ip in devices:
    print(f"\n🔍 Checking {device_ip}...")
    print("-" * 60)
    
    for port, description in ports_to_check.items():
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(2)
        
        try:
            result = sock.connect_ex((device_ip, port))
            if result == 0:
                print(f"  ✅ Port {port} OPEN - {description}")
                
                # Try to get web interface title
                if port in [80, 8080, 8000, 9000]:
                    try:
                        response = requests.get(
                            f"http://{device_ip}:{port}",
                            timeout=3,
                            verify=False
                        )
                        if "hikvision" in response.text.lower():
                            print(f"     🎯 HIKVISION DVR/Camera detected!")
                        elif "dahua" in response.text.lower():
                            print(f"     🎯 DAHUA DVR/Camera detected!")
                        elif "camera" in response.text.lower() or "dvr" in response.text.lower():
                            print(f"     🎯 Camera/DVR web interface detected!")
                    except:
                        pass
            else:
                print(f"  ❌ Port {port} closed - {description}")
        except:
            print(f"  ❌ Port {port} closed - {description}")
        finally:
            sock.close()

print("\n" + "=" * 60)
print("SCAN COMPLETE!")
print("=" * 60)
print("\n📝 NEXT STEPS:")
print("1. Open your browser and go to http://DEVICE_IP (try port 80 or 8080)")
print("2. Login with your camera/DVR credentials")
print("3. Look for 'Network Settings' or 'RTSP' to find the stream URL")
print("\nExample RTSP URLs to try:")
print("  Hikvision: rtsp://admin:password@DEVICE_IP:554/Streaming/Channels/101")
print("  Dahua: rtsp://admin:password@DEVICE_IP:554/cam/realmonitor?channel=1&subtype=0")
print("  Generic: rtsp://admin:password@DEVICE_IP:554/stream1")
