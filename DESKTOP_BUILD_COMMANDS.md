# Desktop App Build - Command Reference

## 🎯 Copy-Paste Commands for Your Workflow

---

## 📋 ON YOUR DEV MACHINE (Linux/Mac)

### First Time Setup (One-Time)

```bash
# Navigate to project
cd /root/face-recognition-attendance/mobile_app

# Enable Windows desktop support
flutter config --enable-windows-desktop

# Verify it's enabled
flutter config --list | grep windows
# Output: enable-windows-desktop: true ✅

# Verify Flutter is ready
flutter doctor
# Look for: ✓ Flutter, ✓ Dart, etc.

# Commit changes
cd /root/face-recognition-attendance
git add .
git commit -m "Prepare for Windows desktop development"
git push origin main
```

### When You Make Code Changes

```bash
# Navigate to project
cd /root/face-recognition-attendance/mobile_app

# Run on Linux (optional - to test quickly)
flutter run -d linux

# Commit changes
cd /root/face-recognition-attendance
git status
git add lib/    # Add only lib/ folder usually
git commit -m "Description of changes"
git push origin main

# Then on Windows machine: git pull && rebuild
```

---

## 🖥️ ON WINDOWS TEST MACHINE

### One-Time Windows Setup (30 minutes)

```cmd
REM ===== INSTALL VISUAL STUDIO 2022 COMMUNITY =====
REM 1. Download from: https://visualstudio.microsoft.com/vs/community/
REM 2. Run installer
REM 3. Select: "Desktop development with C++"
REM 4. Install (takes 10-15 minutes)
REM 5. Restart computer

REM ===== INSTALL FLUTTER SDK =====
REM 1. Download from: https://docs.flutter.dev/get-started/install/windows
REM 2. Extract to: C:\src\flutter
REM 3. Add to PATH: C:\src\flutter\bin
REM    - Win+X -> System -> Advanced system settings
REM    - Environment Variables -> New
REM    - Variable: C:\src\flutter\bin
REM    - Restart PowerShell

REM ===== VERIFY INSTALLATION =====
flutter doctor

REM Expected output:
REM ✓ Flutter (Channel stable)
REM ✓ Windows Version
REM ✓ Visual Studio (full)
```

### First Time: Clone/Get Project

```cmd
REM === Option A: Using Git ===
cd C:\Projects
git clone https://github.com/YOUR_REPO/face-recognition-attendance.git
cd face-recognition-attendance\mobile_app

REM === Option B: Using USB Drive ===
REM Extract folder to: C:\Projects\face-recognition-attendance\mobile_app

REM === Option C: Network Transfer ===
REM Download from dev machine's HTTP server
```

### Build the App

```cmd
REM Navigate to project
cd C:\Projects\face-recognition-attendance\mobile_app

REM Step 1: Clean
flutter clean

REM Step 2: Get dependencies
flutter pub get

REM Step 3: Build for Windows
flutter build windows --release

REM Wait 3-5 minutes...
REM Look for: ✓ Built build\windows\x64\runner\Release\AttendanceAI.exe
```

### Run the App

```cmd
REM Option 1: Run from File Explorer
REM Navigate to: build\windows\x64\runner\Release\
REM Double-click: AttendanceAI.exe

REM Option 2: Command Line
cd build\windows\x64\runner\Release
.\AttendanceAI.exe

REM Option 3: Debug Mode (during development)
REM In mobile_app folder:
flutter run -d windows

REM Then:
REM - Press R to hot-reload
REM - Press Q to quit
REM - Check logs in console
```

### Update After Changes from Dev Machine

```cmd
REM In your project folder:
git pull origin main

REM Rebuild:
flutter clean
flutter pub get
flutter build windows --release

REM Run:
build\windows\x64\runner\Release\AttendanceAI.exe
```

---

## 🔄 Iteration Cycle (Repeat as Needed)

### Dev Machine → Windows Loop:

```bash
# ===== ON DEV MACHINE (Linux/Mac) =====
cd /root/face-recognition-attendance/mobile_app

# 1. Make changes to lib/ files
# 2. Test locally (optional)
flutter run -d linux

# 3. Commit and push
cd /root/face-recognition-attendance
git add .
git commit -m "Your feature description"
git push origin main

# ===== ON WINDOWS MACHINE =====
cd C:\Projects\face-recognition-attendance\mobile_app

# 4. Pull latest
git pull origin main

# 5. Rebuild
flutter clean
flutter pub get
flutter build windows --release

# 6. Test on Windows
build\windows\x64\runner\Release\AttendanceAI.exe

# 7. If bugs, go back to step 1 on dev machine
```

---

## 🔧 Common Commands

### Check Configuration

```cmd
REM Verify Windows desktop enabled
flutter config --list | findstr windows

REM Check Flutter doctor status
flutter doctor
flutter doctor -v

REM Check available devices
flutter devices
```

### Debugging

```cmd
REM Run in debug mode with logs
flutter run -d windows

REM Build debug version
flutter build windows

REM Verbose build output
flutter build windows --release --verbose
```

### Clean & Rebuild

```cmd
REM Clean everything
flutter clean

REM Get fresh dependencies
flutter pub get

REM Clean and rebuild (fresh start)
flutter clean && flutter pub get && flutter build windows --release
```

### Update Dependencies

