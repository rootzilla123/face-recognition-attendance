# Mobile App - Local Testing & APK Build Guide

## Current Status

✅ **App is configured for production** (Cloudflare tunnel URLs)
✅ **Firebase integration ready**
✅ **Google Sign-In configured**
✅ **Push notifications ready** (needs FCM setup)

## Issues for Local Testing

### 🔴 Problem: App Points to Production URLs

The app is currently configured to use:
- API: `https://shadomfacepro.duckdns.org`
- PocketBase: `https://pb.shadomfacepro.duckdns.org`

For local testing, you need to change these to:
- API: `http://localhost:8001` or `http://YOUR_LOCAL_IP:8001`
- PocketBase: `http://localhost:8090` or `http://YOUR_LOCAL_IP:8090`

### ✅ Solution: Two Options

#### Option 1: Change URLs in Settings (Runtime)
The app has a Settings screen where you can change the server URLs without rebuilding.

#### Option 2: Change Default URLs (Build Time)
Edit `mobile_app/lib/core/utils/server_config.dart`:

```dart
// For local testing
static const defaultUrl = 'http://10.0.2.2:8001';  // Android emulator
// OR
static const defaultUrl = 'http://YOUR_LOCAL_IP:8001';  // Physical device

static const defaultPbUrl = 'http://10.0.2.2:8090';  // Android emulator
// OR
static const defaultPbUrl = 'http://YOUR_LOCAL_IP:8090';  // Physical device
```

**Note:** 
- `10.0.2.2` is the special IP for Android emulator to access host machine's localhost
- For physical devices, use your computer's local IP (e.g., `192.168.1.100`)

## Prerequisites

### 1. Install Flutter
```bash
# Check if Flutter is installed
flutter --version

# If not installed, download from: https://flutter.dev/docs/get-started/install
```

### 2. Install Android Studio
- Download from: https://developer.android.com/studio
- Install Android SDK
- Set up Android emulator or connect physical device

### 3. Check Flutter Doctor
```bash
cd mobile_app
flutter doctor
```

Fix any issues reported by `flutter doctor`.

## Local Testing Steps

### Step 1: Start Backend Services

```bash
# Start all services
./start_all.sh

# Or start individually
cd attendance-system
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8001

# In another terminal, start PocketBase
./pocketbase serve --http=0.0.0.0:8090
```

### Step 2: Get Your Local IP Address

```bash
# On Linux
ip addr show | grep "inet " | grep -v 127.0.0.1

# On macOS
ifconfig | grep "inet " | grep -v 127.0.0.1

# On Windows
ipconfig | findstr IPv4
```

Example output: `192.168.1.100`

### Step 3: Update App Configuration

**Option A: Use Settings Screen (Recommended)**
1. Run the app
2. Go to Settings
3. Change "Server URL" to `http://YOUR_LOCAL_IP:8001`
4. Change "PocketBase URL" to `http://YOUR_LOCAL_IP:8090`
5. Restart the app

**Option B: Edit Code**
Edit `mobile_app/lib/core/utils/server_config.dart`:
```dart
static const defaultUrl = 'http://192.168.1.100:8001';  // Your IP
static const defaultPbUrl = 'http://192.168.1.100:8090';  // Your IP
```

### Step 4: Run the App

```bash
cd mobile_app

# Get dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Or run in debug mode with hot reload
flutter run --debug
```

### Step 5: Test Key Features

1. **Login/Register**
   - Test email/password login
   - Test Google Sign-In
   
2. **Attendance**
   - View today's attendance
   - Check attendance history
   
3. **Notifications**
   - Check in-app notifications
   - Test notification preferences
   
4. **Camera Streams**
   - View live camera feeds
   - Check MJPEG streaming
   
5. **Reports**
   - Generate attendance reports
   - Export to PDF

## Building APK

### For Testing (Debug APK)

```bash
cd mobile_app

# Build debug APK
flutter build apk --debug

# Output: build/app/outputs/flutter-apk/app-debug.apk
```

### For Production (Release APK)

#### Step 1: Revert to Production URLs

Edit `mobile_app/lib/core/utils/server_config.dart`:
```dart
static const defaultUrl = 'https://shadomfacepro.duckdns.org';
static const defaultPbUrl = 'https://pb.shadomfacepro.duckdns.org';
```

#### Step 2: Update Version

Edit `mobile_app/pubspec.yaml`:
```yaml
version: 1.0.0+1  # Change to 1.0.1+2, 1.1.0+3, etc.
```

#### Step 3: Generate Signing Key (First Time Only)

```bash
# Generate keystore
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload

# You'll be prompted for:
# - Keystore password (remember this!)
# - Key password (remember this!)
# - Your name, organization, etc.
```

#### Step 4: Configure Signing

Create `mobile_app/android/key.properties`:
```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=/home/YOUR_USERNAME/upload-keystore.jks
```

**⚠️ IMPORTANT:** Add to `.gitignore`:
```bash
echo "android/key.properties" >> mobile_app/.gitignore
echo "*.jks" >> .gitignore
```

