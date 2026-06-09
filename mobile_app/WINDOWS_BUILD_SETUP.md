# Windows Build Setup Guide

## 🎯 Current Status

✅ **Branding configured** - Your app is ready to build as "AttendanceAI"
✅ **Build scripts ready** - `build_windows.sh` is configured
✅ **Icon setup ready** - `update_windows_icon.sh` for custom icons

## 🖥️ Building on Windows

### Option 1: Native Windows

**Requirements:**
- Windows 10/11 (64-bit)
- Flutter SDK installed
- Visual Studio 2022 or Build Tools

**Steps:**

1. **Install Flutter on Windows**
   - Download: https://docs.flutter.dev/get-started/install/windows
   - Extract to `C:\flutter`
   - Add to PATH: `C:\flutter\bin`

2. **Install Visual Studio 2022**
   - Download: https://visualstudio.microsoft.com/downloads/
   - Install "Desktop development with C++" workload
   - Or install Build Tools only

3. **Enable Windows Desktop**
   ```cmd
   flutter config --enable-windows-desktop
   flutter doctor
   ```

4. **Transfer your project to Windows**
   - Copy entire `mobile_app` folder
   - Or use Git to clone

5. **Build**
   ```cmd
   cd mobile_app
   flutter clean
   flutter pub get
   flutter build windows --release
   ```

6. **Output**
   ```
   build\windows\x64\runner\Release\AttendanceAI.exe
   ```

### Option 2: WSL (Windows Subsystem for Linux)

**Note:** WSL can run the build script but requires Windows Flutter SDK.

1. **Install WSL2**
   ```powershell
   wsl --install
   ```

2. **Install Flutter in WSL**
   ```bash
   sudo snap install flutter --classic
   flutter config --enable-windows-desktop
   ```

3. **Run build script**
   ```bash
   cd mobile_app
   ./build_windows.sh
   ```

## 📦 What You'll Get

After building on Windows:

```
build/windows/x64/runner/Release/
├── AttendanceAI.exe          # Your branded app
├── flutter_windows.dll       # Flutter runtime
├── data/                     # App assets
│   ├── icudtl.dat
│   └── flutter_assets/
└── *.dll                     # Other dependencies
```

**Size:** ~80-150 MB

## 🎨 Custom Icon (Before Building)

1. **Prepare your icon**
   - 1024x1024 PNG
   - Square, simple design

2. **Convert to .ico**
   - Online: https://convertio.co/png-ico/
   - Select sizes: 16, 32, 48, 64, 128, 256

3. **Replace icon**
   ```
   mobile_app/windows/runner/resources/app_icon.ico
   ```

4. **Rebuild**
   ```cmd
   flutter clean
   flutter build windows --release
   ```

## 🚀 Distribution

### Portable Version (Easiest)

1. **Zip the Release folder**
   ```cmd
   cd build\windows\x64\runner
   tar -a -c -f AttendanceAI-Windows-v1.0.0.zip Release
   ```

2. **Share the ZIP**
   - Users extract and run `AttendanceAI.exe`
   - No installation needed
   - Works on any Windows 10/11

### Installer (Professional)

**Using Inno Setup:**

1. **Install Inno Setup**
   - Download: https://jrsoftware.org/isdl.php

2. **Create installer script** (`installer.iss`):
   ```iss
   [Setup]
   AppName=AttendanceAI
   AppVersion=1.0.0
   DefaultDirName={pf}\AttendanceAI
   DefaultGroupName=AttendanceAI
   OutputDir=installer
   OutputBaseFilename=AttendanceAI-Setup-v1.0.0
   
   [Files]
   Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs
   
   [Icons]
   Name: "{group}\AttendanceAI"; Filename: "{app}\AttendanceAI.exe"
   Name: "{commondesktop}\AttendanceAI"; Filename: "{app}\AttendanceAI.exe"
   ```

3. **Compile**
   - Open `installer.iss` in Inno Setup
   - Click "Compile"
   - Get `AttendanceAI-Setup-v1.0.0.exe`

## 🔧 Troubleshooting

### "Flutter not found"
```cmd
where flutter
# Should show: C:\flutter\bin\flutter.bat
```

### "Visual Studio not found"
```cmd
flutter doctor -v
# Check for Visual Studio 2022
```

### "Build failed"
```cmd
flutter clean
flutter pub get
flutter build windows --release --verbose
```

### "Missing DLLs"
- All DLLs are in the Release folder
- Distribute the entire Release folder
- Don't move just the .exe

## 📋 Build Checklist

- [ ] Flutter installed on Windows
- [ ] Visual Studio 2022 installed
- [ ] `flutter doctor` shows no errors
- [ ] Custom icon added (optional)
- [ ] Configuration set to production
- [ ] Build completed successfully
- [ ] Tested on clean Windows machine
- [ ] Created distribution package

## 🌐 Remote Build Options

If you don't have Windows access:

### GitHub Actions (Free CI/CD)

Create `.github/workflows/windows-build.yml`:

```yaml
name: Windows Build

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build:
    runs-on: windows-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.29.3'
        channel: 'stable'
    
    - name: Enable Windows Desktop
      run: flutter config --enable-windows-desktop
    
    - name: Get dependencies
      run: flutter pub get
      working-directory: mobile_app
    
    - name: Build Windows
      run: flutter build windows --release
      working-directory: mobile_app
    
    - name: Create ZIP
      run: |
        cd mobile_app/build/windows/x64/runner
        Compress-Archive -Path Release -DestinationPath AttendanceAI-Windows.zip
    
    - name: Upload artifact
      uses: actions/upload-artifact@v3
      with:
        name: windows-build
        path: mobile_app/build/windows/x64/runner/AttendanceAI-Windows.zip
```

Push to GitHub and download the built app from Actions tab!

### AppVeyor (Alternative CI)

Free for open source projects: https://www.appveyor.com/

## 💡 Quick Tips

1. **Test on clean Windows** - Install on a fresh Windows VM to ensure all dependencies are included

2. **Code signing** (optional) - Sign your .exe for better trust:
   - Get code signing certificate
   - Use `signtool.exe` from Windows SDK

3. **Auto-updates** - Consider adding update checking:
   - Host new versions on GitHub Releases
   - Check version on app startup

4. **Antivirus** - Some antivirus may flag unsigned .exe:
   - Code signing helps
   - Submit to antivirus vendors for whitelisting

5. **Size optimization**:
   - Release build is already optimized
   - Consider UPX compression (use carefully)

## 📚 Resources

- [Flutter Windows Desktop](https://docs.flutter.dev/platform-integration/windows/building)
- [Visual Studio Downloads](https://visualstudio.microsoft.com/downloads/)
- [Inno Setup](https://jrsoftware.org/isinfo.php)
- [Windows Code Signing](https://docs.microsoft.com/en-us/windows/win32/seccrypto/cryptography-tools)

## 🎉 Summary

**To build on Windows:**
```cmd
# One-time setup
flutter config --enable-windows-desktop

# Build
cd mobile_app
flutter build windows --release

# Output
build\windows\x64\runner\Release\AttendanceAI.exe
```

**To distribute:**
- ZIP the Release folder
- Or create installer with Inno Setup
- Share with users!

Your Windows app is ready to build! 🚀
