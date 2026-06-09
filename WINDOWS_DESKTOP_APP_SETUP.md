# Windows Desktop App Development - Complete Setup Guide

## 🎯 Your Mission

You want to create a **Windows desktop version** of the mobile app using the same codebase and test it on a Windows computer.

**Good news**: Flutter supports this perfectly! The `mobile_app` folder already has Windows support configured.

---

## 🏗️ Architecture

Your Flutter project is a **multi-platform app**:

```
mobile_app/
├── lib/                          # SHARED code (all platforms use this!)
│   ├── main.dart                 # Entry point
│   ├── app.dart                  # App configuration
│   ├── screens/                  # UI screens (student, parent, admin)
│   ├── widgets/                  # Reusable components
│   ├── providers/                # State management
│   └── core/                     # Business logic
│
├── android/                      # Android-specific config
├── ios/                          # iOS-specific config
├── macos/                        # macOS-specific config
├── linux/                        # Linux-specific config
├── windows/                      # WINDOWS-specific config ← You are here
├── web/                          # Web-specific config
└── pubspec.yaml                  # Dependencies (shared)
```

**Key Point**: The same `lib/` folder code runs on all platforms! You just need to set up Windows.

---

## 📋 Prerequisites for Windows Development

### Option A: Develop on Linux/Mac, Test on Windows Computer

**On your development machine (Linux/Mac):**
1. ✅ Flutter SDK installed
2. ✅ Dart installed
3. ✅ Git installed
4. ✅ Code editor (VSCode, Android Studio, etc.)

**On Windows computer (test machine):**
1. Windows 10 or 11 (64-bit)
2. Visual Studio 2022 Community (free)
3. Flutter SDK
4. Git

### Option B: Develop Directly on Windows Computer

**On Windows 10/11:**
1. Visual Studio 2022 Community Edition
2. Flutter SDK for Windows
3. Git
4. VSCode or Android Studio

---

## 🚀 Phase 1: Setup Development Machine (Linux/Mac)

### Step 1: Check Flutter Installation

```bash
# In your Linux/Mac terminal
flutter --version
flutter doctor

# Expected output:
# Flutter 3.27.3 • channel stable
# [✓] Flutter (Channel stable, 3.27.3)
# [✓] Android toolchain
# etc.
```

### Step 2: Enable Windows Desktop Support

```bash
flutter config --list
# Shows current configuration

# If windows not enabled:
flutter config --enable-windows-desktop

# Verify
flutter config --list | grep windows
```

### Step 3: Build and Test Locally (Optional)

You can test the Linux version to verify the code compiles:

```bash
cd mobile_app
flutter clean
flutter pub get
flutter build linux --release

# Or run in debug mode for testing
flutter run -d linux
```

---

## 🖥️ Phase 2: Setup Windows Test Machine

### Step 1: Install Visual Studio 2022 Community (FREE)

1. **Download**
   - Go to: https://visualstudio.microsoft.com/vs/community/
   - Click "Download Visual Studio 2022 Community"

2. **Install**
   - Run the installer
   - Select "Desktop development with C++" workload
   - Click "Install"
   - This takes 10-15 minutes

3. **Verify**
   ```cmd
   # In Windows Command Prompt or PowerShell
   cl.exe
   # Should show: Microsoft (R) C/C++ Optimizing Compiler
   ```

### Step 2: Install Flutter SDK on Windows

1. **Download Flutter**
   - Go to: https://docs.flutter.dev/get-started/install/windows
   - Click "Download Flutter SDK"
   - Save to `C:\src\flutter`

2. **Extract**
   ```cmd
   # In PowerShell
   cd C:\src
   Expand-Archive flutter_windows_3.24.0-stable.zip
   ```

3. **Add to PATH**
   - Open "Edit environment variables for your account"
   - Add new variable: `C:\src\flutter\bin`
   - Restart PowerShell
   - Verify:
   ```cmd
   flutter --version
   ```

### Step 3: Run Flutter Doctor

```cmd
flutter doctor

# Expected output:
# ✓ Flutter (Channel stable, 3.24.0)
# ✓ Windows Version (Professional, 10.0.19045)
# ✓ Visual Studio (full)
# ✓ Windows PowerShell
```

If you see errors, they'll tell you what to fix.

---

## 💾 Phase 3: Transfer Project to Windows

### Option A: Using Git

**On your development machine:**
```bash
cd face-recognition-attendance
git add .
git commit -m "Prepare for Windows desktop build"
git push
```

**On Windows machine:**
```cmd
cd C:\Projects
git clone https://github.com/YOUR_REPO/face-recognition-attendance.git
cd face-recognition-attendance\mobile_app
```

