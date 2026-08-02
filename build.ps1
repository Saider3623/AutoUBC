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
dart run build_runner build --delete-conflicting-outputs
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERROR: Failed to generate Isar code!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "Step 3: Building APKs..." -ForegroundColor Yellow

function Stop-GradleDaemons {
    $gradleWrapper = Join-Path $PSScriptRoot "android\gradlew.bat"
    if (-not (Test-Path -LiteralPath $gradleWrapper)) {
        Write-Host "WARNING: Gradle wrapper not found; skipping daemon stop." -ForegroundColor DarkYellow
        return
    }

    Push-Location (Join-Path $PSScriptRoot "android")
    try {
        & $gradleWrapper --stop | Out-Host
        $gradleExitCode = [int]$LASTEXITCODE
        if ($gradleExitCode -ne 0) {
            Write-Host "WARNING: Could not stop all Gradle daemons; continuing cleanup." -ForegroundColor DarkYellow
        }
    }
    finally {
        Pop-Location
    }
}

function Clear-StaleGradleArtifacts {
    Write-Host "Clearing stale Gradle project and transform caches..." -ForegroundColor Yellow
    Stop-GradleDaemons

    $projectGradleDir = Join-Path $PSScriptRoot "android\.gradle"
    if (Test-Path -LiteralPath $projectGradleDir) {
        try {
            Remove-Item -LiteralPath $projectGradleDir -Recurse -Force -ErrorAction Stop
            Write-Host "Removed project Gradle cache: $projectGradleDir" -ForegroundColor DarkGray
        }
        catch {
            Write-Host "WARNING: Could not remove project Gradle cache: $($_.Exception.Message)" -ForegroundColor DarkYellow
        }
    }

    $globalGradleCache = Join-Path $env:USERPROFILE ".gradle\caches"
    if (-not (Test-Path -LiteralPath $globalGradleCache)) {
        Write-Host "No global Gradle cache found; continuing." -ForegroundColor DarkGray
        return
    }

    $transformCaches = @(Get-ChildItem -LiteralPath $globalGradleCache -Directory -Filter "transforms-*" -ErrorAction SilentlyContinue)
    if ($transformCaches.Count -eq 0) {
        Write-Host "No global Gradle transform caches found; continuing." -ForegroundColor DarkGray
        return
    }

    foreach ($cache in $transformCaches) {
        try {
            Remove-Item -LiteralPath $cache.FullName -Recurse -Force -ErrorAction Stop
            Write-Host "Removed Gradle transform cache: $($cache.Name)" -ForegroundColor DarkGray
        }
        catch {
            Write-Host "WARNING: Could not remove $($cache.Name): $($_.Exception.Message)" -ForegroundColor DarkYellow
        }
    }
}

function Invoke-ApkBuild {
    flutter build apk --split-per-abi | Out-Host
    $buildExitCode = [int]$LASTEXITCODE
    return $buildExitCode
}

$buildExitCode = Invoke-ApkBuild
if ($buildExitCode -ne 0) {
    Write-Host ""
    Write-Host "The first build failed. Cleaning generated Android resources and retrying..." -ForegroundColor Yellow
    flutter clean
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Flutter clean failed!" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }

    Clear-StaleGradleArtifacts

    flutter pub get
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Failed to restore dependencies after clean!" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }

    flutter pub run build_runner build --delete-conflicting-outputs
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Failed to regenerate Isar code after clean!" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }

    $buildExitCode = Invoke-ApkBuild
}

if ($buildExitCode -ne 0) {
    Write-Host ""
    Write-Host "ERROR: Failed to build APKs after clean retry!" -ForegroundColor Red
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
