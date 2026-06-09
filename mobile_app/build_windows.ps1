# Build Windows desktop app
# Usage: .\build_windows.ps1

Write-Host "════════════════════════════════════════" -ForegroundColor Blue
Write-Host "   AttendanceAI Windows Builder" -ForegroundColor Blue
Write-Host "════════════════════════════════════════" -ForegroundColor Blue
Write-Host ""

# Check Flutter
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "✗ Flutter not found! Please install Flutter first." -ForegroundColor Red
    Write-Host "  Download from: https://flutter.dev" -ForegroundColor Yellow
    exit 1
}

$flutterVersion = flutter --version | Select-String "Flutter" | Select-Object -First 1
Write-Host "✓ Flutter found: $flutterVersion" -ForegroundColor Green
Write-Host ""

# Check Windows desktop support
Write-Host "Checking Windows desktop support..." -ForegroundColor Yellow
flutter config --enable-windows-desktop | Out-Null
Write-Host "✓ Windows desktop enabled" -ForegroundColor Green
Write-Host ""

# Check configuration
Write-Host "Checking configuration..." -ForegroundColor Yellow
$configFile = "lib\core\utils\server_config.dart"
$configContent = Get-Content $configFile -Raw

if ($configContent -match "localhost|10\.0\.2\.2|192\.168") {
    Write-Host "⚠ WARNING: App is configured for LOCAL development!" -ForegroundColor Red
    Write-Host ""
    $response = Read-Host "Switch to PRODUCTION config? (y/n)"
    if ($response -eq "y") {
        .\configure_production.ps1
    } else {
        Write-Host "Building with LOCAL configuration..." -ForegroundColor Yellow
    }
} else {
    Write-Host "✓ Production configuration detected" -ForegroundColor Green
}
Write-Host ""

# Clean
Write-Host "Cleaning previous builds..." -ForegroundColor Yellow
flutter clean | Out-Null
Write-Host "✓ Clean complete" -ForegroundColor Green
Write-Host ""

# Get dependencies
Write-Host "Getting dependencies..." -ForegroundColor Yellow
flutter pub get | Out-Null
Write-Host "✓ Dependencies installed" -ForegroundColor Green
Write-Host ""

# Build
Write-Host "════════════════════════════════════════" -ForegroundColor Blue
Write-Host "Building Windows app (this may take a few minutes)..." -ForegroundColor Yellow
Write-Host "════════════════════════════════════════" -ForegroundColor Blue
Write-Host ""

flutter build windows --release

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "════════════════════════════════════════" -ForegroundColor Blue
    Write-Host "✓ Build successful!" -ForegroundColor Green
    Write-Host "════════════════════════════════════════" -ForegroundColor Blue
    Write-Host ""
    
    # Get build info
    $releaseFolder = "build\windows\x64\runner\Release"
    $exePath = "$releaseFolder\mobile_app.exe"
    
    if (Test-Path $exePath) {
        $exeSize = (Get-Item $exePath).Length / 1MB
        Write-Host "Executable: $exePath" -ForegroundColor White
        Write-Host "Size: $([math]::Round($exeSize, 2)) MB" -ForegroundColor White
        Write-Host ""
    }
    
    # Create distribution package
    $distFolder = "AttendanceAI-Windows"
    
    Write-Host "Creating distribution package..." -ForegroundColor Yellow
    
    if (Test-Path $distFolder) {
        Remove-Item -Recurse -Force $distFolder
    }
    
    New-Item -ItemType Directory -Path $distFolder | Out-Null
    Copy-Item -Recurse -Path "$releaseFolder\*" -Destination $distFolder
    
    # Rename executable
    if (Test-Path "$distFolder\mobile_app.exe") {
        Rename-Item -Path "$distFolder\mobile_app.exe" -NewName "AttendanceAI.exe"
    }
    
    # Create README
    $readme = @"
AttendanceAI - Face Recognition Attendance System
Windows Desktop Application

═══════════════════════════════════════════════════════════

INSTALLATION:
1. Extract all files to a folder (keep folder structure intact)
2. Double-click AttendanceAI.exe to run

REQUIREMENTS:
- Windows 10 or later (64-bit)
- Internet connection for cloud features
- 4GB RAM minimum, 8GB recommended
- 500MB free disk space

FIRST RUN:
1. Launch AttendanceAI.exe
2. Login with your credentials
3. Configure server URL in Settings (if needed)

