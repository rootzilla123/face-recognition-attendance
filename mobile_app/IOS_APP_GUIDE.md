# iOS App Guide - AttendanceAI

## ✅ What's Already Configured

Your iOS app is now branded as:

- **App Name**: AttendanceAI
- **Bundle Display Name**: AttendanceAI
- **Bundle Identifier**: com.shadrack.attendance.mobileApp
- **Version**: Synced from pubspec.yaml

## 📱 Requirements

### Hardware
- **Mac computer** (required for iOS builds)
- **iPhone or iPad** (for testing)
- **USB cable** (for device connection)

### Software
- **macOS** 12.0 or later
- **Xcode** 14.0 or later
- **Flutter** (already installed)
- **CocoaPods** (auto-installed by script)

### Apple Developer Account
- **Free account**: Test on your own devices (7-day limit)
- **Paid account** ($99/year): TestFlight, App Store distribution

## 🚀 Quick Start - Build Your iOS App

### Step 1: Install Xcode

Download from Mac App Store or:
https://developer.apple.com/xcode/

### Step 2: Build the App

```bash
cd mobile_app
./build_ios.sh
```

Choose build type:
1. **Development** - Test on your device
2. **Ad-Hoc** - TestFlight distribution
3. **App Store** - App Store submission

### Step 3: Run on Your iPhone

**Option A: Using Flutter**
```bash
# Connect your iPhone
flutter devices

# Run on device
flutter run -d <device-id>
```

**Option B: Using Xcode**
```bash
# Open project
open ios/Runner.xcworkspace

# In Xcode:
# 1. Connect your iPhone
# 2. Select your device from dropdown
# 3. Click Run (▶) button
```

## 🎨 Add Custom App Icon

### Quick Icon Setup

```bash
./setup_ios_icons.sh /path/to/your/logo.png
```

**Requirements:**
- 1024x1024 pixels minimum
- Square (1:1 aspect ratio)
- PNG format
- NO transparency
- Simple design

This generates all required sizes:
- 20x20, 29x29, 40x40, 60x60 (iPhone)
- 76x76, 83.5x83.5 (iPad)
- 1024x1024 (App Store)

### Manual Icon Setup

1. Create 1024x1024 icon
2. Open Xcode: `open ios/Runner.xcworkspace`
3. Click `Runner` → `Assets.xcassets` → `AppIcon`
4. Drag your icon to the 1024x1024 slot
5. Xcode auto-generates other sizes

## 🔐 Code Signing Setup

### For Free Apple Account

1. Open Xcode: `open ios/Runner.xcworkspace`
2. Select **Runner** target
3. Go to **Signing & Capabilities**
4. Check **Automatically manage signing**
5. Select your **Team** (your Apple ID)
6. Xcode creates a free provisioning profile

**Limitations:**
- Apps expire after 7 days
- Must rebuild and reinstall weekly
- No TestFlight or App Store

### For Paid Developer Account

1. Go to: https://developer.apple.com/account
2. Create **App ID**: `com.shadrack.attendanceai`
3. Create **Provisioning Profile**
4. Download and install certificates
5. In Xcode, select your team and profile

## 📦 Distribution Options

### 1. Development Build (Testing)

```bash
./build_ios.sh
# Select option 1
```

Install on your device via Xcode or Flutter.

### 2. TestFlight (Beta Testing)

```bash
./build_ios.sh
# Select option 2 (Ad-Hoc)
```

Upload to TestFlight:
1. Go to: https://appstoreconnect.apple.com
2. Create app in App Store Connect
3. Upload IPA using **Transporter** app
4. Invite beta testers (up to 10,000)

### 3. App Store Release

```bash
./build_ios.sh
# Select option 3 (App Store)
```

Submit to App Store:
1. Upload IPA via Transporter
2. Fill app information in App Store Connect
3. Add screenshots (required sizes)
4. Submit for review
5. Wait 1-3 days for approval

## 📸 App Store Screenshots

Required sizes for iPhone:
- 6.7" (iPhone 14 Pro Max): 1290 x 2796
- 6.5" (iPhone 11 Pro Max): 1242 x 2688
- 5.5" (iPhone 8 Plus): 1242 x 2208

Required sizes for iPad:
- 12.9" (iPad Pro): 2048 x 2732
- 12.9" (iPad Pro 2nd gen): 2048 x 2732

