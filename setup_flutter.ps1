# =============================================
# Sponge Gallery Cleaner - Flutter Setup Script
# Run this ONCE after Flutter SDK is extracted
# =============================================

param(
    [string]$FlutterSdkPath = "C:\flutter"
)

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " Sponge App - Flutter Environment Setup" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# Step 1: Add Flutter to PATH for this session
$env:PATH = "$FlutterSdkPath\bin;$env:PATH"

# Step 2: Verify Flutter
Write-Host "`n[1/5] Checking Flutter..." -ForegroundColor Yellow
flutter --version

# Step 3: Disable analytics (optional)
Write-Host "`n[2/5] Disabling analytics..." -ForegroundColor Yellow
flutter config --no-analytics

# Step 4: Accept Android licenses
Write-Host "`n[3/5] Accepting Android licenses (follow prompts)..." -ForegroundColor Yellow
flutter doctor --android-licenses

# Step 5: Run flutter doctor
Write-Host "`n[4/5] Running Flutter Doctor..." -ForegroundColor Yellow
flutter doctor -v

# Step 6: Create the project if it doesn't exist, or get dependencies
$projectPath = "C:\Users\user\OneDrive\Desktop\android dev\sponge_gallery_cleaner"

if (Test-Path "$projectPath\pubspec.yaml") {
    Write-Host "`n[5/5] Getting Flutter packages..." -ForegroundColor Yellow
    Set-Location $projectPath
    flutter pub get
    Write-Host "`n✅ Setup complete! Run 'flutter run' to launch the app." -ForegroundColor Green
} else {
    Write-Host "`n[5/5] Creating Flutter project..." -ForegroundColor Yellow
    Set-Location "C:\Users\user\OneDrive\Desktop\android dev"
    flutter create --org com.sponge --project-name sponge_gallery_cleaner sponge_gallery_cleaner
    Write-Host "`n✅ Project created! Now copy your source files and run 'flutter pub get'" -ForegroundColor Green
}

Write-Host "`nTo run the app:" -ForegroundColor Cyan
Write-Host "  cd '$projectPath'" -ForegroundColor White
Write-Host "  flutter devices" -ForegroundColor White
Write-Host "  flutter run" -ForegroundColor White
