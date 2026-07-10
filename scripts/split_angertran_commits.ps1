# Tach 2 commit lon cua AngerTran thanh nhieu commit nho hon.
# Chay sau rewrite_angertran_history.ps1

$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

$AuthorName = 'AngerTran'
$AuthorEmail = 'thoitnse180471@fpt.edu.vn'

function Invoke-Git {
    param([string[]]$GitArgs)
    & git @GitArgs
    if ($LASTEXITCODE -ne 0) { throw "git $($GitArgs -join ' ') failed ($LASTEXITCODE)" }
}

function New-Commit {
    param([string]$Message)
    if (git diff --cached --quiet) { return }
    Invoke-Git @('-c', "user.name=$AuthorName", '-c', "user.email=$AuthorEmail", 'commit', '-m', $Message)
}

function Stage-Paths {
    param([string[]]$Paths)
    $ok = @()
    foreach ($p in $Paths) { if (Test-Path $p) { $ok += $p } }
    if ($ok.Count -gt 0) { Invoke-Git -GitArgs (@('add', '--') + $ok) }
}

Invoke-Git @('checkout', 'angertran-contributions')

$refactor = (git log --grep='Refactor feature architecture' -1 --format=%H).Trim()
$dev2vec = (git log --grep='Complete Dev2Vec migration' -1 --format=%H).Trim()
$refactorParent = (git rev-parse "$refactor^").Trim()

Write-Host "==> Tach refactor: $refactor"
Invoke-Git @('checkout', '-B', 'angertran-split', $refactorParent)
Invoke-Git @('cherry-pick', '-n', $refactor)
Invoke-Git @('reset', 'HEAD')

Stage-Paths @(
    'docs/DANH_GIA_CODE_THEO_TIEU_CHI.md', 'docs/PLAN_9_DIEM_3_TIEU_CHI_COT_LOI.md', 'docs/TIEN_DO_PLAN_9_DIEM.md',
    'lib/ARCHITECTURE.md', 'lib/core/constants', 'assets/images', 'devtools_options.yaml', 'pubspec.yaml'
)
New-Commit 'feat(flutter): add docs, assets and architecture constants'

Stage-Paths @(
    'lib/features/repositories/data', 'lib/features/repositories/providers', 'lib/features/repositories/widgets',
    'lib/features/repositories/screens/repositories_screen.dart',
    'lib/features/dashboard/providers', 'lib/features/notifications/providers',
    'lib/features/feature_providers.dart', 'lib/core/network/app_api_provider.dart'
)
New-Commit 'feat(flutter): extract repositories and dashboard providers'

Stage-Paths @('lib/features/chat')
New-Commit 'feat(flutter): refactor chat into widgets and provider'

Stage-Paths @('lib/features/analysis')
New-Commit 'feat(flutter): refactor analysis screens and role match widgets'

Stage-Paths @(
    'lib/features/roadmaps/data', 'lib/features/roadmaps/providers',
    'lib/features/roadmaps/screens/roadmap_detail_screen.dart', 'lib/features/roadmaps/widgets/roadmap_detail_sections.dart',
    'lib/features/roadmaps/widgets/roadmap_list_header.dart', 'lib/features/roadmaps/screens/roadmaps_screen.dart',
    'lib/features/roadmaps/widgets/roadmap_mobile_widgets.dart'
)
New-Commit 'feat(flutter): refactor roadmaps provider and detail UI'

Stage-Paths @(
    'lib/features/shell', 'lib/core/router/app_navigator_keys.dart', 'lib/core/router/app_router.dart',
    'lib/shared/widgets/collapsible_list.dart', 'lib/shared/widgets/scroll_list_hints.dart',
    'lib/shared/widgets/app_image_assets.dart', 'lib/features/admin/screens/admin_shell.dart', 'test/user_model_test.dart'
)
New-Commit 'feat(flutter): add shell drawer, navigation keys and collapsible lists'

Invoke-Git @('add', '-A')
New-Commit 'feat(flutter): complete architecture refactor leftovers'

Write-Host "==> Tach Dev2Vec: $dev2vec"
Invoke-Git @('cherry-pick', '-n', $dev2vec)
Invoke-Git @('reset', 'HEAD')

Stage-Paths @(
    'lib/core/constants/dev2vec_roles.dart', 'lib/core/config/app_config.dart', 'lib/core/network/api_utils.dart',
    'lib/core/network/app_api.dart', 'lib/features/repositories/data/repository_repository.dart',
    'lib/features/repositories/providers/role_catalog_provider.dart', 'lib/features/repositories/providers/repository_provider.dart',
    'lib/features/roadmaps/models', 'lib/features/roadmaps/data/roadmap_repository.dart', 'lib/features/roadmaps/providers/roadmap_provider.dart',
    'docs/PLAN_DEV2VEC_FLUTTER_MIGRATION.md', 'test/role_match_model_test.dart'
)
New-Commit 'feat(flutter): Dev2Vec API, models and role catalog integration'

Stage-Paths @('lib/features/dashboard/widgets', 'lib/features/dashboard/screens/dashboard_screen.dart')
New-Commit 'feat(flutter): redesign dashboard UI'

Stage-Paths @(
    'lib/features/repositories/screens', 'lib/features/repositories/widgets/repository_card.dart',
    'lib/features/roadmaps/screens/roadmaps_screen.dart', 'lib/features/roadmaps/widgets/create_roadmap_sheet.dart',
    'lib/features/roadmaps/widgets/role_match_suggestion_tile.dart', 'lib/features/roadmaps/utils/roadmap_generate_helper.dart',
    'lib/features/analysis/widgets/analysis_readiness_section.dart', 'lib/features/analysis/widgets/role_match_card.dart',
    'lib/features/analysis/screens/analysis_result_screen.dart'
)
New-Commit 'feat(flutter): improve repos/roadmaps loading sync and Dev2Vec UI'

Invoke-Git @('add', '-A')
New-Commit 'feat(flutter): admin error cleanup, build script and misc Dev2Vec polish'

Invoke-Git @('checkout', 'angertran-contributions')
Invoke-Git @('reset', '--hard', 'angertran-split')

Write-Host ''
Write-Host '=== COMMIT CUA BAN (sau tach) ==='
git log --author=$AuthorEmail --oneline --shortstat -20
$count = (git log --author=$AuthorEmail --oneline | Measure-Object -Line).Lines
Write-Host "Tong: $count commit"
Write-Host 'Push: git push origin angertran-contributions:main --force-with-lease'