```cmd
REM Check for updates
flutter pub outdated

REM Update all dependencies
flutter pub upgrade

REM Update specific package
flutter pub add package_name
```

---

## 📊 Build Times

| Operation | Time | Notes |
|-----------|------|-------|
| `flutter clean` | 10 sec | Fast |
| `flutter pub get` | 30-60 sec | First time slower |
| `flutter build windows --release` | 3-5 min | First build slower |
| Subsequent builds | 2-3 min | Much faster |
| `flutter run -d windows` | 5-10 sec | Hot reload available |

---

## ✅ Complete Workflow Checklist

### Dev Machine Setup
- [ ] `flutter config --enable-windows-desktop` ✅
- [ ] `flutter doctor` shows no errors ✅
- [ ] Code committed to Git ✅

### Windows Machine Setup
- [ ] Visual Studio 2022 Community installed ✅
- [ ] Flutter SDK installed in C:\src\flutter ✅
- [ ] C:\src\flutter\bin added to PATH ✅
- [ ] PowerShell restarted ✅
- [ ] `flutter doctor` works ✅

### First Build
- [ ] Project transferred to Windows ✅
- [ ] `flutter clean` ✅
- [ ] `flutter pub get` ✅
- [ ] `flutter build windows --release` ✅
- [ ] App found in build\windows\x64\runner\Release\ ✅

### Testing
- [ ] App launches ✅
- [ ] Window displays correctly ✅
- [ ] UI responsive to clicks ✅
- [ ] Navigation works ✅
- [ ] API connectivity working ✅

---

## 🎯 Quick Reference

### One-Line Build (Windows)
```cmd
cd C:\Projects\face-recognition-attendance\mobile_app && flutter clean && flutter pub get && flutter build windows --release
```

### One-Line Update & Build (Windows)
```cmd
cd C:\Projects\face-recognition-attendance\mobile_app && git pull && flutter clean && flutter pub get && flutter build windows --release
```

### One-Line Debug Run (Windows)
```cmd
cd C:\Projects\face-recognition-attendance\mobile_app && flutter run -d windows
```

---

## 🔗 Backend Connectivity

### Find Dev Machine IP (Linux/Mac)

```bash
hostname -I
# Output: 192.168.1.100

# Or get all IPs
ifconfig | grep "inet " | grep -v 127.0.0.1
```

### Test Connection from Windows

```cmd
REM Test if dev machine is reachable
ping 192.168.1.100

REM Test if API is accessible
curl http://192.168.1.100:8001/api/v1/health

REM If using Windows Subsystem for Linux:
wsl curl http://192.168.1.100:8001/api/v1/health
```

### Update API URL if Needed

Edit on dev machine:
```dart
// File: lib/core/services/api_service.dart

// OLD (won't work on Windows):
const String API_BASE_URL = 'http://localhost:8001/api/v1';

// NEW (use dev machine IP):
const String API_BASE_URL = 'http://192.168.1.100:8001/api/v1';
```

Then rebuild on Windows.

---

## 🐛 Quick Troubleshooting Commands

```cmd
REM Check everything
flutter doctor

REM Detailed diagnostics
flutter doctor -v

REM See available platforms
flutter devices

REM Clear cache
flutter clean

REM Start fresh
flutter clean && flutter pub get && flutter analyze

REM Run with verbose output
flutter build windows --release --verbose

REM Check if app runs at all
flutter run -d windows --release

REM See live logs while app runs
flutter run -d windows
```

---

## 📦 Distribution Commands (After Testing)

```cmd
REM Create portable ZIP
cd C:\Projects\face-recognition-attendance\mobile_app\build\windows\x64\runner
Compress-Archive -Path Release -DestinationPath AttendanceAI-v1.0.0.zip

REM Send to others:
REM 1. Users extract ZIP
REM 2. Users run AttendanceAI.exe
REM 3. Done!
```

---

## 🎬 Example Daily Sessions

### Session 1: Initial Setup (First Time)

```bash
# ===== DEV MACHINE =====
cd /root/face-recognition-attendance/mobile_app
flutter config --enable-windows-desktop
flutter doctor
cd ..
git push origin main

# ===== WINDOWS MACHINE =====
git clone ...
flutter doctor
cd face-recognition-attendance\mobile_app
flutter clean
flutter pub get
flutter build windows --release
# Test the app
```

### Session 2: Add Feature

```bash
# ===== DEV MACHINE =====
# Edit lib/screens/student_screen.dart
# Add new feature
flutter run -d linux  # Quick test
cd /root/face-recognition-attendance
git commit -m "Add student attendance filter"
git push origin main

# ===== WINDOWS MACHINE =====
cd C:\Projects\face-recognition-attendance\mobile_app
git pull
flutter clean
flutter pub get
flutter build windows --release
# Verify feature works on Windows
```

### Session 3: Bug Fix

```bash
# ===== WINDOWS MACHINE =====
# Found bug: button styling wrong

# ===== DEV MACHINE =====
# Edit lib/widgets/attendance_button.dart
git commit -m "Fix: button styling for Windows"
git push

# ===== WINDOWS MACHINE =====
git pull
flutter build windows --release
# Bug fixed! ✅
```

---

## 🚀 You're Ready!

**Print this page or bookmark it!**

Keep it handy while developing. You'll mostly use:

1. **Dev Machine**: Edit → Commit → Push
2. **Windows Machine**: Pull → Build → Test

That's your workflow! 🎉
