# AutoUBC Build Script
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  Building AutoUBC APK" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Step 1: Getting dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERROR: Failed to get dependencies!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "Step 2: Generating Isar code..." -ForegroundColor Yellow
flutter pub run build_runner build --delete-conflicting-outputs
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERROR: Failed to generate Isar code!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "Step 3: Building APKs..." -ForegroundColor Yellow
flutter build apk --split-per-abi
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERROR: Failed to build APKs!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "Step 4: Copying APKs..." -ForegroundColor Yellow
Copy-Item "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk" -Destination "AutoUBC.apk" -Force
Write-Host "OK: AutoUBC.apk - main file (for most phones)" -ForegroundColor Green

Write-Host ""
Write-Host "==============================================" -ForegroundColor Green
Write-Host "  DONE!" -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Use AutoUBC.apk for your friend!" -ForegroundColor Cyan
Write-Host ""
Read-Host "Press Enter to exit"
