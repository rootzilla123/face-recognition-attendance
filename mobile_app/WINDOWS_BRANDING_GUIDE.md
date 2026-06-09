# Windows Desktop App Branding Guide

## ✅ What's Already Configured

Your Windows desktop app now has professional branding:

- **App Name**: AttendanceAI
- **Executable Name**: `AttendanceAI.exe` (instead of mobile_app.exe)
- **Window Title**: "AttendanceAI - Smart Face Recognition"
- **Company Name**: Shadrack Attendance Systems
- **Product Description**: AttendanceAI - Smart Face Recognition Attendance System
- **Copyright**: Copyright (C) 2026 Shadrack Attendance Systems

## 🎨 Custom App Icon Setup

### Current Icon Location
`mobile_app/windows/runner/resources/app_icon.ico`

### How to Create a Custom Icon

#### Option 1: Online Icon Converter (Easiest)
1. Create or find your logo/icon (PNG, JPG, or SVG)
2. Go to: https://convertio.co/png-ico/ or https://icoconvert.com/
3. Upload your image
4. Select these sizes: **16x16, 32x32, 48x48, 64x64, 128x128, 256x256**
5. Download the `.ico` file
6. Replace `mobile_app/windows/runner/resources/app_icon.ico` with your new icon

#### Option 2: Using GIMP (Free Software)
1. Install GIMP: https://www.gimp.org/downloads/
2. Open your logo in GIMP
3. Scale to 256x256: Image → Scale Image
4. Export as ICO: File → Export As → Select `.ico` format
5. Replace the icon file

#### Option 3: Using ImageMagick (Command Line)
```bash
# Install ImageMagick first
# Then convert your image:
convert your_logo.png -define icon:auto-resize=256,128,64,48,32,16 app_icon.ico
```

### Icon Design Tips
- Use a **square image** (1:1 aspect ratio)
- Minimum size: **256x256 pixels**
- Keep it **simple and recognizable** at small sizes
- Use **high contrast** colors
- Avoid fine details that won't show at 16x16
- Test at multiple sizes

### Recommended Icon Sizes
The `.ico` file should contain multiple resolutions:
- 16x16 - Taskbar, title bar
- 32x32 - Desktop shortcuts
- 48x48 - Large icons view
- 64x64 - Extra large icons
- 128x128 - High DPI displays
- 256x256 - Ultra high DPI

## 🔧 After Changing the Icon

1. **Clean previous builds**:
   ```bash
   cd mobile_app
   flutter clean
   ```

2. **Rebuild the app**:
   ```bash
   ./build_windows.sh
   ```

3. **Test the icon**:
   - Check the `.exe` file icon in File Explorer
   - Check the taskbar icon when running
   - Check the window title bar icon

## 📝 Customizing Further

### Change App Name
Edit `mobile_app/windows/CMakeLists.txt`:
```cmake
set(BINARY_NAME "YourAppName")
```

### Change Window Title
Edit `mobile_app/windows/runner/main.cpp`:
```cpp
if (!window.Create(L"Your Window Title", origin, size)) {
```

### Change Company/Copyright Info
Edit `mobile_app/windows/runner/Runner.rc`:
```rc
VALUE "CompanyName", "Your Company Name" "\0"
VALUE "FileDescription", "Your App Description" "\0"
VALUE "LegalCopyright", "Copyright (C) 2026 Your Company. All rights reserved." "\0"
VALUE "ProductName", "Your Product Name" "\0"
```

### Change App Version
Edit `mobile_app/pubspec.yaml`:
```yaml
version: 1.0.0+1
```
The version automatically syncs to Windows metadata.

## 🚀 Building Your Branded App

```bash
cd mobile_app
./build_windows.sh
```

Your branded app will be at:
`build/windows/x64/runner/Release/AttendanceAI.exe`

## 📦 Distribution

### Create a Portable ZIP
```bash
cd build/windows/x64/runner/Release
zip -r AttendanceAI-Windows-v1.0.0.zip *
```

### What to Include
The Release folder contains everything needed:
- `AttendanceAI.exe` - Your branded executable
- `flutter_windows.dll` - Flutter runtime
- `data/` - App assets and resources
- Other DLL dependencies

Users can extract and run `AttendanceAI.exe` directly!

## 🎯 Quick Icon Replacement

If you already have an icon file:
```bash
# Backup the old icon
cp mobile_app/windows/runner/resources/app_icon.ico mobile_app/windows/runner/resources/app_icon.ico.backup

# Copy your new icon
cp /path/to/your/icon.ico mobile_app/windows/runner/resources/app_icon.ico

# Rebuild
cd mobile_app
flutter clean
./build_windows.sh
```

## ✨ Professional Touch

Consider adding:
- **Splash screen** - Show your logo while loading
- **About dialog** - Display version and company info
- **Custom theme** - Match your brand colors
- **Installer** - Create a professional installer with Inno Setup

Need help with any of these? Just ask!
