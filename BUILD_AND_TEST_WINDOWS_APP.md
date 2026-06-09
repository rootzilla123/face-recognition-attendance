# Build and Test Windows App - Quick Start

## What You Need to Know

Your Flutter mobile app automatically builds into a **Windows .exe file** via GitHub Actions.

**You don't need a Windows machine.** GitHub builds it in the cloud. ☁️

---

## Build Your .EXE

### Step 1: Make Changes (Optional)

Edit your mobile_app code, then:

```bash
git add .
git commit -m "your changes"
git push origin main
```

### Step 2: GitHub Actions Builds Automatically

Once you push to main, GitHub Actions:
- ✅ Checks out your code
- ✅ Installs Flutter
- ✅ Builds Windows app
- ✅ Creates ZIP with .exe
- ✅ Uploads artifact

**Time to build**: 10-15 minutes

### Step 3: Download Your .EXE

1. Go to: https://github.com/rootzilla123/face-recognition-attendance
2. Click **"Actions"** tab
3. Click latest **"Build Windows Desktop App"** workflow
4. Scroll to **"Artifacts"** section
5. Download **"AttendanceAI-Windows"**
6. Extract the ZIP

---

## Run the App on Windows

1. Extract `AttendanceAI-Windows.zip`
2. Open the folder
3. **Double-click `AttendanceAI.exe`** to run!

That's it! The app will launch.

---

## What's Inside the ZIP

```
AttendanceAI-Windows/
├── AttendanceAI.exe          ← RUN THIS
├── flutter_windows.dll
├── data/
│   └── flutter_assets/       ← App assets
└── *.dll                      ← Required libraries
```

All files must stay together. Don't move just the .exe.

---

## Workflow Location

```
Repository: https://github.com/rootzilla123/face-recognition-attendance
Workflow: .github/workflows/windows-build.yml
```

---

## If Build Fails

1. Check the Actions log:
   - Actions tab → Failed workflow → See error message
   
2. Common issues:
   - **"Flutter not found"** → Workflow syntax issue
   - **"Build failed"** → Code has compilation error
   - **"No artifact"** → ZIP creation failed

Fix the issue, commit, and push again to retry.

---

## Every Time You Want to Build

```
1. Make changes to mobile_app/
2. git add .
3. git commit -m "description"
4. git push origin main
5. Wait 10-15 minutes
6. Download artifact from Actions
7. Extract and run AttendanceAI.exe
```

---

## Pro Tips

- **Faster downloads**: Use `gh run download` if GitHub CLI is installed
- **Release builds**: Tag a commit to auto-create GitHub Release with .exe
- **Multiple builds**: Each push creates a new artifact (keep last 30 days)
- **No GitHub login needed**: Just push and wait

---

## Resources

- **GitHub Actions**: https://docs.github.com/en/actions
- **Flutter Windows**: https://docs.flutter.dev/deployment/windows
- **Troubleshooting**: Check WINDOWS_EXE_BUILD_GUIDE.md

---

**Your Windows app is ready to build!** 🚀

Just push your changes and GitHub will handle the rest.

