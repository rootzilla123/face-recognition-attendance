# Camera Setup Guide

This guide explains how to connect your CCTV cameras to the Face Recognition Attendance System.

## Supported Connection Types

The system supports three types of camera connections:

### 1. RTSP (Real-Time Streaming Protocol)
Most professional IP cameras support RTSP. This is the recommended protocol for CCTV cameras.

**URL Format:**
```
rtsp://[username:password@]host:port/path
```

**Examples:**
```
rtsp://192.168.1.100:554/stream1
rtsp://admin:password123@192.168.1.100:554/stream1
rtsp://camera.local:554/live/main
```

**Common RTSP Paths by Brand:**
- **Hikvision:** `rtsp://username:password@ip:554/Streaming/Channels/101`
- **Dahua:** `rtsp://username:password@ip:554/cam/realmonitor?channel=1&subtype=0`
- **Axis:** `rtsp://username:password@ip:554/axis-media/media.amp`
- **Foscam:** `rtsp://username:password@ip:554/videoMain`
- **Amcrest:** `rtsp://username:password@ip:554/cam/realmonitor?channel=1&subtype=0`

### 2. HTTP/HTTPS (MJPEG Streams)
Some cameras provide HTTP-based MJPEG streams.

**URL Format:**
```
http://[username:password@]host:port/path
```

**Examples:**
```
http://192.168.1.100:8080/video.mjpg
http://admin:password@192.168.1.100/mjpeg
https://camera.local/stream.mjpg
```

### 3. Local USB/Webcam
For testing or local cameras connected directly to the server.

**Device Index:**
- `0` - First camera (usually built-in webcam)
- `1` - Second camera (first USB camera)
- `2` - Third camera (second USB camera)
- etc.

## How to Add a Camera

### Via Web Interface

1. **Navigate to Cameras Page**
   - Open the dashboard at `http://localhost:3000`
   - Click on "Cameras" in the sidebar

2. **Click "Add Camera" Button**
   - Located in the top-right corner

3. **Fill in Camera Details**
   - **Camera Name:** Descriptive name (e.g., "Main Entrance Camera")
   - **Location:** Physical location (e.g., "Main Gate", "Building A")
   - **Protocol:** Select RTSP, HTTP, or Local
   - **Stream URL/Device Index:** 
     - For RTSP/HTTP: Enter the full URL
     - For Local: Enter device number (0, 1, 2, etc.)
   - **Username/Password:** (Optional) For cameras requiring authentication

4. **Click "Add Camera"**
   - The camera will be added to the system
   - It will appear in the camera grid

### Via API

You can also add cameras programmatically using the REST API:

```bash
curl -X POST http://localhost:8001/api/v1/cameras \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Main Entrance",
    "location": "Main Gate",
    "stream_url": "rtsp://admin:password@192.168.1.100:554/stream1",
    "protocol": "rtsp",
    "username": "admin",
    "password": "password",
    "is_active": true
  }'
```

## Finding Your Camera's RTSP URL

### Method 1: Check Camera Documentation
- Look in your camera's manual or manufacturer's website
- Search for "RTSP URL" or "Streaming URL"

### Method 2: Use Camera's Web Interface
1. Access your camera's web interface (usually `http://camera-ip`)
2. Log in with admin credentials
3. Navigate to Network or Streaming settings
4. Look for RTSP URL or Stream Path

### Method 3: Use ONVIF Device Manager
1. Download ONVIF Device Manager (free tool)
2. Scan your network for cameras
3. Select your camera
4. View the RTSP URL in the device information

### Method 4: Try Common Ports
Most IP cameras use these default ports:
- RTSP: `554`
- HTTP: `80` or `8080`
- HTTPS: `443`

## Troubleshooting

### Camera Shows "Offline"
1. **Check Network Connection**
   - Ping the camera IP: `ping 192.168.1.100`
   - Ensure camera is on the same network

2. **Verify RTSP URL**
   - Test URL in VLC Media Player: Media → Open Network Stream
   - If VLC can't connect, the URL is incorrect

3. **Check Credentials**
   - Verify username and password are correct
   - Some cameras require admin privileges for RTSP

4. **Firewall Issues**
   - Ensure port 554 (RTSP) or 8080 (HTTP) is not blocked
   - Check both server and camera firewalls

### Camera Shows "Error"
1. **Check Protocol**
   - Ensure you selected the correct protocol (RTSP/HTTP/Local)

2. **URL Format**
   - RTSP URLs must start with `rtsp://`
   - HTTP URLs must start with `http://` or `https://`

3. **Camera Compatibility**
   - Ensure camera supports H.264 or MJPEG encoding
   - Some proprietary formats may not work

### Poor Video Quality
1. **Adjust Camera Settings**
   - Increase bitrate in camera settings
   - Use main stream instead of sub-stream

2. **Network Bandwidth**
   - Ensure sufficient bandwidth for multiple cameras
   - Consider using sub-streams for preview

### High CPU Usage
1. **Reduce Frame Rate**
   - System automatically adjusts based on CPU usage
   - Manually reduce FPS in camera settings

2. **Use Sub-Streams**
   - Configure cameras to use lower resolution sub-streams
   - Main stream: 1080p, Sub-stream: 720p or 480p

## Testing Camera Connection

### Via Settings Page
1. Navigate to Settings page
2. Find your camera in the list
3. Click "Test Connection" button
4. Check the status message

### Via VLC Media Player
1. Open VLC
2. Media → Open Network Stream
3. Enter your RTSP URL
4. Click Play
5. If video appears, URL is correct

### Via Command Line (FFmpeg)
```bash
ffmpeg -i "rtsp://admin:password@192.168.1.100:554/stream1" -frames:v 1 test.jpg
```

## Security Best Practices

1. **Change Default Passwords**
   - Never use default camera passwords
   - Use strong, unique passwords

2. **Network Segmentation**
   - Place cameras on a separate VLAN
   - Restrict access to camera network

3. **Disable UPnP**
   - Disable UPnP on cameras to prevent external access
   - Use VPN for remote access

4. **Regular Updates**
   - Keep camera firmware up to date
   - Check manufacturer's website for security patches

5. **Secure Credentials**
   - Store credentials securely
   - Don't share camera URLs publicly

## Common Camera Brands & Default Credentials

⚠️ **Change these immediately after setup!**

| Brand | Default Username | Default Password |
|-------|-----------------|------------------|
| Hikvision | admin | 12345 |
| Dahua | admin | admin |
| Axis | root | pass |
| Foscam | admin | (blank) |
| Amcrest | admin | admin |
| TP-Link | admin | admin |

## Need Help?

If you're still having trouble connecting your cameras:

1. Check the camera manufacturer's documentation
2. Verify network connectivity
3. Test the URL in VLC Media Player
4. Check system logs for error messages
5. Ensure CompreFace service is running

## Example Configurations

### Hikvision DS-2CD2xxx
```
Protocol: RTSP
URL: rtsp://admin:password@192.168.1.100:554/Streaming/Channels/101
Username: admin
Password: your_password
```

### Dahua IPC-HDW
```
Protocol: RTSP
URL: rtsp://admin:password@192.168.1.101:554/cam/realmonitor?channel=1&subtype=0
Username: admin
Password: your_password
```

### USB Webcam (Testing)
```
Protocol: Local
Device Index: 0
```

### Generic MJPEG Camera
```
Protocol: HTTP
URL: http://192.168.1.102:8080/video.mjpg
Username: (if required)
Password: (if required)
```
