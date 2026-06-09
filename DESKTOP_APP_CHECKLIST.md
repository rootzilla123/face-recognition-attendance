# Desktop App Development - Master Checklist

## ✅ Everything You Need - Master Checklist

Use this checklist to track your progress from start to finish.

---

## 📚 Phase 1: Documentation & Understanding (2 hours)

### Reading
- [ ] Read `DESKTOP_APP_SUMMARY.md` (10 min)
- [ ] Read `DESKTOP_APP_QUICK_START.md` (15 min)
- [ ] Skim `WINDOWS_DESKTOP_APP_SETUP.md` (5 min)
- [ ] Bookmark `DESKTOP_BUILD_COMMANDS.md`
- [ ] Understand the workflow

### Understanding
- [ ] Understand: Same code, multiple platforms
- [ ] Understand: lib/ folder vs platform folders
- [ ] Understand: Dev machine → Windows flow
- [ ] Understand: Build = Flutter build windows --release
- [ ] Understand: One codebase to maintain

**Time**: 30 minutes
**Status**: ☐ Complete

---

## 🖥️ Phase 2: Dev Machine Setup (1 hour)

### On Your Dev Machine (Linux/Mac)

**Check Flutter**
- [ ] `flutter --version` shows version
- [ ] `flutter doctor` shows no critical errors
- [ ] You can build for Linux/Android (optional test)

**Enable Windows Desktop**
- [ ] Run: `flutter config --enable-windows-desktop`
- [ ] Verify: `flutter config --list | grep windows`
- [ ] Verify output: `enable-windows-desktop: true`

**Prepare Code**
- [ ] Code is committed to Git
- [ ] Run: `git push origin main`
- [ ] Verify: Code is on GitHub/GitLab

**Verification**
- [ ] Can access code from Windows machine via Git
- [ ] All team members have access
- [ ] Ready to push future changes

**Time**: 15-20 minutes
**Status**: ☐ Complete

---

## 🪟 Phase 3: Windows Machine Setup (1.5 hours)

### Install Visual Studio 2022 Community

- [ ] Download from: https://visualstudio.microsoft.com/vs/community/
- [ ] Run installer
- [ ] Select: "Desktop development with C++"
- [ ] Install (takes 10-15 minutes)
- [ ] Restart Windows
- [ ] Verify: `cl.exe` works in PowerShell

**Time**: 15 minutes
**Status**: ☐ Complete

### Install Flutter SDK

- [ ] Download Flutter for Windows
- [ ] Extract to: `C:\src\flutter`
- [ ] Add `C:\src\flutter\bin` to PATH
  - [ ] Right-click This PC → Properties
  - [ ] Advanced system settings
  - [ ] Environment Variables
  - [ ] New variable: `C:\src\flutter\bin`
  - [ ] Click OK
  - [ ] **Restart PowerShell**
- [ ] Verify: `flutter --version` works
- [ ] Verify: `flutter doctor` shows no errors

**Time**: 15-20 minutes
**Status**: ☐ Complete

### Verify Installation

- [ ] Open PowerShell
- [ ] Run: `flutter doctor`
- [ ] Check:
  - [ ] ✓ Flutter
  - [ ] ✓ Windows Version
  - [ ] ✓ Visual Studio (full)
  - [ ] ✓ Windows PowerShell

**Time**: 5 minutes
**Status**: ☐ Complete

---

## 📦 Phase 4: Get Project to Windows (30 minutes)

### Clone from Git

- [ ] Open PowerShell
- [ ] Create directory: `C:\Projects` (or your preference)
- [ ] Clone: `git clone https://github.com/YOUR_REPO/face-recognition-attendance.git`
- [ ] Navigate to project: `cd C:\Projects\face-recognition-attendance\mobile_app`
- [ ] Verify project files are there

**OR**

### Transfer via USB/Network

- [ ] Get mobile_app folder from dev machine
- [ ] Extract to: `C:\Projects\face-recognition-attendance\mobile_app`
- [ ] Verify project files are there

**Verification**
- [ ] `ls` or `dir` shows: `lib/`, `android/`, `ios/`, `windows/`, `pubspec.yaml`
- [ ] All files present
- [ ] No corrupted files

**Time**: 10-20 minutes
**Status**: ☐ Complete

