"""
Network scanner to find IP cameras on the local network.
Scans for devices with RTSP port 554 open and tests common camera URLs.
"""

import socket
import cv2
from concurrent.futures import ThreadPoolExecutor, as_completed
import ipaddress

def check_port(ip, port=554, timeout=1):
    """Check if a port is open on an IP address."""
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(timeout)
        result = sock.connect_ex((str(ip), port))
        sock.close()
        return result == 0
    except:
        return False

def test_rtsp_url(ip, credentials="admin:Admin1234", timeout=10):
    """Test common RTSP URL patterns for IP cameras."""
    # Common RTSP URL patterns for different camera brands
    url_patterns = [
        f"rtsp://{credentials}@{ip}:554/cam/realmonitor?channel=1&subtype=0",  # Dahua/Hikvision DVR
        f"rtsp://{credentials}@{ip}:554/cam/realmonitor?channel=2&subtype=0",
        f"rtsp://{credentials}@{ip}:554/cam/realmonitor?channel=3&subtype=0",
        f"rtsp://{credentials}@{ip}:554/cam/realmonitor?channel=4&subtype=0",
        f"rtsp://{credentials}@{ip}:554/Streaming/Channels/101",  # Hikvision
        f"rtsp://{credentials}@{ip}:554/h264Preview_01_main",  # Dahua
        f"rtsp://{credentials}@{ip}:554/live",  # Generic
        f"rtsp://{credentials}@{ip}:554/stream1",  # Generic
    ]
    
    working_urls = []
    
    for url in url_patterns:
        try:
            cap = cv2.VideoCapture(url)
            cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)
            
            if cap.isOpened():
                ret, frame = cap.read()
                if ret and frame is not None:
                    working_urls.append({
                        'url': url,
                        'resolution': frame.shape
                    })
                cap.release()
        except:
            pass
    
    return working_urls

def scan_network(subnet="192.168.0", start=1, end=254):
    """Scan network for IP cameras."""
    print(f"Scanning {subnet}.{start}-{end} for IP cameras...")
    print("="*70)
    
    found_cameras = []
    
    # First pass: Find devices with port 554 open
    print("\n[1/2] Scanning for devices with RTSP port 554 open...")
    devices_with_rtsp = []
    
    with ThreadPoolExecutor(max_workers=50) as executor:
        futures = {
            executor.submit(check_port, f"{subnet}.{i}"): i 
            for i in range(start, end + 1)
        }
        
        for future in as_completed(futures):
            ip_num = futures[future]
            ip = f"{subnet}.{ip_num}"
            try:
                if future.result():
                    devices_with_rtsp.append(ip)
                    print(f"  ✓ Found device with RTSP port open: {ip}")
            except:
                pass
    
    if not devices_with_rtsp:
        print("  ❌ No devices found with RTSP port 554 open")
        return []
    
    print(f"\n  Found {len(devices_with_rtsp)} device(s) with RTSP port open")
    
    # Second pass: Test RTSP URLs on devices with port 554 open
    print("\n[2/2] Testing RTSP URLs on found devices...")
    
    for ip in devices_with_rtsp:
        print(f"\n  Testing {ip}...")
        working_urls = test_rtsp_url(ip)
        
        if working_urls:
            print(f"    ✅ Found {len(working_urls)} working camera stream(s)!")
            for cam in working_urls:
                print(f"       URL: {cam['url']}")
                print(f"       Resolution: {cam['resolution']}")
                found_cameras.append({
                    'ip': ip,
                    'url': cam['url'],
                    'resolution': cam['resolution']
                })
        else:
            print(f"    ❌ No working RTSP streams found")
    
    return found_cameras

if __name__ == "__main__":
    print("="*70)
    print("IP Camera Network Scanner")
    print("="*70)
    
    # Scan the network
    cameras = scan_network()
    
    # Print summary
    print("\n" + "="*70)
    print("SCAN COMPLETE")
    print("="*70)
    
    if cameras:
        print(f"\n✅ Found {len(cameras)} working camera stream(s):\n")
        for i, cam in enumerate(cameras, 1):
            print(f"{i}. IP: {cam['ip']}")
            print(f"   URL: {cam['url']}")
            print(f"   Resolution: {cam['resolution']}")
            print()
    else:
        print("\n❌ No IP cameras found on the network")
        print("\nTroubleshooting:")
        print("  1. Make sure cameras are powered on")
        print("  2. Check that cameras are connected to the same network")
        print("  3. Verify camera credentials (default: admin:Admin1234)")
        print("  4. Check if cameras use a different RTSP port")
