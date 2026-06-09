# Desktop App Development - Quick Start Guide

## 🎯 Your Exact Workflow

You're developing on **Linux/Mac**, testing on **Windows**.

This guide is step-by-step for that exact scenario.

---

## 📋 What You Need

### On Your Dev Machine (Linux/Mac):
- ✅ Flutter (already have it)
- ✅ Git
- ✅ Text editor
- ✅ This project

### On Windows Test Machine:
- Windows 10 or 11
- Visual Studio 2022 Community (free)
- Flutter SDK
- USB drive or network access (to transfer files)

---

## 🚀 Step 1: Prepare Your Dev Machine (5 minutes)

### Check Flutter is Ready:

```bash
cd /root/face-recognition-attendance/mobile_app

flutter doctor

# You should see:
# ✓ Flutter
# ✓ Dart
# ✓ Android toolchain (if you have it)
```

### Enable Windows Desktop Support:

```bash
flutter config --enable-windows-desktop

flutter config --list | grep windows
# Should show: enable-windows-desktop: true
```

Done! ✅

---

## 🖥️ Step 2: Setup Windows Machine (30 minutes - one time only)

### Download & Install Visual Studio 2022 Community

1. Go to: **https://visualstudio.microsoft.com/vs/community/**
2. Click **Download Visual Studio 2022 Community**
3. Run installer
4. Select: **Desktop development with C++**
5. Click **Install**
6. Wait 10-15 minutes
7. Restart computer

### Download & Install Flutter SDK

1. Go to: **https://docs.flutter.dev/get-started/install/windows**
2. Download Flutter SDK (usually ~500MB)
3. Extract to: `C:\src\flutter` (or your preference)
4. Add `C:\src\flutter\bin` to Windows PATH:
   - Press `Win+X`, select **System**
   - Click **Advanced system settings**
   - Click **Environment Variables**
   - Under "User variables", click **New**
   - Variable name: `PATH`
   - Variable value: `C:\src\flutter\bin`
   - Click **OK** multiple times
5. Restart PowerShell

### Verify Installation

Open PowerShell and run:
```cmd
flutter doctor

# Should show:
# ✓ Flutter (Channel stable)
# ✓ Windows Version
# ✓ Visual Studio (full)
```

**Done!** ✅

---

## 📦 Step 3: Get Project to Windows Machine (5 minutes)

### Option A: Using Git (Recommended)

**On your dev machine:**
```bash
cd /root/face-recognition-attendance
git add .
git commit -m "Prepare for Windows desktop build"
git push origin main
```

**On Windows machine:**
```cmd
cd C:\Projects
git clone https://github.com/YOUR_REPO/face-recognition-attendance.git
cd face-recognition-attendance\mobile_app
```

### Option B: Using USB Drive

**On your dev machine:**
```bash
cd /root/face-recognition-attendance
tar -czf mobile_app.tar.gz mobile_app/
# Or: zip -r mobile_app.zip mobile_app/
# Then copy to USB drive
```

**On Windows:**
1. Extract to `C:\Projects\mobile_app`
2. Open PowerShell in that folder

### Option C: Network Transfer

```bash
# On Linux/Mac, start simple HTTP server
cd /root/face-recognition-attendance
python3 -m http.server 8888

# On Windows
# Open browser: http://YOUR_LINUX_IP:8888
# Download mobile_app folder
```

**You now have the project on Windows!** ✅

---

## 🔨 Step 4: Build the Windows App (10 minutes)

### On Windows Machine:

```cmd
# Navigate to project
cd C:\Projects\face-recognition-attendance\mobile_app

# Step 1: Clean build folder
flutter clean

# Step 2: Get dependencies
flutter pub get
# This downloads all packages (takes 2-3 minutes first time)

# Step 3: Build
flutter build windows --release
# This compiles the app (takes 3-5 minutes)
```

### Watch for Success Message:

```
Building Windows application...
├─ Compiling Dart...
├─ Building native plugins...
├─ Linking...
└─ 🎉 Build complete!

✓ Built build\windows\x64\runner\Release\AttendanceAI.exe
Size: 145 MB
```

**Your app is built!** ✅

---

## ▶️ Step 5: Run and Test the App

### Method 1: Click and Run (Easiest)

1. Open File Explorer
2. Navigate to: `build\windows\x64\runner\Release\`
3. Double-click `AttendanceAI.exe`
4. App launches!

### Method 2: Command Line

```cmd
cd build\windows\x64\runner\Release
.\AttendanceAI.exe
```

### Method 3: Debug Mode (During Development)

```cmd
# In mobile_app folder
flutter run -d windows

# This shows real-time logs
# Press 'R' to hot-reload
# Press 'Q' to quit
```

---

## 🧪 Step 6: Test the App Features

### Checklist:

- [ ] **Launch**: App starts without errors
- [ ] **Window**: Appears, sized correctly (1280x720+)
- [ ] **Navigation**: Menu works, can navigate between screens
- [ ] **Student Screen**: Shows attendance data
- [ ] **Parent Screen**: Can view child's attendance
- [ ] **Buttons**: All clickable and responsive
- [ ] **Input Fields**: Text entry works
- [ ] **Animations**: Smooth, no stuttering
- [ ] **Resize**: Window can be resized
- [ ] **Colors**: Dark theme displays correctly

### Backend Connectivity

Your app needs to connect to the backend API.

**First, check if backend is accessible:**

```cmd
# On Windows, ping your dev machine
ping YOUR_DEV_MACHINE_IP
# e.g., ping 192.168.1.100

