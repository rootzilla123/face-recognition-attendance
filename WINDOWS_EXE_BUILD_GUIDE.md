# Windows .EXE Build Guide - Using GitHub Actions

## 🎯 What This Does

GitHub Actions automatically builds your Flutter app into a **Windows .exe file** every time you push to GitHub.

**No Windows machine needed!** ✨

---

## 🚀 Quick Start

### Step 1: Fix Git Authentication

Your GitHub token might be expired. Create a new one:

1. Go to: https://github.com/settings/tokens
2. Click "Generate new token"
3. Select: "classic"
4. Give it these permissions:
   - `repo` (full control of private repositories)
   - `workflow` (actions)
5. Copy the token
6. In your terminal, set it:

```bash
git config --global credential.helper store
# Then when you git push, enter:
# Username: YOUR_USERNAME
# Password: YOUR_TOKEN (paste the new token)
```

### Step 2: Push Your Code

```bash
cd /home/rootzilla/face-recognition-attendance
git push origin main
```

This triggers the GitHub Actions workflow automatically!

---

## 📋 What GitHub Actions Does

When you push to `main`:

1. ✅ Checks out your code
2. ✅ Installs Flutter
3. ✅ Builds for Windows
4. ✅ Creates ZIP file
5. ✅ Uploads as artifact
6. ✅ You download the .exe!

**Time**: 10-15 minutes total

---

## 📥 Download Your .EXE

### After Build Completes:

1. Go to: https://github.com/calvinceoyugah2-del/face-recognition-attendance
2. Click "Actions" tab
3. Find the latest "Build Windows Desktop App" workflow
4. Click on it
5. Scroll down to "Artifacts"
6. Download "AttendanceAI-Windows"
7. Extract the ZIP
8. Run `AttendanceAI.exe`!

### Or Use GitHub CLI (Faster):

```bash
gh run list --workflow windows-build.yml --limit 1
# Copy the run ID, then:
gh run download RUN_ID -n AttendanceAI-Windows
```

---

## 🔄 Workflow File Location

The workflow is here:
```
.github/workflows/windows-build.yml
```

It's already created and committed!

---

## 📊 Status Check

### Check if Workflow Exists:

```bash
ls -la .github/workflows/
# Should show: windows-build.yml
```

### Check Git Status:

```bash
git status
# Should show everything committed
```

### Check Remote:

```bash
git log --oneline -5
# Should show your latest commits
```

---

## 🎯 Complete Workflow

```
1. Make code changes
   ↓
2. git add .
3. git commit -m "Description"
4. git push origin main
   ↓
5. GitHub Actions automatically builds
   ├─ Checks out code
   ├─ Installs Flutter
   ├─ Builds Windows app
   ├─ Creates ZIP with .exe
   └─ Uploads artifact
   ↓
6. Download from GitHub Actions
   ├─ Go to Actions tab
   ├─ Find workflow
   ├─ Download artifact
   └─ Extract and run AttendanceAI.exe
```

---

## 🧪 Test It Now

### First Time Setup:

1. **Fix GitHub token** (see Step 1 above)
2. **Push to GitHub**:
   ```bash
   git push origin main
   ```
3. **Wait 10-15 minutes** for build
4. **Go to Actions tab** to download

### Every Time After:

1. Make changes
2. `git add .`
3. `git commit -m "your message"`
4. `git push origin main`
5. Wait for GitHub Actions (10-15 min)
6. Download .exe from Actions tab

---

## 💡 What You Get

After download and extract:
```
AttendanceAI-Windows/
├── AttendanceAI.exe          ← DOUBLE-CLICK THIS!
├── flutter_windows.dll
├── data/
│   └── flutter_assets/
└── *.dll
```

Just double-click `AttendanceAI.exe` to run!

---

## ⚙️ Configure Build (Optional)

Edit `.github/workflows/windows-build.yml` to:

### Change Flutter Version
```yaml
flutter-version: '3.29.3'  # Change this
```

### Add Email Notifications
```yaml
- name: Notify on Success
  if: success()
  run: echo "Build succeeded!"
```

### Deploy to Release
```yaml
- name: Create Release
  if: startsWith(github.ref, 'refs/tags/')
  # Automatically creates release for tagged versions
```

---

## 🐛 Troubleshooting

### Build Failed?

1. Check the Actions log:
   - Go to Actions tab
   - Click the failed workflow
   - Scroll to see error

2. Common issues:
   - **"Flutter not found"** → Workflow file issue
   - **"Build failed"** → Code compilation error
   - **"Artifact not found"** → ZIP creation failed

### Can't Download Artifact?

1. Check if workflow completed
2. Go to Actions tab
3. Look for "AttendanceAI-Windows" under Artifacts
4. If not there, workflow is still running

### .EXE Won't Run?

1. You're on Windows (requirement!)
2. Extract full ZIP folder
3. Don't move just the .exe
4. Run `AttendanceAI.exe` with all DLLs present

---

## 📚 Resources

- **GitHub Actions Docs**: https://docs.github.com/en/actions
- **GitHub CLI**: https://cli.github.com/
- **Flutter Windows Build**: https://docs.flutter.dev/deployment/windows

---

## ✅ Success Checklist

- [ ] GitHub token created and configured
- [ ] Workflow file exists: `.github/workflows/windows-build.yml`
- [ ] Code pushed to main branch
- [ ] GitHub Actions triggered (check Actions tab)
- [ ] Build completed (10-15 minutes)
- [ ] Artifact downloaded
- [ ] ZIP extracted
- [ ] AttendanceAI.exe runs on Windows machine

---

## 🎉 You're Set Up!

Everything is ready. Just:

1. **Fix your GitHub token** (if needed)
2. **Push to GitHub** with `git push origin main`
3. **Wait** for GitHub Actions to build (10-15 min)
4. **Download** the .exe from Actions artifacts
5. **Run** on your Windows computer!

**That's it!** 🚀

---

## 🔗 Quick Links

- GitHub Repo: https://github.com/calvinceoyugah2-del/face-recognition-attendance
- Actions Tab: https://github.com/calvinceoyugah2-del/face-recognition-attendance/actions
- Workflow File: `.github/workflows/windows-build.yml`

---

## 💬 Next Steps

1. **Set up GitHub token** (Step 1 above)
2. **Run**: `git push origin main`
3. **Watch** Actions tab for build
4. **Download** when complete
5. **Test** on Windows!

Questions? Check the troubleshooting section above.