Edit `mobile_app/android/app/build.gradle.kts`:

Add before `android {`:
```kotlin
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```

Update `signingConfigs` inside `android {`:
```kotlin
signingConfigs {
    create("release") {
        keyAlias = keystoreProperties["keyAlias"] as String
        keyPassword = keystoreProperties["keyPassword"] as String
        storeFile = file(keystoreProperties["storeFile"] as String)
        storePassword = keystoreProperties["storePassword"] as String
    }
}

buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
        isMinifyEnabled = true
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
        )
    }
}
```

#### Step 5: Build Release APK

```bash
cd mobile_app

# Clean previous builds
flutter clean
flutter pub get

# Build release APK
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk
```

#### Step 6: Build App Bundle (for Play Store)

```bash
# Build app bundle
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

## APK Locations

After building, APKs are located at:
- **Debug**: `mobile_app/build/app/outputs/flutter-apk/app-debug.apk`
- **Release**: `mobile_app/build/app/outputs/flutter-apk/app-release.apk`
- **Bundle**: `mobile_app/build/app/outputs/bundle/release/app-release.aab`

## Installing APK

### On Physical Device

```bash
# Via ADB
adb install mobile_app/build/app/outputs/flutter-apk/app-release.apk

# Or copy APK to device and install manually
```

### On Emulator

```bash
# Drag and drop APK onto emulator
# Or use ADB
adb -e install mobile_app/build/app/outputs/flutter-apk/app-release.apk
```

## Troubleshooting

### Issue: "Unable to connect to server"

**Solution:**
1. Check backend is running: `curl http://localhost:8001/api/v1/health`
2. Check PocketBase is running: `curl http://localhost:8090/api/health`
3. Verify URLs in app settings
4. For physical device, ensure device and computer are on same network
5. Check firewall isn't blocking ports 8001 and 8090

### Issue: "Google Sign-In failed"

**Solution:**
1. Ensure `google-services.json` is in `mobile_app/android/app/`
2. Check Firebase project configuration
3. Add SHA-1 fingerprint to Firebase console:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```

### Issue: "Push notifications not working"

**Solution:**
1. Ensure Firebase Cloud Messaging is enabled in Firebase console
2. Check `google-services.json` is up to date
3. Request notification permissions in app
4. Register device token after login

### Issue: "Camera streams not loading"

**Solution:**
1. Check cameras are online: `curl http://localhost:8001/api/v1/cameras`
2. Verify MJPEG stream URLs
3. Check network connectivity
4. Try refreshing the stream

### Issue: "Build failed"

**Solution:**
```bash
# Clean and rebuild
cd mobile_app
flutter clean
flutter pub get
flutter pub upgrade
flutter build apk --release
```

## Testing Checklist

Before releasing APK:

- [ ] Test on Android emulator
- [ ] Test on physical device
- [ ] Test login/register
- [ ] Test Google Sign-In
- [ ] Test attendance viewing
- [ ] Test notifications
- [ ] Test camera streams
- [ ] Test reports generation
- [ ] Test offline mode (if applicable)
- [ ] Test push notifications
- [ ] Test app version enforcement
- [ ] Verify production URLs
- [ ] Check app permissions
- [ ] Test on different Android versions (API 23+)

## App Permissions

The app requires these permissions (already configured in `AndroidManifest.xml`):

- `INTERNET` - API calls
- `CAMERA` - Profile photo upload
- `READ_EXTERNAL_STORAGE` - Image picker
- `WRITE_EXTERNAL_STORAGE` - Save reports
- `RECEIVE_BOOT_COMPLETED` - Notifications
- `VIBRATE` - Notification alerts
- `POST_NOTIFICATIONS` - Push notifications (Android 13+)

## Performance Optimization

For production builds:

1. **Enable Obfuscation**:
   ```bash
   flutter build apk --release --obfuscate --split-debug-info=build/debug-info
   ```

2. **Split APKs by ABI** (smaller file size):
   ```bash
   flutter build apk --release --split-per-abi
   ```
   This creates separate APKs for arm64-v8a, armeabi-v7a, x86_64

3. **Analyze APK Size**:
   ```bash
   flutter build apk --release --analyze-size
   ```

## Distribution

### Option 1: Direct APK Distribution
- Share `app-release.apk` directly
- Users enable "Install from Unknown Sources"
- Install APK manually

### Option 2: Google Play Store
1. Create Google Play Developer account ($25 one-time fee)
2. Upload `app-release.aab` (not APK)
3. Fill in store listing details
4. Submit for review

### Option 3: Internal Testing
1. Use Firebase App Distribution
2. Upload APK to Firebase console
3. Invite testers via email
4. Testers download via Firebase App Tester app

## Next Steps

1. **Test locally** with debug APK
2. **Fix any issues** found during testing
3. **Build release APK** with production URLs
4. **Test release APK** on multiple devices
5. **Distribute** via chosen method

## Support

For issues:
1. Check Flutter logs: `flutter logs`
2. Check Android logs: `adb logcat`
3. Check backend logs: `docker logs backend`
4. Review error messages in app
