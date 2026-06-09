# Windows Branding - Quick Start

## ✅ Already Done

Your Windows app is now branded as:
- **App Name**: AttendanceAI.exe
- **Window Title**: AttendanceAI - Smart Face Recognition
- **Company**: Shadrack Attendance Systems

## 🎨 Add Your Custom Icon (3 Steps)

### Step 1: Get Your Icon Ready
- Square image (PNG or JPG)
- At least 256x256 pixels
- Simple design

### Step 2: Update the Icon
```bash
cd mobile_app
./update_windows_icon.sh /path/to/your/icon.png
```

### Step 3: Build
```bash
flutter clean
./build_windows.sh
```

Done! Your branded app is at: `build/windows/x64/runner/Release/AttendanceAI.exe`

## 🌐 Convert Icon Online (If Needed)

If you need to convert your image to .ico format:
1. Go to: https://convertio.co/png-ico/
2. Upload your image
3. Select sizes: 16, 32, 48, 64, 128, 256
4. Download and use: `./update_windows_icon.sh downloaded.ico`

## 📝 Change Branding

| What | Where | Line |
|------|-------|------|
| App Name | `windows/CMakeLists.txt` | Line 7 |
| Window Title | `windows/runner/main.cpp` | Line 29 |
| Company Name | `windows/runner/Runner.rc` | Line 95 |
| Description | `windows/runner/Runner.rc` | Line 96 |
| Version | `pubspec.yaml` | Line 21 |

## 🚀 Build & Distribute

```bash
# Build
./build_windows.sh

# Create portable ZIP
cd build/windows/x64/runner/Release
zip -r AttendanceAI-Windows-v1.0.0.zip *
```

Share the ZIP file - users extract and run `AttendanceAI.exe`!

## 📚 Full Guide

See `WINDOWS_BRANDING_GUIDE.md` for detailed instructions.
