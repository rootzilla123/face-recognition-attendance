# Windows Desktop App - Build Guide

## 🎉 Good News!

Your Flutter mobile app **already supports Windows desktop** with minimal changes! Flutter is cross-platform, so the same codebase works on:
- ✅ Android
- ✅ iOS
- ✅ Windows
- ✅ macOS
- ✅ Linux
- ✅ Web

## 📋 Prerequisites

### 1. Windows Development Environment

You need:
- **Windows 10/11** (64-bit)
- **Visual Studio 2022** (Community Edition is free)
  - Download: https://visualstudio.microsoft.com/downloads/
  - Required workloads:
    - "Desktop development with C++"
    - Windows 10/11 SDK

### 2. Flutter Desktop Support

```bash
# Enable Windows desktop support
flutter config --enable-windows-desktop

# Check if Windows is enabled
flutter devices
# Should show "Windows (desktop)" in the list
```

## 🚀 Quick Build (3 Steps)

### Step 1: Configure for Desktop
```bash
cd mobile_app
./configure_desktop.sh
```

### Step 2: Build Windows App
```bash
./build_windows.sh
```

### Step 3: Run the App
```bash
# The installer will be at:
build/windows/x64/runner/Release/AttendanceAI-Setup.exe
```

That's it! Double-click the installer to install on Windows.

---

## 🔧 Manual Build Steps

### 1. Configure for Production
```bash
cd mobile_app
./configure_production.sh
```

### 2. Build Windows Release
```bash
flutter build windows --release
```

### 3. Find the Executable
The built app will be at:
```
mobile_app/build/windows/x64/runner/Release/
├── mobile_app.exe          # Main executable
├── flutter_windows.dll     # Flutter runtime
├── data/                   # App resources
└── ... (other DLLs)
```

---

## 📦 Creating an Installer

### Option 1: Inno Setup (Recommended)

**Install Inno Setup:**
- Download: https://jrsoftware.org/isdl.php
- Install Inno Setup 6

**Create Installer Script:**
See `mobile_app/windows/installer.iss` (created below)

**Build Installer:**
```bash
# Using the script
./build_windows_installer.sh

# Or manually
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" windows\installer.iss
```

### Option 2: MSIX Package (Microsoft Store)

```bash
# Build MSIX package
flutter build windows --release

# Package with MSIX tool
msix:create
```

### Option 3: Portable ZIP

```bash
# Just zip the Release folder
cd build/windows/x64/runner/Release
7z a AttendanceAI-Portable.zip *
```

---

## 🎨 Desktop-Specific Features

### Window Size & Title

Edit `mobile_app/windows/runner/main.cpp`:

```cpp
// Set window size
const int window_width = 1280;
const int window_height = 720;

// Set window title
const wchar_t* window_title = L"AttendanceAI - Face Recognition System";
```

### App Icon

Replace `mobile_app/windows/runner/resources/app_icon.ico` with your icon.

### Splash Screen

Edit `mobile_app/windows/runner/resources/splash.png`

---

## 🔍 Differences from Mobile

### What Works Differently

| Feature | Mobile | Desktop |
|---------|--------|---------|
| Camera | Device camera | Webcam |
| Notifications | Push notifications | System tray notifications |
| Biometrics | Fingerprint/Face ID | Windows Hello (optional) |
| File Picker | Gallery | File explorer |
| Screen Size | Small, touch | Large, mouse/keyboard |

### Desktop Advantages

✅ **Larger Screen** - Better for viewing reports and dashboards
✅ **Keyboard Input** - Faster data entry
✅ **Multi-Window** - Can have multiple views open
✅ **Always On** - Can run in background/system tray
✅ **Better Performance** - More powerful hardware

### Desktop Use Cases

1. **Admin Dashboard** - Manage system from desktop
2. **Teacher Portal** - View attendance, enter marks
3. **Reception Kiosk** - Check-in station
4. **Monitoring Station** - Watch live camera feeds
5. **Report Generation** - Create and print reports

---

## 🛠️ Desktop-Specific Optimizations

### 1. Responsive Layout

The app should adapt to desktop screen sizes:

```dart
// In your widgets
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth > 1200) {
      // Desktop layout - side-by-side
      return Row(children: [...]);
    } else {
      // Mobile layout - stacked
      return Column(children: [...]);
    }
  },
)
```

### 2. Keyboard Shortcuts

Add keyboard shortcuts for desktop:

```dart
import 'package:flutter/services.dart';

Shortcuts(
  shortcuts: {
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN): 
      NewRecordIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS): 
      SaveIntent(),
  },
  child: Actions(
    actions: {
      NewRecordIntent: CallbackAction<NewRecordIntent>(
        onInvoke: (intent) => _createNewRecord(),
      ),
    },
    child: YourWidget(),
  ),
)
```

### 3. System Tray

Add system tray icon (optional):

```yaml
# pubspec.yaml
dependencies:
  system_tray: ^2.0.3
```