### Option B: Transfer Folder Directly

1. **Compress on Linux/Mac:**
```bash
cd face-recognition-attendance
tar -czf mobile_app.tar.gz mobile_app/
# Compress as ZIP if needed
```

2. **Transfer** (USB drive, email, cloud)

3. **Extract on Windows:**
```cmd
# In Windows File Explorer
# Right-click → Extract All
# Or: tar -xzf mobile_app.tar.gz
```

---

## 🔧 Phase 4: Build Windows App

### On Windows Machine:

```cmd
# Navigate to project
cd C:\Projects\face-recognition-attendance\mobile_app

# Step 1: Clean
flutter clean

# Step 2: Get dependencies
flutter pub get

# Step 3: Build Windows Release
flutter build windows --release

# This will take 3-5 minutes first time
# Output will show build progress
```

### Successful Build Output:

```
Building Windows application...
✓ Built build\windows\x64\runner\Release\AttendanceAI.exe
✓ Size: 145 MB
```

### Build Output Location:

```
C:\Projects\face-recognition-attendance\mobile_app\build\windows\x64\runner\Release\
├── AttendanceAI.exe              ← THE APP (run this!)
├── flutter_windows.dll           ← Runtime library
├── data/                         ← App assets
│   ├── icudtl.dat
│   └── flutter_assets/
└── *.dll                         ← Other dependencies
```

---

## ▶️ Phase 5: Run the Windows App

### Method 1: Run Directly from File Explorer

1. Navigate to: `build\windows\x64\runner\Release\`
2. Double-click `AttendanceAI.exe`
3. App launches!

### Method 2: Run from Command Line

```cmd
cd build\windows\x64\runner\Release
.\AttendanceAI.exe
```

### Method 3: Run Debug Build (Development)

```cmd
# In mobile_app folder
flutter run -d windows

# This opens the app in debug mode
# You can see debug output in terminal
# Hot reload supported (Ctrl+R)
```

---

## 📱 Testing the App on Windows

### What to Test

1. **Launch**
   - App starts without errors
   - Window appears (1280x720 typical)
   - UI displays correctly

2. **Appearance**
   - Compare with mobile version
   - Check responsiveness to window resize
   - Dark mode working (if enabled)

3. **Core Functionality**
   - Navigation works
   - Buttons respond to clicks
   - Text input works
   - Animations smooth

4. **API Connectivity**
   - Ensure backend API is running: `http://localhost:8001`
   - Check backend is accessible from Windows machine
   - Network requests working (check logs)

5. **Performance**
   - No lag when scrolling
   - Buttons respond quickly
   - Animation smooth (60fps)

### Debugging Output

When running `flutter run -d windows`, you see real-time logs:

```
I/flutter (14520): [User Logged In] ID: 12345
D/flutter (14520): HTTP GET /api/v1/attendance
I/flutter (14520): [API Response] 200 OK
```

---

## 🎯 Testing Checklist

- [ ] App launches without errors
- [ ] Window size appropriate (1280x720 minimum)
- [ ] All buttons clickable
- [ ] Text input fields work
- [ ] Navigation smooth
- [ ] Network API connectivity working
- [ ] No console errors
- [ ] Animations smooth
- [ ] Scaling with window resize works
- [ ] Dark mode displays correctly

---

## 🔧 Troubleshooting

### "Flutter command not found"

```cmd
# Check Flutter is in PATH
echo %PATH%

# If not, add it:
# 1. Edit Environment Variables
# 2. Add: C:\src\flutter\bin
# 3. Restart PowerShell
```

### "Visual Studio not found"

```cmd
flutter doctor -v

# Install Visual Studio Community if missing
# Make sure "Desktop development with C++" workload is selected
```

### "Build fails with cryptic error"

```cmd
flutter clean
flutter pub get
flutter build windows --release --verbose

# --verbose shows detailed error messages
```

### "App crashes immediately"

```cmd
# Run in debug mode to see logs
flutter run -d windows

# Check logs for specific errors
# Usually backend connection issues
```

### "API requests fail"

1. Check backend is running on your dev machine
2. Verify Windows machine can reach backend URL:
   ```cmd
   # On Windows, test connectivity
   curl http://YOUR_DEV_MACHINE_IP:8001/api/v1/health
   ```
3. Update API URL in app if needed

### "Cannot connect to localhost:8001"

**This is normal!** On Windows machine, `localhost` refers to the Windows machine itself.

**Solution:**
1. Find your development machine's IP:
   ```bash
   # On Linux/Mac
   hostname -I
   # e.g., 192.168.1.100
   ```

