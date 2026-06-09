# Mobile App - Quick Start Guide

## 🚀 Test Locally (3 Steps)

### Step 1: Configure for Local Testing
```bash
cd mobile_app
./configure_local.sh
# Or provide your IP: ./configure_local.sh 192.168.1.100
```

### Step 2: Start Backend Services
```bash
cd ..
./start_all.sh
```

### Step 3: Run the App
```bash
cd mobile_app
flutter run
```

That's it! The app will connect to your local backend.

---

## 📦 Build APK (2 Steps)

### Step 1: Switch to Production Config
```bash
cd mobile_app
./configure_production.sh
```

### Step 2: Build APK
```bash
./build_apk.sh release
```

APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

---

## 📱 Install APK on Device

### Via ADB
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Via File Transfer
1. Copy APK to device
2. Open APK file on device
3. Allow "Install from Unknown Sources"
4. Install

---

## ⚙️ Configuration Scripts

| Script | Purpose |
|--------|---------|
| `./configure_local.sh` | Configure for local testing |
| `./configure_production.sh` | Configure for production |
| `./build_apk.sh debug` | Build debug APK |
| `./build_apk.sh release` | Build release APK |
| `./build_apk.sh both` | Build both debug and release |

---

## 🔍 Troubleshooting

### App can't connect to backend

**Check backend is running:**
```bash
curl http://localhost:8001/api/v1/health
```

**Check your local IP:**
```bash
# Linux/Mac
ip addr show | grep "inet " | grep -v 127.0.0.1

# Or
ifconfig | grep "inet " | grep -v 127.0.0.1
```

**Reconfigure with correct IP:**
```bash
./configure_local.sh YOUR_CORRECT_IP
```

### Flutter not found

**Install Flutter:**
```bash
# Download from: https://flutter.dev/docs/get-started/install
# Or use snap (Linux):
sudo snap install flutter --classic
```

### Build failed

**Clean and retry:**
```bash
flutter clean
flutter pub get
./build_apk.sh release
```

---

## 📋 Pre-Build Checklist

Before building production APK:

- [ ] Backend services are working
- [ ] Tested app locally
- [ ] Switched to production config (`./configure_production.sh`)
- [ ] Updated version in `pubspec.yaml`
- [ ] Tested login/register
- [ ] Tested key features
- [ ] Checked app permissions

---

## 🎯 Quick Commands

```bash
# Configure for local testing
cd mobile_app && ./configure_local.sh

# Start backend
cd .. && ./start_all.sh

# Run app
cd mobile_app && flutter run

# Build production APK
./configure_production.sh && ./build_apk.sh release

# Install on device
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## 📖 Full Documentation

For detailed instructions, see:
- `MOBILE_APP_LOCAL_TESTING_AND_BUILD.md` - Complete guide
- `mobile_app/README.md` - App-specific documentation

---

## ✅ What Works

- ✅ Email/Password authentication
- ✅ Google Sign-In
- ✅ Attendance viewing
- ✅ Camera streams (MJPEG)
- ✅ Notifications
- ✅ Reports generation
- ✅ PDF export
- ✅ Profile management
- ✅ Settings configuration
- ✅ Push notifications (with FCM setup)
- ✅ App version enforcement

---

## 🔄 Workflow

```
Local Testing:
  configure_local.sh → start_all.sh → flutter run

Production Build:
  configure_production.sh → build_apk.sh release → adb install
```

---

## 💡 Tips

1. **Use Android Emulator for quick testing**
   - No need to configure IP
   - Use `10.0.2.2` for localhost

2. **Use physical device for real testing**
   - Better performance
   - Test camera, notifications, etc.

3. **Keep production config separate**
   - Always run `configure_production.sh` before building release APK
   - Scripts create backups automatically

4. **Test on multiple devices**
   - Different Android versions
   - Different screen sizes
   - Different manufacturers

---

## 🆘 Need Help?

1. Check logs: `flutter logs`
2. Check backend: `curl http://localhost:8001/api/v1/health`
3. Review full guide: `MOBILE_APP_LOCAL_TESTING_AND_BUILD.md`
4. Check Flutter doctor: `flutter doctor`