```dart
// Initialize system tray
final systemTray = SystemTray();
await systemTray.initSystemTray(
  title: "AttendanceAI",
  iconPath: 'assets/icons/tray_icon.ico',
);
```

### 4. Auto-Start on Windows

Create a registry entry or startup shortcut:

```dart
import 'package:launch_at_startup/launch_at_startup.dart';

// Enable auto-start
await launchAtStartup.enable();

// Disable auto-start
await launchAtStartup.disable();
```

---

## 📊 Desktop vs Mobile Comparison

### File Size

| Platform | Size | Notes |
|----------|------|-------|
| Android APK | ~50-80 MB | Compressed |
| Windows EXE | ~150-200 MB | Includes Flutter runtime |
| Windows Installer | ~180-220 MB | Includes dependencies |

### Performance

| Metric | Mobile | Desktop |
|--------|--------|---------|
| Startup Time | 2-3s | 1-2s |
| Memory Usage | 100-200 MB | 150-300 MB |
| CPU Usage | Low | Very Low |

---

## 🎯 Recommended Desktop Features

### Must-Have
1. ✅ Responsive layout for large screens
2. ✅ Keyboard shortcuts
3. ✅ Window state persistence (size, position)
4. ✅ Multi-window support (optional)

### Nice-to-Have
5. ⭐ System tray integration
6. ⭐ Auto-start on boot
7. ⭐ Desktop notifications
8. ⭐ Print support (already have PDF)
9. ⭐ Drag & drop file upload
10. ⭐ Multiple monitor support

---

## 🔧 Build Configuration

### Debug Build (for testing)
```bash
flutter build windows --debug
```

### Release Build (for distribution)
```bash
flutter build windows --release
```

### Profile Build (for performance testing)
```bash
flutter build windows --profile
```

---

## 📦 Distribution Options

### 1. Direct Download
- Host installer on your website
- Users download and install
- No approval process needed

### 2. Microsoft Store
- Requires developer account ($19/year)
- Build MSIX package
- Submit for review
- Automatic updates

### 3. Portable Version
- No installation required
- Extract and run
- Good for USB drives

### 4. Enterprise Deployment
- MSI package for Group Policy
- Silent install options
- Centralized management

---

## 🐛 Troubleshooting

### Issue: "Windows desktop not available"

**Solution:**
```bash
flutter config --enable-windows-desktop
flutter doctor
```

### Issue: "Visual Studio not found"

**Solution:**
1. Install Visual Studio 2022
2. Install "Desktop development with C++" workload
3. Restart terminal
4. Run `flutter doctor`

### Issue: "Build failed"

**Solution:**
```bash
flutter clean
flutter pub get
flutter build windows --release
```

### Issue: "App crashes on startup"

**Solution:**
1. Check `windows/runner/main.cpp` for errors
2. Run in debug mode: `flutter run -d windows`
3. Check logs in Output window

---

## 📋 Pre-Build Checklist

Before building Windows app:

- [ ] Visual Studio 2022 installed
- [ ] Windows desktop support enabled
- [ ] App tested in debug mode
- [ ] Production URLs configured
- [ ] Version updated in `pubspec.yaml`
- [ ] App icon replaced
- [ ] Window title set
- [ ] Keyboard shortcuts tested
- [ ] Responsive layout verified
- [ ] All features tested on Windows

---

## 🎓 Next Steps

1. **Enable Windows support**
   ```bash
   flutter config --enable-windows-desktop
   ```

2. **Test in debug mode**
   ```bash
   flutter run -d windows
   ```

3. **Build release version**
   ```bash
   ./build_windows.sh
   ```

4. **Create installer**
   ```bash
   ./build_windows_installer.sh
   ```

5. **Distribute**
   - Upload to website
   - Or submit to Microsoft Store

---

## 💡 Pro Tips

1. **Test on clean Windows VM** - Ensure all dependencies are included
2. **Use Inno Setup** - Professional-looking installer
3. **Sign your executable** - Prevents Windows SmartScreen warnings
4. **Add auto-update** - Keep users on latest version
5. **Create portable version** - For users who can't install software

---

## 🆚 When to Use Desktop vs Mobile

### Use Desktop App For:
- 👨‍💼 Admin tasks
- 📊 Report generation
- 🖥️ Monitoring stations
- 👨‍🏫 Teacher workstations
- 🏢 Reception desks

### Use Mobile App For:
- 📱 On-the-go access
- 👨‍🎓 Student self-service
- 👪 Parent notifications
- 📸 Photo uploads
- 🔔 Push notifications

### Use Both:
- Same account works on both
- Data syncs automatically
- Choose based on context

---

## 📞 Support

For Windows-specific issues:
1. Check Flutter Windows docs: https://docs.flutter.dev/desktop
2. Run `flutter doctor -v`
3. Check Visual Studio installation
4. Review build logs

---

## ✨ Summary

Building a Windows desktop app is **easy** because:
- ✅ Same Flutter codebase
- ✅ No code changes needed
- ✅ Just run `flutter build windows`
- ✅ Professional installer with Inno Setup

**You can have a Windows app in under 30 minutes!**
