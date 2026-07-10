# Gom 5 commit Flutter cua AngerTran ve 1 email GitHub.
# Chay: cd flutter_app; powershell -ExecutionPolicy Bypass -File .\scripts\rewrite_angertran_history.ps1
# Sau do push: git push origin angertran-contributions:main --force-with-lease

$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

$AuthorName = 'AngerTran'
$AuthorEmail = 'thoitnse180471@fpt.edu.vn'

function Invoke-Git {
    param([string[]]$GitArgs)
    & git @GitArgs
    if ($LASTEXITCODE -ne 0) { throw "git $($GitArgs -join ' ') failed ($LASTEXITCODE)" }
}

Write-Host '==> Fetch origin'
Invoke-Git @('fetch', 'origin')

Write-Host '==> Branch angertran-contributions'
Invoke-Git @('checkout', '-B', 'angertran-contributions', 'origin/main')

Write-Host "==> Rewrite author (chi 5 commit cua ban)"
$env:FILTER_BRANCH_SQUELCH_WARNING = '1'
$filter = 'case "$GIT_COMMIT" in fb7b963*|dfc0df7*|502d761*|97bdd7c*|276ccd7*) export GIT_AUTHOR_NAME="AngerTran"; export GIT_AUTHOR_EMAIL="thoitnse180471@fpt.edu.vn"; export GIT_COMMITTER_NAME="AngerTran"; export GIT_COMMITTER_EMAIL="thoitnse180471@fpt.edu.vn";; esac'
Invoke-Git @('filter-branch', '-f', '--env-filter', $filter, 'HEAD')

Write-Host ''
Write-Host '=== COMMIT CUA BAN SAU KHI GOM ==='
git log --author=$AuthorEmail --oneline --shortstat

Write-Host ''
$count = (git log --author=$AuthorEmail --oneline | Measure-Object -Line).Lines
Write-Host "Tong: $count commit duoi AngerTran <$AuthorEmail>"
Write-Host ''
Write-Host 'Tren GitHub: Settings -> Emails -> verify thoitnse180471@fpt.edu.vn'
Write-Host 'Push: git push origin angertran-contributions:main --force-with-lease'
