# Performance Optimization Options

## Current Issue
- CPU usage hitting 100% with 4 cameras
- Frame rate automatically throttling from 5 FPS to 2 FPS
- Video delays due to performance bottleneck

## Quick Fixes (Choose One or More)

### Option 1: Reduce Default Frame Rate (Easiest)
Lower the base frame rate to reduce CPU load:

**In database, update cameras table:**
```sql
UPDATE cameras SET frame_rate = 2 WHERE id IN (3, 4, 5, 6);
```

**Pros:** Immediate relief, still functional
**Cons:** Lower frame rate for face recognition

---

### Option 2: Increase CPU Threshold (Temporary)
Allow higher CPU usage before throttling:

**In `video_streaming.py` line 500:**
```python
# Change from 80% to 95%
def __init__(self, cpu_threshold: float = 95.0, memory_threshold: float = 90.0):
```

**Pros:** Maintains 5 FPS longer
**Cons:** System may become unresponsive, not a real fix

---

### Option 3: Disable Face Recognition Processing (Testing)
Temporarily disable the CPU-intensive face recognition to test streaming only:

**In `video_streaming.py`, modify the pipeline to skip face detection**

**Pros:** Isolates if face recognition is the bottleneck
**Cons:** No attendance tracking while testing

---

### Option 4: Optimize Frame Processing (Recommended)
Reduce frame resolution before processing:

**Add to `video_streaming.py` in the frame processing pipeline:**
```python
# Resize frame to 640x480 before processing
frame = cv2.resize(frame, (640, 480))
```

**Pros:** Significant CPU reduction, maintains functionality
**Cons:** Slightly lower recognition accuracy

---

### Option 5: Process Fewer Cameras Simultaneously
Only process 2 cameras at a time for face recognition:

**Pros:** Reduces CPU load by 50%
**Cons:** Not all cameras monitored simultaneously

---

### Option 6: Reduce JPEG Quality (Quick Win)
Lower JPEG compression quality for MJPEG streams:

**In `.env` or config:**
```
MJPEG_QUALITY=50  # Default is 70
```

**Pros:** Less CPU for encoding, smaller bandwidth
**Cons:** Slightly lower video quality

---

### Option 7: Hardware Acceleration (Best Long-term)
Use GPU for video decoding/encoding:

**Install CUDA/GPU-enabled OpenCV**
**Requires:** NVIDIA GPU with CUDA support

**Pros:** Massive performance improvement
**Cons:** Requires compatible hardware and setup

---

## Recommended Immediate Actions

1. **Quick Fix:** Reduce frame rate to 3 FPS
2. **Medium Fix:** Resize frames to 640x480 before processing
3. **Long-term:** Consider GPU acceleration or more powerful CPU

## System Requirements for 4 Cameras @ 5 FPS
- **Minimum:** 4-core CPU @ 2.5GHz
- **Recommended:** 6-core CPU @ 3.0GHz or GPU acceleration
- **RAM:** 8GB minimum, 16GB recommended

## Which option would you like to implement?
