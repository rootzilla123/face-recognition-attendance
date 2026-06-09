# iOS App - Quick Start

## ✅ Already Configured

- **App Name**: AttendanceAI
- **Bundle ID**: com.shadrack.attendance.mobileApp

## 📱 Requirements

- **Mac computer** (required)
- **Xcode** from Mac App Store
- **iPhone** for testing

## 🚀 Build in 3 Steps

### 1. Install Xcode
Download from Mac App Store

### 2. Build
```bash
cd mobile_app
./build_ios.sh
```

Choose option 1 (Development) for testing

### 3. Run on iPhone
```bash
# Connect iPhone via USB
flutter devices

# Run
flutter run -d <device-id>
```

**Or use Xcode:**
```bash
open ios/Runner.xcworkspace
# Click Run (▶) button
```

## 🎨 Add Custom Icon

```bash
./setup_ios_icons.sh /path/to/your/logo.png
```

Requirements:
- 1024x1024 pixels
- PNG format
- No transparency

## 🔐 Code Signing (First Time)

1. Open: `open ios/Runner.xcworkspace`
2. Select **Runner** target
3. **Signing & Capabilities** tab
4. Check **Automatically manage signing**
5. Select your **Team** (Apple ID)

## 📦 Distribution

### TestFlight (Beta Testing)
```bash
./build_ios.sh
# Select option 2
```

Upload to: https://appstoreconnect.apple.com

### App Store
```bash
./build_ios.sh
# Select option 3
```

Submit via App Store Connect

## 🐛 Common Issues

**"No provisioning profile"**
- Open Xcode → Signing & Capabilities
- Enable "Automatically manage signing"

**"Untrusted Developer"**
- iPhone: Settings → General → VPN & Device Management
- Trust your developer account

**Build errors**
```bash
flutter clean
rm -rf ios/Pods
./build_ios.sh
```

## 📚 Full Guide

See `IOS_APP_GUIDE.md` for complete instructions.

## 🎯 App Store Checklist

- [ ] App icon (1024x1024)
- [ ] Screenshots
- [ ] App description
- [ ] Privacy policy
- [ ] Test on real device
- [ ] Apple Developer account ($99/year)

## 💡 Quick Tips

- Use TestFlight for beta testing
- Test on real iPhone (not just simulator)
- Read Apple's review guidelines
- Screenshots required for submission

Need help? Check the full guide!
