# Webcam Setup Guide

This guide explains how to add and use webcams (built-in or USB) as camera sources in the attendance system.

## Quick Start

1. **Open the Dashboard**
   - Navigate to the Cameras page
   - Click "Add Camera" button

2. **Select Local Protocol**
   - Choose the "Local" option (💻 icon)
   - This protocol is for webcams connected directly to the server

3. **Enter Device Index**
   - **0** = First webcam (usually built-in laptop camera)
   - **1** = Second webcam (usually first USB camera)
   - **2** = Third webcam (second USB camera)
   - And so on...

4. **Fill in Details**
   - **Camera Name**: e.g., "Laptop Webcam" or "USB Camera 1"
   - **Location**: e.g., "Reception Desk" or "Front Office"
   - **Device Index**: Enter the number (0, 1, 2, etc.)

5. **Save and Test**
   - Click "Add Camera"
   - The webcam feed should appear in the camera grid
   - If you see a black screen or error, try a different device index

## Finding Your Webcam Device Index

### Windows
```bash
# List all video devices
ffmpeg -list_devices true -f dshow -i dummy
```

### Linux
```bash
# List all video devices
ls -l /dev/video*
# Usually /dev/video0 is index 0, /dev/video1 is index 1, etc.
```

### macOS
```bash
# List all video devices
system_profiler SPCameraDataType
```

## Common Device Indices

| Device Index | Typical Device |
|--------------|----------------|
| 0 | Built-in laptop webcam |
| 1 | First USB webcam |
| 2 | Second USB webcam |
| 3 | Third USB webcam |

## Troubleshooting

### Camera Not Showing Video

1. **Check if webcam is in use**
   - Close other applications using the webcam (Zoom, Teams, Skype, etc.)
   - Only one application can access a webcam at a time

2. **Try different device indices**
   - Start with 0, then try 1, 2, 3, etc.
   - Some systems skip indices

3. **Check permissions**
   - Ensure the backend server has permission to access the webcam
   - On Windows: Check Privacy Settings → Camera
   - On Linux: User must be in `video` group
   - On macOS: Grant camera access in System Preferences

4. **Verify webcam is connected**
   - Check Device Manager (Windows) or system settings
   - Unplug and replug USB webcams

### Camera Shows "Offline" Status

- The webcam might be disconnected
- Try restarting the backend server
- Check backend logs for error messages

### Low Frame Rate or Lag

- Reduce frame rate in Settings page (try 2-3 FPS)
- Close other applications using system resources
- Use lower resolution webcams if possible

## Example Configurations

### Built-in Laptop Webcam
```
Name: Laptop Camera
Location: Reception Desk
Protocol: Local
Device Index: 0
```

### USB Webcam
```
Name: USB Camera - Main Entrance
Location: Main Entrance
Protocol: Local
Device Index: 1
```

### Multiple Webcams
```
Camera 1:
  Name: Built-in Webcam
  Location: Front Desk
  Device Index: 0

Camera 2:
  Name: USB Camera 1
  Location: Back Office
  Device Index: 1

Camera 3:
  Name: USB Camera 2
  Location: Meeting Room
  Device Index: 2
```

## Performance Tips

1. **Limit concurrent webcams**
   - Each webcam uses CPU and memory
   - Recommended: Max 2-3 webcams on a standard laptop

2. **Adjust frame rate**
   - Lower frame rates (2-3 FPS) reduce CPU usage
   - Face recognition still works well at low frame rates

3. **Use good lighting**
   - Webcams need good lighting for face detection
   - Avoid backlighting (windows behind people)

4. **Position webcams properly**
   - Face-level height (not looking up or down)
   - 3-6 feet distance from subjects
   - Avoid extreme angles

## Integration with Face Recognition

Once a webcam is added:

1. **Face Detection**: Automatically detects faces in the webcam feed
2. **Face Recognition**: Matches detected faces against registered students
3. **Attendance Marking**: Automatically marks attendance when a student is recognized
4. **Visual Overlay**: Shows green bounding boxes around recognized faces
5. **Notifications**: Displays real-time attendance notifications

## Notes

- Webcams must be connected to the machine running the backend server
- The backend server must have permission to access the webcam
- Only one application can use a webcam at a time
- Webcam quality affects face recognition accuracy
- Recommended: 720p or higher resolution webcams

## Support

If you encounter issues:
1. Check backend server logs for error messages
2. Verify webcam works in other applications (e.g., Camera app)
3. Try different device indices
4. Restart the backend server
5. Check system permissions for camera access
