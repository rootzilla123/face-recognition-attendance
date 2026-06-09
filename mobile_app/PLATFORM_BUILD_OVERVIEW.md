# AttendanceAI - Platform Build Overview

Complete guide for building AttendanceAI on all platforms.

## 📱 Supported Platforms

- ✅ **Android** (APK)
- ✅ **iOS** (iPhone/iPad)
- ✅ **Windows** Desktop
- ✅ **Linux** Desktop
- ✅ **macOS** Desktop (coming soon)
- ✅ **Web** (coming soon)

## 🎨 Branding Status

All platforms are branded as **AttendanceAI** with professional metadata.

## 🚀 Quick Build Commands

### Android (APK)
```bash
./build_apk.sh
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### iOS (iPhone)
```bash
./build_ios.sh
```
Output: `build/ios/ipa/mobile_app.ipa`
**Requires:** macOS + Xcode

### Windows Desktop
```bash
./build_windows.sh
```
Output: `build/windows/x64/runner/Release/AttendanceAI.exe`
**Requires:** Windows or WSL

### Linux Desktop
```bash
./build_linux.sh
```
Output: `build/linux/x64/release/bundle/attendanceai`
**Requires:** Linux

## 🎨 Icon Setup

### Android
```bash
# Place icon at: android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
# Or use: flutter pub run flutter_launcher_icons
```

### iOS
```bash
./setup_ios_icons.sh /path/to/icon.png
```

### Windows
```bash
./update_windows_icon.sh /path/to/icon.png
```

### Linux
```bash
./setup_linux_icons.sh /path/to/icon.png
```

## 📚 Platform-Specific Guides

| Platform | Quick Start | Full Guide |
|----------|-------------|------------|
| Android | `build_apk.sh` | Built-in Flutter docs |
| iOS | `IOS_QUICK_START.md` | `IOS_APP_GUIDE.md` |
| Windows | `WINDOWS_BRANDING_QUICK_START.md` | `WINDOWS_BRANDING_GUIDE.md` |
| Linux | `LINUX_QUICK_START.md` | `LINUX_DESKTOP_GUIDE.md` |

## 🔧 Configuration

### Switch to Production
```bash
./configure_production.sh
```

### Switch to Local Development
```bash
./configure_local.sh
```

## 📦 Distribution Formats

### Android
- **APK** - Direct install
- **AAB** - Google Play Store
- **Split APKs** - Optimized size

### iOS
- **Development** - Testing on your device
- **Ad-Hoc** - TestFlight distribution
- **App Store** - Public release

### Windows
- **Portable EXE** - No installation needed
- **ZIP Archive** - Extract and run
- **Installer** - Professional setup (coming soon)

### Linux
- **Portable Tarball** - Universal
- **System Install** - `/opt/attendanceai`
- **.deb Package** - Debian/Ubuntu (coming soon)
- **.rpm Package** - Fedora/RHEL (coming soon)
- **AppImage** - Run anywhere (coming soon)
- **Flatpak** - Sandboxed (coming soon)
- **Snap** - Ubuntu store (coming soon)

## 🎯 Platform Requirements

### Android
- **Min SDK**: 21 (Android 5.0)
- **Target SDK**: 34 (Android 14)
- **Build**: Any OS with Flutter

### iOS
- **Min iOS**: 12.0
- **Build**: macOS + Xcode only
- **Distribution**: Apple Developer account

### Windows
- **Min Windows**: 10 (64-bit)
- **Build**: Windows or WSL
- **Distribution**: No signing required

### Linux
- **Min Kernel**: 4.15+
- **GTK**: 3.22+
- **Build**: Linux only
- **Distribution**: No signing required

## 📊 Build Matrix

| Platform | Build OS | Requirements | Output Size |
|----------|----------|--------------|-------------|
| Android | Any | Android SDK | ~50-100 MB |
| iOS | macOS | Xcode | ~60-120 MB |
| Windows | Windows/WSL | Flutter | ~80-150 MB |
| Linux | Linux | GTK3 | ~70-130 MB |

## 🔐 Code Signing

### Android
- **Debug**: Auto-signed
- **Release**: Requires keystore
- **Play Store**: Upload key

### iOS
- **Development**: Free Apple ID (7-day limit)
- **Distribution**: Paid account ($99/year)
- **App Store**: Required

### Windows
- **Optional**: Authenticode signing
- **Not required** for distribution

### Linux
- **Not required**
- **Optional**: GPG signing for packages

## 🌟 Features by Platform

| Feature | Android | iOS | Windows | Linux |
|---------|---------|-----|---------|-------|
| Face Recognition | ✅ | ✅ | ✅ | ✅ |
| Camera Access | ✅ | ✅ | ✅ | ✅ |
| Notifications | ✅ | ✅ | ✅ | ✅ |
| Offline Mode | ✅ | ✅ | ✅ | ✅ |
| Auto Updates | ✅ | ✅ | 🔄 | 🔄 |
| Biometric Auth | ✅ | ✅ | ✅ | ✅ |

✅ = Fully supported
🔄 = Coming soon

## 🚀 CI/CD Ready

All build scripts are designed for automation:

```yaml
# Example GitHub Actions
- name: Build Android
  run: cd mobile_app && ./build_apk.sh

- name: Build iOS
  run: cd mobile_app && ./build_ios.sh

- name: Build Windows
  run: cd mobile_app && ./build_windows.sh

- name: Build Linux
  run: cd mobile_app && ./build_linux.sh
```

## 📝 Version Management

Edit `pubspec.yaml`:
```yaml
version: 1.0.0+1
```

- `1.0.0` = Version name (user-facing)
- `+1` = Build number (internal)

This syncs across all platforms automatically!

## 🎉 Quick Start for All Platforms

```bash
cd mobile_app

# Android
./build_apk.sh

# iOS (macOS only)
./build_ios.sh

# Windows (Windows/WSL)
./build_windows.sh

# Linux (Linux only)
./build_linux.sh
```

## 💡 Pro Tips

1. **Test on real devices** - Simulators don't show real performance
2. **Use production config** - Switch before building releases
3. **Version consistently** - Update pubspec.yaml for all platforms
4. **Icon requirements** - Each platform has different size requirements
5. **Code signing** - Set up early for iOS and Android releases
6. **Automated builds** - Use CI/CD for consistent releases
7. **Beta testing** - Use TestFlight (iOS) and internal testing (Android)

## 🐛 Common Issues

### "Flutter not found"
```bash
flutter doctor
```

### "Dependencies missing"
```bash
flutter pub get
```

### "Build failed"
```bash
flutter clean
flutter pub get
# Try build again
```

### Platform-specific issues
Check the platform-specific guide for detailed troubleshooting.

## 📚 Additional Resources

- [Flutter Documentation](https://docs.flutter.dev)
- [Android Publishing](https://developer.android.com/studio/publish)
- [iOS App Distribution](https://developer.apple.com/distribute/)
- [Windows Desktop Apps](https://docs.flutter.dev/platform-integration/windows/building)
- [Linux Desktop Apps](https://docs.flutter.dev/platform-integration/linux/building)

## 🎯 Next Steps

1. Choose your target platform(s)
2. Read the platform-specific guide
3. Set up icons and branding
4. Build and test
5. Distribute to users!

Happy building! 🚀
