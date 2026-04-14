"""
DVR/NVR Network Scanner and RTSP URL Finder
Scans your local network to find DVR/NVR devices and test RTSP connections
"""

import socket
import subprocess
import re
import requests
from concurrent.futures import ThreadPoolExecutor, as_completed
import cv2

# Common DVR/NVR ports
DVR_PORTS = {
    80: "HTTP Web Interface",
    8000: "Hikvision Web Service",
    8080: "HTTP Alternative",
    554: "RTSP Streaming",
    37777: "Dahua TCP",
    9000: "Dahua Web Service",
    34567: "XMEye/DVR",
    85: "HTTP Alternative"
}

# Common RTSP URL patterns for different brands
RTSP_PATTERNS = {
    "Hikvision": [
        "rtsp://{username}:{password}@{ip}:554/Streaming/Channels/101",
        "rtsp://{username}:{password}@{ip}:554/Streaming/Channels/1",
        "rtsp://{username}:{password}@{ip}:554/h264/ch1/main/av_stream",
    ],
    "Dahua": [
        "rtsp://{username}:{password}@{ip}:554/cam/realmonitor?channel=1&subtype=0",
        "rtsp://{username}:{password}@{ip}:554/cam/realmonitor?channel=1&subtype=1",
    ],
    "Generic": [
        "rtsp://{username}:{password}@{ip}:554/stream1",
        "rtsp://{username}:{password}@{ip}:554/live",
        "rtsp://{username}:{password}@{ip}:554/",
    ]
}


def get_local_network():
    """Get the local network range (e.g., 192.168.0.0/24)"""
    try:
        # Get local IP
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        local_ip = s.getsockname()[0]
        s.close()
        
        # Extract network prefix (e.g., 192.168.0)
        network_prefix = '.'.join(local_ip.split('.')[:-1])
        
        print(f"✓ Your computer IP: {local_ip}")
        print(f"✓ Scanning network: {network_prefix}.0/24\n")
        
        return network_prefix, local_ip
    except Exception as e:
        print(f"✗ Error getting local network: {e}")
        return None, None


def scan_arp_table():
    """Scan ARP table to find active devices quickly"""
    print("📡 Scanning ARP table for active devices...")
    devices = []
    
    try:
        result = subprocess.run(['arp', '-a'], capture_output=True, text=True)
        lines = result.stdout.split('\n')
        
        for line in lines:
            # Match IP addresses in ARP table
            match = re.search(r'(\d+\.\d+\.\d+\.\d+)', line)
            if match:
                ip = match.group(1)
                if not ip.endswith('.255') and not ip.endswith('.0'):
                    devices.append(ip)
        
        print(f"✓ Found {len(devices)} devices in ARP table\n")
        return devices
    except Exception as e:
        print(f"✗ Error scanning ARP table: {e}\n")
        return []


def check_port(ip, port, timeout=1):
    """Check if a port is open on an IP address"""
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(timeout)
        result = sock.connect_ex((ip, port))
        sock.close()
        return result == 0
    except:
        return False


def check_http_service(ip, port=80):
    """Check if HTTP service is running and try to identify device"""
    try:
        response = requests.get(f"http://{ip}:{port}", timeout=2, allow_redirects=True)
        content = response.text.lower()
        
        # Try to identify device type
        if 'hikvision' in content or 'ivms' in content:
            return "Hikvision DVR/NVR"
        elif 'dahua' in content:
            return "Dahua DVR/NVR"
        elif 'dvr' in content or 'nvr' in content or 'camera' in content:
            return "DVR/NVR/Camera"
        elif 'login' in content or 'password' in content:
            return "Web Interface (Possible DVR)"
        else:
            return "HTTP Service"
    except:
        return None


def scan_device(ip):
    """Scan a single device for DVR/NVR characteristics"""
    open_ports = []
    device_info = {
        'ip': ip,
        'open_ports': [],
        'device_type': None,
        'is_dvr': False
    }
    
    # Check common DVR ports
    for port, description in DVR_PORTS.items():
        if check_port(ip, port, timeout=1):
            open_ports.append((port, description))
    
    if open_ports:
        device_info['open_ports'] = open_ports
        
        # Check HTTP service for device identification
        if any(port in [80, 8000, 8080, 9000] for port, _ in open_ports):
            for port in [80, 8000, 8080, 9000]:
                if any(p == port for p, _ in open_ports):
                    device_type = check_http_service(ip, port)
                    if device_type:
                        device_info['device_type'] = device_type
                        if 'DVR' in device_type or 'NVR' in device_type or 'Camera' in device_type:
                            device_info['is_dvr'] = True
                        break
        
        # If RTSP port is open, likely a camera/DVR
        if any(port == 554 for port, _ in open_ports):
            device_info['is_dvr'] = True
            if not device_info['device_type']:
                device_info['device_type'] = "RTSP Device (Camera/DVR)"
    
    return device_info if open_ports else None


def test_rtsp_url(rtsp_url, timeout=5):
    """Test if an RTSP URL is valid by trying to open it with OpenCV"""
    try:
        cap = cv2.VideoCapture(rtsp_url)
        if cap.isOpened():
            ret, frame = cap.read()
            cap.release()
            return ret  # True if we successfully read a frame
        return False
    except:
        return False


