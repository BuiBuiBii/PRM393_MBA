# Build APK release — luôn dùng API thật (DEMO_MODE=false)
# Usage: .\scripts\build_apk.ps1 [-ApiUrl <url>]

param(
  [string]$ApiUrl = 'https://career-roadmap-api-zs7y.onrender.com/api'
)

$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

Write-Host "Building release APK | DEMO_MODE=false | API=$ApiUrl"

flutter build apk --release `
  --dart-define=DEMO_MODE=false `
  --dart-define=API_BASE_URL=$ApiUrl `
  --dart-define=GOOGLE_CLIENT_ID=970437677508-k1jc855q10hnl3sktcop9job68hgkd0r.apps.googleusercontent.com

$apk = 'build\app\outputs\flutter-apk\app-release.apk'
if (Test-Path $apk) {
  $dest = 'GitAnalyzer-v1.0.1-release.apk'
  Copy-Item $apk $dest -Force
  Write-Host "Done: $dest"
} else {
  Write-Host "APK not found at $apk"
  exit 1
}