# Then test API
curl http://192.168.1.100:8001/api/v1/health
# Should return: {"status":"healthy"...}
```

**If it fails**, you need to update the API URL:

1. Edit: `lib/core/services/api_service.dart`
2. Change: `const String API_BASE_URL = 'http://localhost:8001'`
3. To: `const String API_BASE_URL = 'http://192.168.1.100:8001'`
4. Rebuild: `flutter build windows --release`

---

## 🔄 Step 7: Development Cycle

### When You Find a Bug or Want to Add Features:

```
1. Make changes on your dev machine (Linux/Mac)
   └─ Edit files in mobile_app/lib/

2. Test on Linux (optional)
   └─ flutter run -d linux

3. Commit and push
   └─ git commit -m "Fix button styling"
   └─ git push

4. On Windows machine, pull changes
   └─ git pull

5. Rebuild
   └─ flutter clean
   └─ flutter pub get
   └─ flutter build windows --release

6. Test on Windows
   └─ build\windows\x64\runner\Release\AttendanceAI.exe

7. Repeat as needed
```

---

## 📁 Project Structure Reference

```
mobile_app/
├── lib/
│   ├── main.dart                    ← App entry point
│   ├── app.dart                     ← App configuration
│   ├── screens/                     ← All UI screens
│   │   ├── student_screen.dart
│   │   ├── parent_screen.dart
│   │   ├── admin_dashboard.dart
│   │   └── ...
│   ├── widgets/                     ← Reusable components
│   ├── providers/                   ← State management
│   └── core/
│       ├── services/
│       │   └── api_service.dart     ← Backend connection
│       └── models/                  ← Data models
│
├── windows/                         ← Windows-specific
│   ├── runner/
│   │   ├── main.cpp                 ← Entry point
│   │   └── resources/
│   │       └── app_icon.ico         ← App icon
│   └── CMakeLists.txt               ← Build config
│
├── build/                           ← Build output
│   └── windows/x64/runner/Release/  ← Final app here!
│
└── pubspec.yaml                     ← Dependencies (same for all platforms)
```

---

## 🎯 Key Points to Remember

1. **Same code, different platform**: Changes in `lib/` apply to Android, iOS, Windows, Linux, macOS, Web
2. **Platform-specific**: Folder like `windows/`, `android/`, etc. are platform-specific
3. **Shared dependencies**: `pubspec.yaml` dependencies work on all platforms
4. **You mainly edit `lib/`**: The platform folders rarely need changes
5. **Build separately**: Each platform builds separately (`flutter build windows`, `flutter build apk`, etc.)

---

## 🐛 Troubleshooting Quick Fixes

### "App won't launch"
```cmd
flutter clean
flutter pub get
flutter build windows --release
```

### "Backend connection fails"
- Check backend is running on dev machine
- Use dev machine IP, not `localhost`
- Verify firewall allows connection

### "Build takes forever"
- First build takes longer (5-10 mins)
- Subsequent builds faster (2-3 mins)
- Close other apps to free resources

### "'Flutter' is not recognized"
```cmd
# Flutter not in PATH
# Add C:\src\flutter\bin to Environment Variables
# Then restart PowerShell
```

### "Visual Studio tools not found"
```cmd
flutter doctor

# If Visual Studio missing, reinstall with
# "Desktop development with C++" workload
```

---

## 🎬 Real-World Workflow Example

### Day 1: Initial Setup
```bash
# Dev machine
flutter config --enable-windows-desktop
git push

# Windows machine
git clone ...
flutter pub get
flutter build windows --release
# Test and verify app works
```

### Day 2: Add Feature (Update Student List UI)
```bash
# Dev machine
# Edit: lib/screens/student_screen.dart
# Add new columns to student table

git commit -m "Add student attendance summary"
git push

# Windows machine
git pull
flutter clean
flutter pub get
flutter build windows --release
# Test new feature works on Windows
```

### Day 3: Fix Bug (Button not clickable)
```bash
# Windows machine finds bug

# Dev machine
# Fix: lib/widgets/attendance_button.dart
# Increase tap target size

git commit -m "Fix: make attendance button more tappable"
git push

# Windows machine
git pull
flutter build windows --release
# Verify bug is fixed
```

---

## ✨ Windows App vs Mobile App

| Feature | Mobile | Desktop | Same Code? |
|---------|--------|---------|-----------|
| UI screens | ✅ Portrait | ✅ Landscape | ✅ Yes |
| Buttons | ✅ Touch | ✅ Click | ✅ Yes |
| Size | 375x667 | 1280x720+ | ✅ Responsive |
| Icons | ✅ Material | ✅ Material | ✅ Yes |
| API calls | ✅ HTTP | ✅ HTTP | ✅ Yes |
| Dark mode | ✅ Yes | ✅ Yes | ✅ Yes |
| Notifications | ✅ Yes | ⚠️ Limited | ⚠️ Partial |

---

## 📊 Timeline Example

**Total time to get working Windows desktop app:**

- Initial setup: 30 minutes (one-time)
- Transfer project: 5 minutes (one-time)
- Build app: 10 minutes (first time, 2-3 after)
- Test: 5-10 minutes per iteration
- **Total**: ~1 hour for everything including testing

---

## 🚀 You're Ready!

You now have everything you need to:
1. ✅ Develop on your Linux/Mac machine
2. ✅ Build Windows desktop app
3. ✅ Test on Windows computer
4. ✅ Iterate and improve
5. ✅ Create distribution package

**Start with Step 2 on your Windows machine** (Visual Studio + Flutter SDK)

Let me know when you hit any issues! 🎉