---

## 🔨 Phase 5: Build Windows App (15 minutes)

### Initial Build

```cmd
cd C:\Projects\face-recognition-attendance\mobile_app
```

- [ ] **Step 1**: `flutter clean` (10 seconds)
- [ ] **Step 2**: `flutter pub get` (1-2 minutes)
  - [ ] Wait for "Got dependencies"
  - [ ] No errors shown
- [ ] **Step 3**: `flutter build windows --release` (3-5 minutes)
  - [ ] Watch for build progress
  - [ ] Wait for "Build complete!"
  - [ ] No errors in output

### Verify Build Output

- [ ] Navigate to: `build\windows\x64\runner\Release\`
- [ ] Check for:
  - [ ] `AttendanceAI.exe` exists
  - [ ] File size ~100-150 MB
  - [ ] Other .dll files present
  - [ ] `data/` folder exists

**Time**: 10-15 minutes (first time), 2-3 minutes (subsequent)
**Status**: ☐ Complete

---

## ▶️ Phase 6: Run & Test App (10 minutes)

### Run the App

**Method 1: File Explorer (Easiest)**
- [ ] Open File Explorer
- [ ] Navigate to: `build\windows\x64\runner\Release\`
- [ ] Double-click: `AttendanceAI.exe`
- [ ] App window opens

**OR**

**Method 2: Command Line**
```cmd
cd build\windows\x64\runner\Release
.\AttendanceAI.exe
```

**OR**

**Method 3: Debug Mode**
```cmd
# In mobile_app folder
flutter run -d windows
```

### Test Checklist

**Launch**
- [ ] App starts without error
- [ ] No crash on startup
- [ ] Console shows no errors (if debug mode)

**Window**
- [ ] Window opens with expected title
- [ ] Window size reasonable (1280x720 or similar)
- [ ] Can resize window

**UI**
- [ ] Screens visible
- [ ] Text readable
- [ ] Colors display correctly
- [ ] Dark theme shows properly

**Navigation**
- [ ] Can click buttons
- [ ] Menu/navigation works
- [ ] Can switch between screens
- [ ] No freezing

**Input**
- [ ] Can type in text fields
- [ ] Can click buttons with mouse
- [ ] Keyboard input works

**Backend Connectivity** (if needed)
- [ ] API requests work
- [ ] Data displays correctly
- [ ] No "cannot reach server" errors

**Performance**
- [ ] No lag when scrolling
- [ ] Animations smooth
- [ ] Buttons respond quickly

**Time**: 5-10 minutes
**Status**: ☐ Complete

---

## 🔄 Phase 7: Development Workflow (Ongoing)

### For Each Code Change

**On Dev Machine**
- [ ] Make code changes in `lib/` folder
- [ ] Test locally (optional): `flutter run -d linux`
- [ ] Verify no errors
- [ ] Commit changes: `git commit -m "Description"`
- [ ] Push changes: `git push origin main`

**On Windows Machine**
- [ ] Pull latest: `git pull origin main`
- [ ] Clean build: `flutter clean`
- [ ] Get dependencies: `flutter pub get`
- [ ] Build: `flutter build windows --release`
- [ ] Test: Run the app
- [ ] Report any bugs back

**Iteration**
- [ ] If bug found, report to dev machine
- [ ] Dev machine fixes it
- [ ] Repeat build and test
- [ ] Continue until satisfied

**Time**: Per iteration varies (5-40 minutes)
**Status**: ☐ Complete (after first iteration)

---

## 🐛 Phase 8: Debugging (As Needed)

### If Build Fails

- [ ] Check error message carefully
- [ ] Try: `flutter clean`
- [ ] Try: `flutter pub get`
- [ ] Try: `flutter build windows --release --verbose`
- [ ] Check Visual Studio is installed correctly
- [ ] Reference: `WINDOWS_DESKTOP_APP_SETUP.md` troubleshooting

**Status**: ☐ Complete

### If App Crashes

- [ ] Run in debug mode: `flutter run -d windows`
- [ ] Check console output for error messages
- [ ] Look for specific error
- [ ] Report to dev machine for fixing
- [ ] Rebuild after fix

**Status**: ☐ Complete

### If API Connectivity Issues

- [ ] Check backend is running: `curl http://YOUR_DEV_IP:8001/api/v1/health`
- [ ] Verify IP address (use dev machine IP, not localhost)
- [ ] Update URL in code if needed
- [ ] Rebuild and test

