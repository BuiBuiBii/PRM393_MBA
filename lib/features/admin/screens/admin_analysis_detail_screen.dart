import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/format_utils.dart';
import '../../../shared/widgets/async_content.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_detail_widgets.dart';
import '../widgets/admin_widgets.dart';

const _scoreLabels = {
  'techStackScore': 'Công nghệ',
  'documentationScore': 'Tài liệu',
  'commitQualityScore': 'Commit',
  'deploymentScore': 'Triển khai',
  'testingScore': 'Kiểm thử',
  'portfolioReadinessScore': 'Portfolio',
  'overallScore': 'Tổng thể',
};

const _hiddenScoreKeys = {
  'commitQualityScore',
  'deploymentScore',
  'testingScore',
};

const _checklistLabels = {
  'hasReadme': 'README',
  'hasEnvExample': '.env.example',
  'hasDocker': 'Dockerfile',
  'hasDockerCompose': 'Docker Compose',
  'hasCICD': 'CI/CD',
  'hasTesting': 'Kiểm thử',
  'hasLinting': 'Linting',
  'hasFormatter': 'Formatter',
  'hasPackageFile': 'Package file',
};

class AdminAnalysisDetailScreen extends ConsumerStatefulWidget {
  const AdminAnalysisDetailScreen({super.key, required this.analysisId});

  final String analysisId;

  @override
  ConsumerState<AdminAnalysisDetailScreen> createState() =>
      _AdminAnalysisDetailScreenState();
}

