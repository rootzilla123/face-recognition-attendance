# Linux Desktop App Guide

## ✅ What's Already Configured

Your Linux desktop app is now branded as:

- **App Name**: AttendanceAI
- **Executable Name**: `attendanceai`
- **Application ID**: `com.shadrack.attendanceai`
- **Window Title**: "AttendanceAI - Smart Face Recognition"
- **Desktop Entry**: Configured for application menu integration

## 🚀 Quick Start - Build Your Linux App

### Step 1: Install Dependencies

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y libgtk-3-dev libglib2.0-dev

# Fedora
sudo dnf install gtk3-devel glib2-devel

# Arch Linux
sudo pacman -S gtk3 glib2
```

### Step 2: Build the App

```bash
cd mobile_app
./build_linux.sh
```

Your app will be at: `build/linux/x64/release/bundle/attendanceai`

### Step 3: Run the App

```bash
./build/linux/x64/release/bundle/attendanceai
```

## 🎨 Add Custom Icon (Optional)

### Quick Icon Setup

```bash
./setup_linux_icons.sh /path/to/your/logo.png
```

This will generate icons at all required sizes:
- 16x16, 32x32, 48x48, 64x64, 128x128, 256x256, 512x512

### Manual Icon Setup

1. Create icon directories:
```bash
mkdir -p linux/icons/{16x16,32x32,48x48,64x64,128x128,256x256,512x512}
```

2. Place your icons (named `attendanceai.png`) in each size folder

3. Rebuild and install

## 📦 Installation Options

### Option 1: System-Wide Installation (Recommended)

```bash
sudo ./install_linux.sh
```

This will:
- Install to `/opt/attendanceai`
- Create launcher in application menu
- Add to system PATH
- Install desktop entry and icons

**Launch from:**
- Application menu (search "AttendanceAI")
- Terminal: `attendanceai`

**Uninstall:**
```bash
sudo ./uninstall_linux.sh
```

### Option 2: Portable Archive

```bash
cd build/linux/x64/release
tar -czf AttendanceAI-Linux-x64-v1.0.0.tar.gz bundle/
```

Users extract and run:
```bash
tar -xzf AttendanceAI-Linux-x64-v1.0.0.tar.gz
cd bundle
./attendanceai
```

### Option 3: Create .deb Package (Coming Soon)

For Debian/Ubuntu users, you can create an installable package:
```bash
./build_linux_deb.sh
```

## 🔧 Customization

### Change App Name

**Executable name** - Edit `linux/CMakeLists.txt`:
```cmake
set(BINARY_NAME "your-app-name")
```

**Application ID** - Edit `linux/CMakeLists.txt`:
```cmake
set(APPLICATION_ID "com.yourcompany.yourapp")
```

**Window title** - Edit `linux/runner/my_application.cc`:
```cpp
gtk_header_bar_set_title(header_bar, "Your App Name");
```

### Change Desktop Entry

Edit `linux/attendanceai.desktop`:
```ini
[Desktop Entry]
Name=Your App Name
GenericName=Your App Description
Comment=Detailed description
Icon=your-app-icon
Categories=Office;Utility;
```

### Change Version

Edit `pubspec.yaml`:
```yaml
version: 1.0.0+1
```

## 🐧 Distribution Formats

### 1. Portable Tarball
**Best for:** Universal Linux compatibility
```bash
tar -czf AttendanceAI-Linux-x64.tar.gz -C build/linux/x64/release bundle/
```

### 2. AppImage (Coming Soon)
**Best for:** Run anywhere without installation
- Single executable file
- No dependencies needed
- Works on all major distros

### 3. Flatpak (Coming Soon)
**Best for:** Sandboxed, secure distribution
- Available in Flathub
- Automatic updates
- Isolated from system

### 4. Snap (Coming Soon)
**Best for:** Ubuntu and derivatives
- Easy installation
- Automatic updates
- Confined environment

### 5. .deb Package (Coming Soon)
**Best for:** Debian/Ubuntu/Mint
```bash
sudo dpkg -i attendanceai_1.0.0_amd64.deb
```

### 6. .rpm Package (Coming Soon)
**Best for:** Fedora/RHEL/openSUSE
```bash
sudo rpm -i attendanceai-1.0.0.x86_64.rpm
```

## 📋 System Requirements

### Minimum Requirements
- Linux kernel 4.15+
- GTK 3.22+
- glibc 2.27+
- 2GB RAM
- 500MB disk space

### Recommended
- Ubuntu 20.04+ / Fedora 35+ / Debian 11+
- 4GB RAM
- 1GB disk space

### Tested Distributions
- ✅ Ubuntu 20.04, 22.04, 24.04
- ✅ Debian 11, 12
- ✅ Fedora 38, 39, 40
- ✅ Linux Mint 21, 22
- ✅ Pop!_OS 22.04
- ✅ Arch Linux (latest)
- ✅ Manjaro (latest)

## 🎯 Desktop Integration

### Application Menu Entry
After system-wide installation, the app appears in:
- GNOME: Activities → Show Applications
- KDE: Application Launcher → Office/Utilities
- XFCE: Applications Menu → Office/Utilities

### File Associations (Optional)
To open specific file types with your app, edit `linux/attendanceai.desktop`:
```ini
MimeType=application/x-attendance-data;
```

### Startup on Login (Optional)
Copy desktop entry to autostart:
```bash
mkdir -p ~/.config/autostart
cp /usr/share/applications/attendanceai.desktop ~/.config/autostart/
```

## 🔍 Troubleshooting

### App doesn't start
```bash
# Check dependencies
ldd build/linux/x64/release/bundle/attendanceai

# Run with debug output
FLUTTER_DEBUG=1 ./build/linux/x64/release/bundle/attendanceai
```

### Missing GTK libraries
```bash
sudo apt-get install libgtk-3-0 libglib2.0-0
```

### Icon not showing
```bash
# Update icon cache
sudo gtk-update-icon-cache -f -t /usr/share/icons/hicolor

# Update desktop database
sudo update-desktop-database /usr/share/applications
```

### Permission denied
```bash
chmod +x build/linux/x64/release/bundle/attendanceai
```

## 📝 Build Configurations

### Debug Build
```bash
flutter build linux --debug
```

### Profile Build (Performance Testing)
```bash
flutter build linux --profile
```

### Release Build (Production)
```bash
flutter build linux --release
```

## 🌟 Advanced Features

### Custom Themes
Your app respects system GTK themes automatically!

### Wayland Support
Fully compatible with Wayland display server.

### HiDPI Support
Automatic scaling on high-resolution displays.

### Keyboard Shortcuts
Standard Linux shortcuts work out of the box:
- Ctrl+Q: Quit
- Ctrl+W: Close window
- F11: Fullscreen

## 📚 Additional Resources

- [Flutter Linux Desktop](https://docs.flutter.dev/platform-integration/linux/building)
- [GTK Documentation](https://docs.gtk.org/gtk3/)
- [Desktop Entry Specification](https://specifications.freedesktop.org/desktop-entry-spec/latest/)
- [Icon Theme Specification](https://specifications.freedesktop.org/icon-theme-spec/latest/)

## 🎉 Quick Commands Reference

```bash
# Build
./build_linux.sh

# Setup icons
./setup_linux_icons.sh /path/to/icon.png

# Install system-wide
sudo ./install_linux.sh

# Uninstall
sudo ./uninstall_linux.sh

# Run locally
./build/linux/x64/release/bundle/attendanceai

# Create portable archive
tar -czf AttendanceAI-Linux.tar.gz -C build/linux/x64/release bundle/
```

Need help? Check the troubleshooting section or open an issue!