**Status**: ☐ Complete

---

## 📦 Phase 9: Distribution (Optional)

### Create Portable ZIP

```cmd
cd C:\Projects\face-recognition-attendance\mobile_app\build\windows\x64\runner
Compress-Archive -Path Release -DestinationPath AttendanceAI-v1.0.0.zip
```

- [ ] ZIP file created
- [ ] ZIP contains entire Release folder
- [ ] ZIP size ~100-150 MB

**Status**: ☐ Complete

### Create Installer (Optional)

- [ ] Download Inno Setup: https://jrsoftware.org/isdl.php
- [ ] Create installer.iss script
- [ ] Compile in Inno Setup
- [ ] Get installer .exe
- [ ] Test on clean Windows VM

**Status**: ☐ Complete

---

## 🎯 Phase 10: Documentation & Knowledge Base

### Documentation

- [ ] Save command reference
- [ ] Document any custom API URLs
- [ ] Document build process
- [ ] Document troubleshooting steps used
- [ ] Create "how to build" guide for team

**Status**: ☐ Complete

### Team Knowledge

- [ ] Share these documents with team
- [ ] Explain workflow to team members
- [ ] Get feedback on process
- [ ] Document lessons learned

**Status**: ☐ Complete

---

## 🚀 Quick Status Summary

### Initial Setup (One-Time)
- [ ] Phase 1: Documentation (2 hours)
- [ ] Phase 2: Dev machine setup (1 hour)
- [ ] Phase 3: Windows machine setup (1.5 hours)
- [ ] Phase 4: Get project (30 minutes)
- [ ] Phase 5: Build app (15 minutes)
- [ ] Phase 6: Test app (10 minutes)

**Total Initial**: ~6 hours (can be parallelized)

### Per Iteration
- [ ] Dev machine: Make changes (5-30 min)
- [ ] Windows machine: Build & test (10 min)

**Total Per Iteration**: 15-40 minutes

---

## ✅ Success Criteria

### You're Ready When:
- [ ] App builds without errors
- [ ] App runs without crashing
- [ ] All screens display correctly
- [ ] Navigation works
- [ ] Buttons are clickable
- [ ] Backend connectivity working
- [ ] No console errors
- [ ] Performance is smooth

### You're Done When:
- [ ] Windows app feature-complete
- [ ] All tests passing
- [ ] Ready for users
- [ ] Can be easily updated
- [ ] Team understands process

---

## 📊 Progress Tracking

Use this to track your progress:

```
Week 1:
  ☐ Day 1: Setup documentation & dev machine
  ☐ Day 2: Setup Windows machine
  ☐ Day 2: Build first version
  ☐ Day 3: Test and fix issues
  ☐ Day 4: Iterate and improve

Week 2+:
  ☐ Daily: Make changes, build, test
  ☐ As needed: Debug and optimize
  ☐ When ready: Distribute to users
```

---

## 📝 Notes Section

### Things I Need To Remember:

```
Dev Machine IP: _____________________
Windows Computer IP: _____________________
Backend URL: _____________________
Git Repository: _____________________
Project Location: _____________________

Custom Configuration:
_________________________________________
_________________________________________
_________________________________________

Issues Encountered & Solutions:
_________________________________________
_________________________________________
_________________________________________

Team Members:
_________________________________________
_________________________________________
_________________________________________
```

---

## 🎉 Final Verification

Before declaring victory:

- [ ] App builds from scratch without errors
- [ ] App runs from fresh checkout
- [ ] All features working
- [ ] No crashes found
- [ ] Performance acceptable
- [ ] Tested on Windows 10 and Windows 11
- [ ] Documentation complete
- [ ] Team can reproduce build
- [ ] Ready for first users

**Overall Status**: ☐ COMPLETE & READY

---

## 🚀 Next: Deployment

Once complete:

- [ ] Create distribution package
- [ ] Share with first users
- [ ] Gather feedback
- [ ] Fix any issues
- [ ] Create public release
- [ ] Document for future updates

---

**Print this page and check off as you go!**

**Keep a copy handy while developing.**

**Good luck!** 🎉
