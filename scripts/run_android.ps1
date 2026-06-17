# Chạy Flutter trên Android emulator
# Usage: .\scripts\run_android.ps1 [-Mode Demo|Api|Local]

param(
    [ValidateSet('Demo', 'Api', 'Local')]
    [string]$Mode = 'Api'
)

$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

function Get-AndroidDeviceId {
    $lines = flutter devices --machine 2>$null | ConvertFrom-Json
    $android = $lines | Where-Object { $_.targetPlatform -eq 'android-arm64' -or $_.targetPlatform -eq 'android-x64' -or $_.id -match '^emulator-' } | Select-Object -First 1
    return $android.id
}

$deviceId = Get-AndroidDeviceId
if (-not $deviceId) {
    Write-Host 'Khong thay emulator Android. Dang khoi dong Medium Phone...'
    flutter emulators --launch Medium_Phone 2>$null
    if ($LASTEXITCODE -ne 0) {
        flutter emulators --launch Pixel_10_Pro 2>$null
    }
    Start-Sleep -Seconds 25
    $deviceId = Get-AndroidDeviceId
}

if (-not $deviceId) {
    Write-Host 'Van chua co thiet bi Android. Mo Device Manager trong Android Studio va Start emulator truoc.'
    exit 1
}

Write-Host "Thiet bi: $deviceId"

$apiUrl = switch ($Mode) {
    'Local' { 'http://10.0.2.2:5000/api' }
    default { 'https://career-roadmap-api-zs7y.onrender.com/api' }
}

$demoMode = if ($Mode -eq 'Demo') { 'true' } else { 'false' }
$googleClientId = '970437677508-k1jc855q10hnl3sktcop9job68hgkd0r.apps.googleusercontent.com'

Write-Host "Mode: $Mode | DEMO_MODE=$demoMode | API=$apiUrl"

flutter run -d $deviceId `
    --dart-define=DEMO_MODE=$demoMode `
    --dart-define=API_BASE_URL=$apiUrl `
    --dart-define=GOOGLE_CLIENT_ID=$googleClientId
