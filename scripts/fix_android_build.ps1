# Sửa lỗi build Android: jni CMake RECORD_NOT_SET, PathExistsException asset copy (errno 183)
# Usage: .\scripts\fix_android_build.ps1

$ErrorActionPreference = 'Continue'
Set-Location (Join-Path $PSScriptRoot '..')

function Remove-TreeForce([string]$Path) {
    if (-not (Test-Path $Path)) { return }
    try {
        Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
    } catch {
        cmd /c "rmdir /s /q `"$Path`"" 2>$null
    }
    if (Test-Path $Path) {
        Write-Warning "  Con ton: $Path (dong Android Studio/emulator roi chay lai script)"
    } else {
        Write-Host "  Da xoa: $Path"
    }
}

Write-Host 'Dang dung Gradle daemon...'
if (Test-Path 'android\gradlew.bat') {
    & 'android\gradlew.bat' --stop 2>$null
}

Write-Host 'Dang xoa cache build bi hong...'

$jniCxx = Join-Path $env:LOCALAPPDATA 'Pub\Cache\hosted\pub.dev\jni-1.0.0\android\.cxx'
Remove-TreeForce $jniCxx

foreach ($rel in @('build', 'android\.gradle', 'android\.kotlin', 'android\app\.cxx', 'android\app\build')) {
    Remove-TreeForce (Join-Path (Get-Location) $rel)
}

flutter clean
flutter pub get

Write-Host ''
Write-Host 'Xong. Trong Android Studio: Stop app -> Run lai (debug).'
Write-Host 'Hoac: flutter run -d emulator-5554'
