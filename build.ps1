# AutoUBC Build Script
#
# Builds release APKs per ABI into release\. A distributable APK must be
# signed with the release key from android\key.properties (see
# android\key.properties.example). For a quick test build signed with the
# debug key, run:  .\build.ps1 -AllowDebugSigning
param(
    [switch]$AllowDebugSigning
)

function Exit-WithError([string]$message) {
    Write-Host ""
    Write-Host "ERROR: $message" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  Building AutoUBC APK" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Step 0: Checking the release signing key..." -ForegroundColor Yellow
$keyProperties = Join-Path $PSScriptRoot "android\key.properties"
if (Test-Path -LiteralPath $keyProperties) {
    $storeFileLine = Get-Content -LiteralPath $keyProperties |
        Where-Object { $_ -match '^\s*storeFile\s*=' } |
        Select-Object -First 1
    if (-not $storeFileLine) {
        Exit-WithError "android\key.properties has no storeFile entry."
    }
    $storeFile = ($storeFileLine -split '=', 2)[1].Trim()
    $storePath = Join-Path (Join-Path $PSScriptRoot "android") $storeFile
    if (-not (Test-Path -LiteralPath $storePath)) {
        Exit-WithError "The keystore from android\key.properties was not found: $storePath"
    }
    Write-Host "Release key: $storeFile" -ForegroundColor Green
} elseif ($AllowDebugSigning) {
    Write-Host "WARNING: no android\key.properties - the APK is signed with the DEBUG key." -ForegroundColor DarkYellow
    Write-Host "         It cannot be installed over a release-signed app." -ForegroundColor DarkYellow
} else {
    Exit-WithError ("android\key.properties not found. Create the release key as described in " +
        "android\key.properties.example, or run .\build.ps1 -AllowDebugSigning for a test build.")
}

Write-Host ""
Write-Host "Step 1: Getting dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) { Exit-WithError "Failed to get dependencies!" }

Write-Host ""
Write-Host "Step 2: Generating Isar code..." -ForegroundColor Yellow
dart run build_runner build --delete-conflicting-outputs
if ($LASTEXITCODE -ne 0) { Exit-WithError "Failed to generate Isar code!" }

Write-Host ""
Write-Host "Step 3: Static analysis and tests..." -ForegroundColor Yellow
flutter analyze
if ($LASTEXITCODE -ne 0) { Exit-WithError "flutter analyze found problems. Fix them before building a release." }
$env:TZ = "Europe/Kyiv"
flutter test
if ($LASTEXITCODE -ne 0) { Exit-WithError "Tests failed. Fix them before building a release." }

Write-Host ""
Write-Host "Step 4: Building APKs..." -ForegroundColor Yellow
flutter build apk --release --split-per-abi --android-skip-build-dependency-validation | Out-Host
if ([int]$LASTEXITCODE -ne 0) {
    Exit-WithError ("APK build failed! TIP: run 'flutter pub get' in a regular PowerShell " +
        "(not the Trae sandbox) after editing pubspec.yaml, then retry this build script.")
}

Write-Host ""
Write-Host "Step 5: Copying ABI-specific APKs..." -ForegroundColor Yellow
$apkOutputDir = Join-Path $PSScriptRoot "build\app\outputs\flutter-apk"
$releaseDir = Join-Path $PSScriptRoot "release"
$abiFiles = @{
    "arm64-v8a" = "app-arm64-v8a-release.apk"
    "armeabi-v7a" = "app-armeabi-v7a-release.apk"
    "x86_64" = "app-x86_64-release.apk"
}

foreach ($abiFile in $abiFiles.Values) {
    $sourcePath = Join-Path $apkOutputDir $abiFile
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        Exit-WithError "Missing ABI APK: $sourcePath"
    }
}

New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null

foreach ($abi in $abiFiles.Keys) {
    $sourcePath = Join-Path $apkOutputDir $abiFiles[$abi]
    $destinationPath = Join-Path $releaseDir "AutoUBC-$abi.apk"
    Copy-Item $sourcePath -Destination $destinationPath -Force
    Write-Host "OK: release\AutoUBC-$abi.apk" -ForegroundColor Green
}

Write-Host ""
Write-Host "==============================================" -ForegroundColor Green
Write-Host "  DONE!" -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Use the APK from release\ and choose the ABI matching the phone." -ForegroundColor Cyan
Write-Host ""
Read-Host "Press Enter to exit"