FEATURES:
- View attendance records
- Monitor live camera feeds
- Generate reports and export to PDF
- Manage students and teachers
- Real-time notifications
- Multi-window support

TROUBLESHOOTING:
- If app doesn't start, install Visual C++ Redistributable:
  https://aka.ms/vs/17/release/vc_redist.x64.exe

- If "Unknown Publisher" warning appears, click "More info" 
  then "Run anyway" (app is safe, just not code-signed)

- For connection issues, check Settings > Server Configuration

SUPPORT:
- Website: https://shadomfacepro.duckdns.org
- Documentation: See WINDOWS_DESKTOP_APP_GUIDE.md

VERSION: 1.0.0
BUILD DATE: $(Get-Date -Format "yyyy-MM-dd HH:mm")

═══════════════════════════════════════════════════════════
"@
    
    Set-Content -Path "$distFolder\README.txt" -Value $readme
    
    # Create quick start guide
    $quickStart = @"
QUICK START GUIDE
═══════════════════════════════════════════════════════════

1. LAUNCH THE APP
   - Double-click AttendanceAI.exe
   
2. LOGIN
   - Use your email and password
   - Or sign in with Google
   
3. MAIN FEATURES
   - Dashboard: Overview of today's attendance
   - Attendance: View detailed records
   - Students: Manage student information
   - Reports: Generate and export reports
   - Cameras: Monitor live feeds
   - Settings: Configure app preferences

4. KEYBOARD SHORTCUTS
   - Ctrl+R: Refresh data
   - Ctrl+P: Print/Export report
   - Ctrl+S: Open settings
   - Ctrl+Q: Quit app
   - F5: Refresh current view
   - F11: Toggle fullscreen

5. TIPS
   - Keep the app running for real-time notifications
   - Use Settings to change server URL for local testing
   - Export reports regularly for backup
   - Check camera status in Cameras tab

═══════════════════════════════════════════════════════════
"@
    
    Set-Content -Path "$distFolder\QUICK_START.txt" -Value $quickStart
    
    Write-Host "✓ Distribution package created" -ForegroundColor Green
    Write-Host ""
    
    # Create ZIP
    Write-Host "Creating ZIP archive..." -ForegroundColor Yellow
    $zipPath = "AttendanceAI-Windows-v1.0.0.zip"
    
    if (Test-Path $zipPath) {
        Remove-Item $zipPath
    }
    
    Compress-Archive -Path "$distFolder\*" -DestinationPath $zipPath -Force
    
    $zipSize = (Get-Item $zipPath).Length / 1MB
    
    Write-Host "✓ ZIP archive created" -ForegroundColor Green
    Write-Host ""
    Write-Host "════════════════════════════════════════" -ForegroundColor Blue
    Write-Host "✓ Package complete!" -ForegroundColor Green
    Write-Host "════════════════════════════════════════" -ForegroundColor Blue
    Write-Host ""
    Write-Host "Output files:" -ForegroundColor Yellow
    Write-Host "  📁 $distFolder\ (folder)" -ForegroundColor White
    Write-Host "  📦 $zipPath ($([math]::Round($zipSize, 2)) MB)" -ForegroundColor White
    Write-Host ""
    Write-Host "To test:" -ForegroundColor Yellow
    Write-Host "  cd $distFolder" -ForegroundColor White
    Write-Host "  .\AttendanceAI.exe" -ForegroundColor White
    Write-Host ""
    Write-Host "To distribute:" -ForegroundColor Yellow
    Write-Host "  Share $zipPath with users" -ForegroundColor White
    Write-Host ""
    
} else {
    Write-Host ""
    Write-Host "════════════════════════════════════════" -ForegroundColor Blue
    Write-Host "✗ Build failed!" -ForegroundColor Red
    Write-Host "════════════════════════════════════════" -ForegroundColor Blue
    Write-Host ""
    Write-Host "Common issues:" -ForegroundColor Yellow
    Write-Host "  1. Visual Studio not installed" -ForegroundColor White
    Write-Host "     Solution: Install Visual Studio 2022 or Build Tools" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  2. Windows SDK missing" -ForegroundColor White
    Write-Host "     Solution: Install Windows 10 SDK via Visual Studio Installer" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  3. Flutter not configured for Windows" -ForegroundColor White
    Write-Host "     Solution: Run 'flutter config --enable-windows-desktop'" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Run 'flutter doctor' for more details" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}
