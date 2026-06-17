# Sửa lỗi build Android: APK hỏng, jni CMake RECORD_NOT_SET, cache Gradle/CMake cũ
# Usage: .\scripts\fix_android_build.ps1

$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

Write-Host 'Dang xoa cache build bi hong...'

$jniCxx = Join-Path $env:LOCALAPPDATA 'Pub\Cache\hosted\pub.dev\jni-1.0.0\android\.cxx'
if (Test-Path $jniCxx) {
    Remove-Item -Recurse -Force $jniCxx
    Write-Host "  Da xoa: $jniCxx"
}

$paths = @(
    'build',
    'android\.gradle',
    'android\.kotlin',
    'android\app\.cxx'
)
foreach ($rel in $paths) {
    if (Test-Path $rel) {
        Remove-Item -Recurse -Force $rel
        Write-Host "  Da xoa: $rel"
    }
}

flutter clean
flutter pub get

Write-Host ''
Write-Host 'Xong. Mo emulator trong Android Studio (Device Manager) roi chay lai app.'