def find_rtsp_urls(ip, username, password):
    """Try common RTSP URL patterns to find working streams"""
    print(f"\n🔍 Testing RTSP URLs for {ip}...")
    working_urls = []
    
    all_patterns = []
    for brand, patterns in RTSP_PATTERNS.items():
        all_patterns.extend([(brand, pattern) for pattern in patterns])
    
    for brand, pattern in all_patterns:
        rtsp_url = pattern.format(username=username, password=password, ip=ip)
        print(f"   Testing {brand}: {rtsp_url.replace(password, '****')}...", end=' ')
        
        if test_rtsp_url(rtsp_url, timeout=5):
            print("✓ WORKS!")
            working_urls.append({
                'brand': brand,
                'url': rtsp_url,
                'channel': 1
            })
        else:
            print("✗")
    
    return working_urls


def main():
    print("=" * 70)
    print("DVR/NVR Network Scanner & RTSP URL Finder")
    print("=" * 70)
    print()
    
    # Get network info
    network_prefix, local_ip = get_local_network()
    if not network_prefix:
        return
    
    # Get credentials
    print("📝 Enter your DVR/Camera credentials:")
    username = input("Username (default: admin): ").strip() or "admin"
    password = input("Password: ").strip()
    
    if not password:
        print("✗ Password is required!")
        return
    
    print()
    
    # Scan ARP table first (faster)
    devices = scan_arp_table()
    
    if not devices:
        print("⚠ No devices found in ARP table. Scanning full network range...")
        devices = [f"{network_prefix}.{i}" for i in range(1, 255)]
    
    # Filter out local IP
    devices = [ip for ip in devices if ip != local_ip]
    
    print(f"🔍 Scanning {len(devices)} devices for DVR/NVR characteristics...")
    print("This may take a few minutes...\n")
    
    # Scan devices in parallel
    dvr_candidates = []
    with ThreadPoolExecutor(max_workers=20) as executor:
        future_to_ip = {executor.submit(scan_device, ip): ip for ip in devices}
        
        for future in as_completed(future_to_ip):
            result = future.result()
            if result:
                ip = result['ip']
                print(f"✓ {ip}: {len(result['open_ports'])} ports open", end='')
                if result['device_type']:
                    print(f" - {result['device_type']}")
                else:
                    print()
                
                if result['is_dvr']:
                    dvr_candidates.append(result)
    
    print("\n" + "=" * 70)
    print("SCAN RESULTS")
    print("=" * 70)
    
    if not dvr_candidates:
        print("✗ No DVR/NVR devices found on the network")
        print("\nTroubleshooting:")
        print("1. Make sure your DVR is powered on")
        print("2. Check that DVR is connected to the same network")
        print("3. Try accessing DVR web interface manually in browser")
        return
    
    print(f"\n✓ Found {len(dvr_candidates)} potential DVR/NVR device(s):\n")
    
    for idx, device in enumerate(dvr_candidates, 1):
        print(f"{idx}. IP Address: {device['ip']}")
        print(f"   Device Type: {device['device_type'] or 'Unknown'}")
        print(f"   Open Ports: {', '.join([f'{p} ({d})' for p, d in device['open_ports']])}")
        
        # Try to access web interface
        for port in [80, 8000, 8080, 9000]:
            if any(p == port for p, _ in device['open_ports']):
                print(f"   Web Interface: http://{device['ip']}:{port}")
                break
        print()
    
    # Test RTSP URLs for each candidate
    print("=" * 70)
    print("TESTING RTSP CONNECTIONS")
    print("=" * 70)
    
    all_working_urls = []
    for device in dvr_candidates:
        working_urls = find_rtsp_urls(device['ip'], username, password)
        if working_urls:
            all_working_urls.extend([{**url, 'ip': device['ip']} for url in working_urls])
    
    # Summary
    print("\n" + "=" * 70)
    print("SUMMARY")
    print("=" * 70)
    
    if all_working_urls:
        print(f"\n✓ Found {len(all_working_urls)} working RTSP stream(s)!\n")
        
        for idx, url_info in enumerate(all_working_urls, 1):
            print(f"{idx}. {url_info['brand']} - Channel {url_info['channel']}")
            print(f"   IP: {url_info['ip']}")
            print(f"   URL: {url_info['url']}")
            print()
        
        print("📋 Next Steps:")
        print("1. Copy the RTSP URLs above")
        print("2. Open the dashboard at http://localhost:3000")
        print("3. Go to Cameras page")
        print("4. Click 'Add Camera' and paste the RTSP URL")
        print("5. Repeat for each camera channel (change channel number in URL)")
        
    else:
        print("\n⚠ No working RTSP streams found")
        print("\nPossible reasons:")
        print("1. Incorrect username/password")
        print("2. RTSP is disabled on the DVR")
        print("3. DVR uses a different RTSP URL format")
        print("\nTry:")
        print("1. Access DVR web interface and check RTSP settings")
        print("2. Look for 'Network' or 'Streaming' settings")
        print("3. Check DVR manual for correct RTSP URL format")


if __name__ == "__main__":
    main()
