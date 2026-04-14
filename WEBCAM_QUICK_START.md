# Webcam Quick Start Guide

## ✅ Webcam Support is Already Built-In!

Your attendance system already supports webcams! You can use:
- 💻 Built-in laptop cameras
- 🔌 USB webcams
- 📹 Any local video device

## 🚀 Quick Setup (3 Steps)

### Step 1: Find Your Webcam Device Index

Run the webcam finder script:

```bash
cd attendance-system
python test_webcam.py
```

This will show you all available webcams and their device indices.

**Example Output:**
```
✅ Found 2 webcam(s):
   • Device Index: 0  (Built-in camera)
   • Device Index: 1  (USB webcam)
```

### Step 2: Add Webcam in Dashboard

1. Open the dashboard: `http://localhost:3000/cameras`
2. Click **"Add Camera"** button
3. Select **"Local"** protocol (💻 icon)
4. Fill in the details:
   - **Camera Name**: "My Webcam"
   - **Location**: "Front Desk"
   - **Device Index**: Enter the number from Step 1 (usually `0`)
5. Click **"Add Camera"**

### Step 3: Test the Feed

- The webcam feed should appear immediately
- Face detection will start automatically
- Register a student with photo to test face recognition

## 📋 Common Device Indices

| Index | Typical Device |
|-------|----------------|
| `0` | Built-in laptop camera |
| `1` | First USB webcam |
| `2` | Second USB webcam |
| `3` | Third USB webcam |

## 🧪 Test a Specific Webcam

To test a specific device with live preview:

```bash
python test_webcam.py 0
```

This opens a preview window. Press `q` or `ESC` to close.

## ⚠️ Troubleshooting

### "No camera found at index X"

**Solution:**
- Try different indices: 0, 1, 2, 3...
- Close other apps using the webcam (Zoom, Teams, Skype)
- Unplug and replug USB webcams
- Restart the backend server

### "Camera shows black screen"

**Solution:**
- Check if another app is using the webcam
- Verify webcam works in other apps (Camera app, browser)
- Try a different device index
- Check camera permissions:
  - **Windows**: Settings → Privacy → Camera
  - **Linux**: Add user to `video` group
  - **macOS**: System Preferences → Security & Privacy → Camera

### "Camera is offline"

**Solution:**
- Webcam might be disconnected
- Restart the backend server
- Check backend logs for errors

## 💡 Pro Tips

### Multiple Webcams
You can add multiple webcams simultaneously:
```
Device 0: Built-in camera → Reception
Device 1: USB camera 1 → Main Entrance  
Device 2: USB camera 2 → Back Office
```

### Performance Optimization
- **Lower frame rate** for better performance (2-3 FPS is enough)
- **Close unused apps** to free up resources
- **Good lighting** improves face detection accuracy

### Best Positioning
- **Height**: Face level (not looking up/down)
- **Distance**: 3-6 feet from subjects
- **Lighting**: Front lighting (avoid backlighting)
- **Angle**: Straight on (avoid extreme angles)

## 🎯 Complete Example

```bash
# 1. Find webcams
cd attendance-system
python test_webcam.py

# Output: Found device at index 0

# 2. Add in dashboard
# - Go to http://localhost:3000/cameras
# - Click "Add Camera"
# - Select "Local" protocol
# - Enter device index: 0
# - Name: "Laptop Webcam"
# - Location: "Reception Desk"
# - Click "Add Camera"

# 3. Done! Webcam feed appears immediately
```

## 📊 System Requirements

- **Backend**: Must run on the same machine as the webcam
- **Permissions**: Backend needs camera access
- **Resources**: Each webcam uses ~10-20% CPU
- **Recommended**: Max 2-3 webcams on standard laptop

## 🔗 Related Guides

- Full setup guide: `WEBCAM_SETUP_GUIDE.md`
- Camera setup: `CAMERA_SETUP_GUIDE.md`
- Main README: `README.md`

## ❓ Need Help?

1. Run the test script: `python test_webcam.py`
2. Check backend logs for errors
3. Verify webcam works in other apps
4. Try different device indices
5. Check system permissions

---

**That's it!** Webcam support is already built-in and ready to use. Just find your device index and add it through the dashboard. 🎉