**Tip:** Use iOS Simulator to capture screenshots:
```bash
# List simulators
xcrun simctl list devices

# Boot simulator
xcrun simctl boot "iPhone 14 Pro Max"

# Open simulator
open -a Simulator

# Run app
flutter run -d <simulator-id>

# Take screenshot: Cmd+S in Simulator
```

## 🔧 Customization

### Change App Name

Edit `ios/Runner/Info.plist`:
```xml
<key>CFBundleDisplayName</key>
<string>Your App Name</string>
```

### Change Bundle Identifier

1. Open: `open ios/Runner.xcworkspace`
2. Select **Runner** target
3. Go to **General** tab
4. Change **Bundle Identifier**

**Format:** `com.yourcompany.yourapp`

### Change Version

Edit `pubspec.yaml`:
```yaml
version: 1.0.0+1
```

- `1.0.0` = Version number (shown to users)
- `+1` = Build number (internal)

### Add Permissions

Edit `ios/Runner/Info.plist` to add:

**Camera permission:**
```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access for face recognition</string>
```

**Photo library:**
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>We need photo access to select images</string>
```

**Location:**
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need location for attendance tracking</string>
```

## 🎯 App Store Submission Checklist

- [ ] App icon (1024x1024)
- [ ] Screenshots (all required sizes)
- [ ] App description
- [ ] Keywords
- [ ] Privacy policy URL
- [ ] Support URL
- [ ] App category
- [ ] Age rating
- [ ] Pricing (free or paid)
- [ ] Export compliance
- [ ] Test on real devices
- [ ] No crashes or bugs
- [ ] Follows Apple guidelines

## 🐛 Troubleshooting

### "No provisioning profile found"

**Solution:**
1. Open Xcode: `open ios/Runner.xcworkspace`
2. Select Runner target
3. Signing & Capabilities
4. Enable "Automatically manage signing"
5. Select your team

### "Untrusted Developer"

On your iPhone:
1. Settings → General → VPN & Device Management
2. Tap your developer name
3. Tap "Trust"

### "App installation failed"

```bash
# Clean and rebuild
flutter clean
rm -rf ios/Pods
./build_ios.sh
```

### CocoaPods errors

```bash
# Update CocoaPods
sudo gem install cocoapods

# Clean pods
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
```

### Xcode build errors

```bash
# Clean Xcode build
cd ios
xcodebuild clean
cd ..

# Rebuild
flutter clean
./build_ios.sh
```

## 📱 Device Testing

### Connect iPhone

1. Connect via USB
2. Trust computer on iPhone
3. Check connection:
```bash
flutter devices
```

### Run on device

```bash
flutter run -d <device-id>
```

### View logs

```bash
flutter logs
```

## 🌟 Advanced Features

### Push Notifications

1. Enable in Xcode: Signing & Capabilities → + Capability → Push Notifications
2. Add Firebase or APNs configuration
3. Request permission in app

### Background Modes

Enable in Xcode: Signing & Capabilities → + Capability → Background Modes

Options:
- Background fetch
- Remote notifications
- Location updates

### App Groups

For sharing data between app and extensions:
1. Signing & Capabilities → + Capability → App Groups
2. Create group: `group.com.shadrack.attendanceai`

## 📚 Resources

- [Apple Developer](https://developer.apple.com)
- [App Store Connect](https://appstoreconnect.apple.com)
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/ios)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

## 🎉 Quick Commands

```bash
# Build for testing
./build_ios.sh

# Setup icons
./setup_ios_icons.sh /path/to/icon.png

# Open in Xcode
open ios/Runner.xcworkspace

# Run on device
flutter run -d <device-id>

# Build IPA for App Store
flutter build ipa --release

# Clean everything
flutter clean && rm -rf ios/Pods
```

## 💡 Tips

1. **Test on real devices** - Simulator doesn't show real performance
2. **Use TestFlight** - Get feedback before App Store release
3. **Follow guidelines** - Read Apple's review guidelines carefully
4. **Optimize size** - Keep app under 200MB for cellular downloads
5. **Support latest iOS** - Test on newest iOS version
6. **Handle permissions** - Always explain why you need permissions
7. **Offline mode** - App should work without internet when possible

Need help? Check Apple Developer Forums or Flutter documentation!