2. Update app config to use that IP:
   ```dart
   // In lib/core/services/api_service.dart
   const String API_URL = 'http://192.168.1.100:8001';
   // Instead of: 'http://localhost:8001'
   ```

3. Rebuild:
   ```cmd
   flutter clean
   flutter pub get
   flutter build windows --release
   ```

---

## 📦 Distribution (After Testing)

### Option 1: Portable (Simplest)

```cmd
# Create ZIP of Release folder
cd build\windows\x64\runner
Compress-Archive -Path Release -DestinationPath AttendanceAI-v1.0.0.zip

# Share this ZIP file
# Users extract and run AttendanceAI.exe
```

### Option 2: Create Installer

**Using Inno Setup (Free):**

1. Download: https://jrsoftware.org/isdl.php

2. Create `installer.iss`:
```ini
[Setup]
AppName=AttendanceAI
AppVersion=1.0.0
DefaultDirName={pf}\AttendanceAI
DefaultGroupName=AttendanceAI
OutputDir=.
OutputBaseFilename=AttendanceAI-Setup-v1.0.0

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs

[Icons]
Name: "{group}\AttendanceAI"; Filename: "{app}\AttendanceAI.exe"
Name: "{commondesktop}\AttendanceAI"; Filename: "{app}\AttendanceAI.exe"

[Run]
Filename: "{app}\AttendanceAI.exe"; Description: "Launch AttendanceAI"; Flags: nowait postinstall
```

3. Compile in Inno Setup GUI
4. Get `AttendanceAI-Setup-v1.0.0.exe`

---

## 🎬 Quick Start Commands Summary

### On Development Machine (Linux/Mac):
```bash
# One time setup
flutter config --enable-windows-desktop

# Verify everything
flutter doctor

# Build for Windows
cd mobile_app
flutter build windows --release
```

### On Windows Test Machine:
```cmd
# Install Visual Studio 2022 Community
# Install Flutter SDK

# Transfer project
cd C:\Projects\face-recognition-attendance\mobile_app

# Build
flutter clean
flutter pub get
flutter build windows --release

# Run
build\windows\x64\runner\Release\AttendanceAI.exe

# Or debug mode
flutter run -d windows
```

---

## 📊 Development Workflow

### Typical Daily Workflow:

```
┌─────────────────────────────────────────────────┐
│  1. Make code changes on Linux/Mac (lib/)      │
│  2. Test on Linux: flutter run -d linux        │
│  3. Commit and push to Git                     │
│  4. On Windows: git pull                       │
│  5. Rebuild: flutter build windows --release   │
│  6. Test on Windows                            │
│  7. If bugs, go back to step 1                 │
└─────────────────────────────────────────────────┘
```

---

## 🎨 Customizing for Windows

### Change App Icon

1. Prepare 1024x1024 PNG
2. Convert to ICO format: https://convertio.co/png-ico/
3. Place in: `windows/runner/resources/app_icon.ico`
4. Rebuild

### Change App Title

Edit `windows/runner/main.cpp`:
```cpp
flutter::TextInputPlugin::SetEditingState(view, "AttendanceAI");
```

### Adjust Window Size

Edit `windows/runner/win32_window.cc`:
```cpp
int width = 1280;
int height = 720;
```

---

## 🔗 Connecting Windows App to Backend

Your backend runs on: `http://localhost:8001`

**On Windows machine:**
- If on same network, use development machine IP: `http://192.168.1.X:8001`
- If on same machine, use `localhost:8001`

**Update in code:**
```dart
// lib/core/services/api_service.dart
const String API_BASE_URL = 'http://YOUR_DEV_IP:8001/api/v1';
```

---

## ✅ What You Get

After following this guide, you'll have:

✅ Working Windows desktop app
✅ Same code as mobile app (just different platform target)
✅ Full functionality (attendance, dashboard, etc.)
✅ Executable for distribution
✅ Development setup for ongoing updates

---

## 🚀 Next Steps

1. **Setup Windows machine** (Phase 2)
2. **Transfer project** (Phase 3)
3. **Build app** (Phase 4)
4. **Test thoroughly** (Phase 5)
5. **Fix any issues** (repeat dev cycle)
6. **Create installer** (optional)

---

## 💡 Tips

- Keep mobile and desktop code in sync
- Test on Windows regularly
- Use same API endpoints for both
- Desktop window can be larger than mobile
- All UI responds to window resize

---

## 📞 Support Resources

- Flutter Windows Docs: https://docs.flutter.dev/deployment/windows
- Flutter Discord: https://discord.gg/flutter
- Stack Overflow: Tag `flutter` and `windows`

---

**You're ready to build your Windows desktop app!** 🎉