class _AdminAnalysisDetailScreenState
    extends ConsumerState<AdminAnalysisDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        ref.read(adminAnalysisDetailProvider.notifier).load(widget.analysisId));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminAnalysisDetailProvider);
    final analysis = state.analysis;
    final visibleScoreEntries = analysis == null
        ? const <MapEntry<String, int>>[]
        : analysis.scores.entries
            .where((entry) => !_hiddenScoreKeys.contains(entry.key))
            .toList();

    return AsyncPageBody(
      isLoading: state.isLoading,
      hasData: analysis != null,
      error: state.error,
      onRetry: () => ref
          .read(adminAnalysisDetailProvider.notifier)
          .load(widget.analysisId),
      child: analysis == null
          ? const SizedBox.shrink()
          : ListView(
              padding: appScreenPadding(context),
              children: [
                AdminSectionHeader(
                  title: analysis.repoName,
                  subtitle: 'Chi tiết kết quả phân tích repository.',
                  trailing: PrimaryButton(
                    label: 'Làm mới',
                    icon: Icons.refresh,
                    outlined: true,
                    onPressed: () => ref
                        .read(adminAnalysisDetailProvider.notifier)
                        .load(widget.analysisId),
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(analysis.projectType,
                                style: context.appSectionTitleStyle),
                          ),
                          AppBadge(
                            label: 'Tổng thể ${analysis.overallScore ?? 0}/100',
                            variant: (analysis.overallScore ?? 0) >= 70
                                ? AppBadgeVariant.success
                                : (analysis.overallScore ?? 0) >= 40
                                    ? AppBadgeVariant.warning
                                    : AppBadgeVariant.info,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      adminDetailRow(context, 'Người dùng', analysis.ownerName),
                      if (analysis.ownerEmail != null)
                        adminDetailRow(context, 'Email', analysis.ownerEmail!),
                      adminDetailRow(
                          context, 'Định hướng', analysis.careerDirection),
                      adminDetailRow(context, 'Ngày phân tích',
                          formatDate(analysis.analyzedAt)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (analysis.analysisScope.isNotEmpty) ...[
                  _analysisScopeSection(context, analysis.analysisScope),
                  const SizedBox(height: 12),
                ],
                if (visibleScoreEntries.isNotEmpty) ...[
                  Text('Điểm số', style: context.appSectionTitleStyle),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.8,
                    children: [
                      for (final entry in visibleScoreEntries)
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_scoreLabels[entry.key] ?? entry.key,
                                  style: context.appLabelStyle),
                              Text('${entry.value}/100',
                                  style: context.appHeadingStyle
                                      .copyWith(fontSize: 18)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Công nghệ phát hiện',
                          style: context.appSectionTitleStyle),
                      const SizedBox(height: 10),
                      _badgeSection(context, 'Ngôn ngữ', analysis.languages,
                          AppBadgeVariant.info),
                      _badgeSection(context, 'Framework', analysis.frameworks,
                          AppBadgeVariant.neutral),
                      _badgeSection(
                          context,
                          'Package',
                          analysis.packages.take(24).toList(),
                          AppBadgeVariant.neutral),
                    ],
                  ),
                ),
                if (analysis.checklist.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Checklist repository',
                            style: context.appSectionTitleStyle),
                        const SizedBox(height: 10),
                        for (final entry in analysis.checklist.entries)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                    child: Text(_checklistLabels[entry.key] ??
                                        entry.key)),
                                AppBadge(
                                  label: entry.value ? 'Có' : 'Thiếu',
                                  variant: entry.value
                                      ? AppBadgeVariant.success
                                      : AppBadgeVariant.warning,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                if (analysis.commitSummary.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hoạt động commit',
                            style: context.appSectionTitleStyle),
                        const SizedBox(height: 10),
                        adminDetailRow(context, 'Tổng commit',
                            '${analysis.commitSummary['totalCommits'] ?? 0}'),
                        adminDetailRow(context, 'Số ngày hoạt động',
                            '${analysis.commitSummary['activeDays'] ?? 0}'),
                        adminDetailRow(
                          context,
                          'Commit mơ hồ',
                          '${((analysis.commitSummary['vagueCommitRatio'] as num? ?? 0) * 100).round()}%',
                        ),
                        adminDetailRow(
                          context,
                          'Conventional commit',
                          '${((analysis.commitSummary['conventionalCommitRatio'] as num? ?? 0) * 100).round()}%',
                        ),
                        adminDetailRow(
                            context,
                            'Commit đầu',
                            formatDate(analysis.commitSummary['firstCommitDate']
                                ?.toString())),
                        adminDetailRow(
                            context,
                            'Commit gần nhất',
                            formatDate(analysis.commitSummary['lastCommitDate']
                                ?.toString())),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                AdminTextListCard(
                    title: 'Điểm mạnh',
                    items: analysis.strengths,
                    variant: AppBadgeVariant.success),
                const SizedBox(height: 12),
                AdminTextListCard(
                    title: 'Điểm yếu',
                    items: analysis.weaknesses,
                    variant: AppBadgeVariant.warning),
                const SizedBox(height: 12),
                AdminTextListCard(
                  title: 'Kỹ năng còn thiếu',
                  items: analysis.missingSkills,
                  variant: AppBadgeVariant.info,
                  emptyText: 'Không phát hiện kỹ năng còn thiếu.',
                ),
                const SizedBox(height: 12),
                AdminTextListCard(
                    title: 'Khuyến nghị',
                    items: analysis.recommendations,
                    variant: AppBadgeVariant.info),
              ],
            ),
    );
  }

  Widget _badgeSection(BuildContext context, String title, List<String> items,
      AppBadgeVariant variant) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: context.appTextPrimary)),
          const SizedBox(height: 6),
          if (items.isEmpty)
            Text('Chưa có', style: context.appLabelStyle)
          else
            Wrap(
                spacing: 6,
                runSpacing: 6,
                children: items
                    .map((e) => AppBadge(label: e, variant: variant))
                    .toList()),
        ],
      ),
    );
  }

  Widget _analysisScopeSection(
      BuildContext context, Map<String, dynamic> scope) {
    final evidence = _analysisEvidence(scope);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.monitor_heart_outlined,
                size: 20, color: context.appTextPrimary),
            const SizedBox(width: 8),
            Text('Phạm vi và độ phủ dữ liệu',
                style: context.appSectionTitleStyle),
          ],
        ),
        const SizedBox(height: 10),
        AdminDetailStatGrid(
          items: _analysisScopeItems(scope),
          mainAxisExtent: 148,
        ),
        if (evidence.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('Nguồn bằng chứng', style: context.appLabelStyle),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: evidence
                .map((item) => AppBadge(
                      label: item,
                      variant: AppBadgeVariant.info,
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  List<(String label, String value)> _analysisScopeItems(
      Map<String, dynamic> scope) {
    final items = <(String, String)>[];

    void add(String label, List<String> keys,
        {String Function(dynamic)? format}) {
      final value = _firstScopeValue(scope, keys);
      if (value == null) return;
      items.add((label, format?.call(value) ?? _displayScopeValue(value)));
    }

    add('Phạm vi', const ['type'], format: _scopeTypeLabel);
    add('GitHub user', const ['githubUsername', 'githubUser', 'username']);

    final userCommits = _scopeInteger(
        _firstScopeValue(scope, const ['userCommits', 'contributedCommits']));
    final totalCommits = _scopeInteger(
        _firstScopeValue(scope, const ['totalRepoCommits', 'totalCommits']));
    if (userCommits != null || totalCommits != null) {
      items.add((
        'Commit của user / repo',
        '${userCommits ?? 0} / ${totalCommits ?? 0}'
      ));
    }

    add('Ngày hoạt động', const ['activeDays']);
    add('File nguồn',
        const ['sourceFileCount', 'totalSourceFiles', 'sourceFiles']);
    add('File từ đóng góp user', const [
      'userSourceFileCount',
      'userContributedFiles',
      'userFiles'
    ]);
    add('API/dependency token', const [
      'apiDependencyTokenCount',
      'apiDependencyTokens',
      'apiTokens'
    ]);
    add('Độ tin cậy', const ['confidence', 'coverageConfidence'],
        format: _scopePercent);
    add('Issue đã phân tích',
        const ['analyzedIssueCount', 'analyzedIssues', 'issueCount']);
    add('File package',
        const ['packageFileCount', 'packageFiles', 'manifestFileCount']);
    add('Tài liệu', const [
      'documentationStatus',
      'documentationCoverage',
      'documentation'
    ]);
    add('Dùng dữ liệu cache',
        const ['usedCache', 'cacheUsed', 'isCached', 'fromCache']);

    return items;
  }

  List<String> _analysisEvidence(Map<String, dynamic> scope) {
    final raw = _firstScopeValue(
        scope, const ['evidenceSources', 'sources', 'dataSources']);
    if (raw is List) {
      return raw
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (raw is Map) {
      return raw.entries
          .map((entry) => '${entry.key}: ${_displayScopeValue(entry.value)}')
          .toList();
    }

    final evidence = <String>[];
    void add(String label, List<String> keys) {
      final value = _firstScopeValue(scope, keys);
      if (value != null) {
        evidence.add('$label: ${_displayScopeValue(value)}');
      }
    }

    add('Nguồn', const ['analysisSource', 'scoringSource', 'source']);
    add('repos', const ['reposAvailable', 'repositoriesAvailable', 'hasRepos']);
    add('issues', const ['issuesAvailable', 'hasIssues']);
    add('apis', const ['apisAvailable', 'hasApis']);
    return evidence;
  }

  dynamic _firstScopeValue(Map<String, dynamic> scope, List<String> keys) {
    for (final key in keys) {
      final value = scope[key];
      if (value != null && value.toString().isNotEmpty) return value;
    }
    return null;
  }

  int? _scopeInteger(dynamic value) {
    if (value is List) return value.length;
    if (value is Map) return value.length;
    return value is num
        ? value.round()
        : int.tryParse(value?.toString() ?? '');
  }

  String _displayScopeValue(dynamic value) {
    if (value is bool) return value ? 'Có' : 'Không';
    if (value is List) return '${value.length}';
    if (value is Map) return '${value.length}';
    return value.toString();
  }

  String _scopeTypeLabel(dynamic value) {
    switch (value.toString()) {
      case 'user_contribution':
        return 'Đóng góp của người dùng';
      case 'full_repository':
      case 'repository':
        return 'Toàn bộ repository';
      default:
        return value.toString();
    }
  }

  String _scopePercent(dynamic value) {
    final parsed = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');
    if (parsed == null) return value.toString();
    final percent = parsed >= 0 && parsed <= 1 ? parsed * 100 : parsed;
    return '${percent.toStringAsFixed(1)}%';
  }
}
