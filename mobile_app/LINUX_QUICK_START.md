# Linux Desktop App - Quick Start

## ✅ Already Configured

- **App Name**: AttendanceAI
- **Executable**: `attendanceai`
- **Window Title**: AttendanceAI - Smart Face Recognition

## 🚀 Build in 3 Steps

### 1. Install Dependencies
```bash
sudo apt-get update
sudo apt-get install -y libgtk-3-dev libglib2.0-dev
```

### 2. Build
```bash
cd mobile_app
./build_linux.sh
```

### 3. Run
```bash
./build/linux/x64/release/bundle/attendanceai
```

## 📦 Install System-Wide

```bash
sudo ./install_linux.sh
```

Then launch from application menu or run: `attendanceai`

## 🎨 Add Custom Icon (Optional)

```bash
./setup_linux_icons.sh /path/to/your/logo.png
```

Then rebuild and reinstall.

## 📤 Distribute

### Portable Archive
```bash
cd build/linux/x64/release
tar -czf AttendanceAI-Linux-x64-v1.0.0.tar.gz bundle/
```

Users extract and run `./bundle/attendanceai`

## 🔧 Uninstall

```bash
sudo ./uninstall_linux.sh
```

## 📚 Full Guide

See `LINUX_DESKTOP_GUIDE.md` for detailed instructions.
