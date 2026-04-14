# MJPEG Video Streaming - Quick Start Guide

## What Was Implemented

The MJPEG video streaming feature has been successfully implemented to replace WebSocket-based video streaming. This eliminates browser freezing, constant disconnections, and blinking online/offline status issues.

## How It Works

### Before (WebSocket)
```
Camera → VideoStreamManager → FrameProcessor → WebSocket → Browser
                                                    ↓
                                            (Large base64 frames)
                                                    ↓
                                            Browser freezes 😞
```

### After (MJPEG)
```
Camera → VideoStreamManager → FrameProcessor → MJPEG HTTP Stream → Browser <img> tag
                                                                            ↓
                                                                    Smooth video! 😊

WebSocket (separate) → Only events (attendance, status) → Browser
```

## Testing the Implementation

### Step 1: Start the Backend

```bash
cd attendance-system
python -m uvicorn app.main:app --host 0.0.0.0 --port 8001 --reload
```

Wait for the startup messages:
- ✓ Redis connection established
- ✓ WebSocket manager initialized
- ✓ Video streaming service started
- ✓ MJPEG streaming service initialized
- ✓ System startup complete!

### Step 2: Run the Test Script

In a new terminal:

```bash
cd attendance-system
python test_mjpeg_endpoint.py
```

Expected output:
```
Test 1: Checking health endpoint...
✓ Health check: 200 - {...}

Test 2: Getting camera list...
✓ Found X cameras

Test 3: Testing MJPEG stream endpoint...
✓ MJPEG stream endpoint is working correctly!
  Successfully received 3 chunks

Test 4: Testing error handling...
✓ Correctly returns 404 for non-existent camera
```

### Step 3: Start the Frontend

```bash
cd attendance-dashboard
npm run dev
```

### Step 4: Open the Cameras Page

1. Open browser: http://localhost:3000/cameras
2. You should see:
   - Camera feeds displaying via MJPEG streams
   - No browser freezing
   - Smooth video playback
   - WebSocket status indicator (green = connected)

### Step 5: Verify WebSocket Separation

Open browser console (F12) and check:
- ✓ WebSocket messages show only `attendance_event` and `camera_status`
- ✗ No `frame_update` messages (these are gone!)

## API Endpoints

### MJPEG Stream Endpoint

```
GET /api/v1/cameras/{camera_id}/stream
```

**Response:**
- Content-Type: `multipart/x-mixed-replace; boundary=frame`
- Body: Continuous stream of JPEG frames

**Error Codes:**
- 404: Camera not found
- 400: Camera not active
- 503: Camera offline

**Example Usage:**

```html
<!-- In browser -->
<img src="http://192.168.0.111:8001/api/v1/cameras/1/stream" />
```

```bash
# In terminal (test with curl)
curl -N http://192.168.0.111:8001/api/v1/cameras/1/stream
```

### WebSocket Endpoint (Unchanged)

```
WS /ws/attendance
```

**Messages:**
- `attendance_event`: Student recognized
- `camera_status`: Camera online/offline/error
- ~~`frame_update`~~: REMOVED (now handled by MJPEG)

## Troubleshooting

### Issue: "MJPEG service not initialized"

**Solution:** Make sure the backend started successfully. Check logs for errors during startup.

### Issue: Camera shows "Loading stream..." forever

**Possible causes:**
1. Camera is offline - Check camera status in database
2. Camera stream URL is incorrect - Verify RTSP/HTTP URL
3. Network issue - Verify camera is reachable from backend server

**Debug:**
```bash
# Check camera status
curl http://192.168.0.111:8001/api/v1/cameras

# Test stream endpoint directly
curl -N http://192.168.0.111:8001/api/v1/cameras/1/stream
```

### Issue: "Failed to load camera stream" error

**Possible causes:**
1. Camera went offline during streaming
2. Network connection lost
3. Backend service crashed

**Debug:**
- Check backend logs for errors
- Verify camera is still online
- Restart backend service if needed

### Issue: Browser console shows CORS errors

**Solution:** CORS is already configured in main.py. If you still see errors:
1. Verify backend is running on correct host/port
2. Check `apiBaseUrl` in MJPEGCameraFeed component
3. Restart backend after any CORS changes

## Performance Monitoring

### Expected Performance (4 cameras @ 5 FPS)
- CPU usage: < 60%
- Memory usage: < 1.5 GB
- Frame latency: < 500ms

### Monitor Resources

```bash
# On Windows
taskmgr

# On Linux
htop
```

### Adjust Frame Rate

Frame rate is controlled per camera in the database:

```sql
UPDATE cameras SET frame_rate = 3 WHERE id = 1;
```

Lower frame rate = less bandwidth and CPU usage.

### Adjust JPEG Quality

JPEG quality is set in `main.py` during MJPEG service initialization:

```python
mjpeg_service = MJPEGStreamService(
    video_stream_manager=video_streaming_service.video_stream_manager,
    frame_processor=video_streaming_service.frame_processor,
    db=db,
    jpeg_quality=70  # Change this (1-100)
)
```

Lower quality = smaller file size, less bandwidth.

## Architecture Overview

### Backend Components

1. **MJPEGStreamService** (`app/services/mjpeg_streaming.py`)
   - Generates MJPEG streams
   - Manages client connections
   - Handles errors gracefully

2. **MJPEG Router** (`app/routes/mjpeg_stream.py`)
   - Exposes `/api/v1/cameras/{id}/stream` endpoint
   - Returns StreamingResponse
   - Handles HTTP errors

3. **VideoStreamingService** (modified)
   - No longer broadcasts frames via WebSocket
   - Still handles face recognition
   - Still broadcasts attendance events

### Frontend Components

1. **MJPEGCameraFeed** (`app/components/MJPEGCameraFeed.tsx`)
   - Displays MJPEG stream via `<img>` tag
   - Handles loading and error states
   - Shows camera status

2. **Cameras Page** (modified)
   - Uses MJPEGCameraFeed instead of CameraFeed
   - WebSocket only for events (no frames)
   - Cleaner, simpler code

## Benefits

### Before (WebSocket-based)
- ❌ Browser freezing
- ❌ Constant disconnections
- ❌ Blinking online/offline status
- ❌ High memory usage
- ❌ Complex client-side code

### After (MJPEG-based)
- ✅ Smooth video playback
- ✅ Stable connections
- ✅ Native browser support
- ✅ Lower memory usage
- ✅ Simple client-side code
- ✅ Better scalability

## Next Steps

1. **Add More Cameras**: Test with 4 cameras simultaneously
2. **Monitor Performance**: Check CPU and memory usage
3. **Test Error Scenarios**: Disconnect cameras, test reconnection
4. **Optimize Settings**: Adjust frame rate and JPEG quality as needed
5. **Production Deployment**: Deploy to production environment

## Support

If you encounter issues:
1. Check backend logs for errors
2. Check browser console for errors
3. Run the test script to verify endpoints
4. Verify camera configuration in database
5. Check network connectivity

## Summary

The MJPEG video streaming implementation is complete and ready for testing. The system now uses efficient HTTP multipart streaming for video delivery while maintaining WebSocket connections for real-time events only. This architecture eliminates the browser freezing and connection issues that plagued the previous WebSocket-based implementation.

Happy streaming! 🎥
