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
  ConsumerState<AdminAnalysisDetailScreen> createState() => _AdminAnalysisDetailScreenState();
}

class _AdminAnalysisDetailScreenState extends ConsumerState<AdminAnalysisDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminAnalysisDetailProvider.notifier).load(widget.analysisId));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminAnalysisDetailProvider);
    final analysis = state.analysis;

    return AsyncPageBody(
      isLoading: state.isLoading,
      hasData: analysis != null,
      error: state.error,
      onRetry: () => ref.read(adminAnalysisDetailProvider.notifier).load(widget.analysisId),
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
                    onPressed: () => ref.read(adminAnalysisDetailProvider.notifier).load(widget.analysisId),
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
                            child: Text(analysis.projectType, style: context.appSectionTitleStyle),
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
                      adminDetailRow(context,'Người dùng', analysis.ownerName),
                      if (analysis.ownerEmail != null) adminDetailRow(context,'Email', analysis.ownerEmail!),
                      adminDetailRow(context,'Định hướng', analysis.careerDirection),
                      adminDetailRow(context,'Ngày phân tích', formatDate(analysis.analyzedAt)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (analysis.scores.isNotEmpty) ...[
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
                      for (final entry in analysis.scores.entries)
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_scoreLabels[entry.key] ?? entry.key, style: context.appLabelStyle),
                              Text('${entry.value}/100', style: context.appHeadingStyle.copyWith(fontSize: 18)),
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
                      Text('Công nghệ phát hiện', style: context.appSectionTitleStyle),
                      const SizedBox(height: 10),
                      _badgeSection(context, 'Ngôn ngữ', analysis.languages, AppBadgeVariant.info),
                      _badgeSection(context, 'Framework', analysis.frameworks, AppBadgeVariant.neutral),
                      _badgeSection(context, 'Package', analysis.packages.take(24).toList(), AppBadgeVariant.neutral),
                    ],
                  ),
                ),
                if (analysis.checklist.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Checklist repository', style: context.appSectionTitleStyle),
                        const SizedBox(height: 10),
                        for (final entry in analysis.checklist.entries)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(child: Text(_checklistLabels[entry.key] ?? entry.key)),
                                AppBadge(
                                  label: entry.value ? 'Có' : 'Thiếu',
                                  variant: entry.value ? AppBadgeVariant.success : AppBadgeVariant.warning,
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
                        Text('Hoạt động commit', style: context.appSectionTitleStyle),
                        const SizedBox(height: 10),
                        adminDetailRow(context,'Tổng commit', '${analysis.commitSummary['totalCommits'] ?? 0}'),
                        adminDetailRow(context,'Số ngày hoạt động', '${analysis.commitSummary['activeDays'] ?? 0}'),
                        adminDetailRow(context,
                          'Commit mơ hồ',
                          '${((analysis.commitSummary['vagueCommitRatio'] as num? ?? 0) * 100).round()}%',
                        ),
                        adminDetailRow(context,
                          'Conventional commit',
                          '${((analysis.commitSummary['conventionalCommitRatio'] as num? ?? 0) * 100).round()}%',
                        ),
                        adminDetailRow(context,'Commit đầu', formatDate(analysis.commitSummary['firstCommitDate']?.toString())),
                        adminDetailRow(context,'Commit gần nhất', formatDate(analysis.commitSummary['lastCommitDate']?.toString())),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                AdminTextListCard(title: 'Điểm mạnh', items: analysis.strengths, variant: AppBadgeVariant.success),
                const SizedBox(height: 12),
                AdminTextListCard(title: 'Điểm yếu', items: analysis.weaknesses, variant: AppBadgeVariant.warning),
                const SizedBox(height: 12),
                AdminTextListCard(title: 'Kỹ năng còn thiếu', items: analysis.missingSkills, variant: AppBadgeVariant.info),
                const SizedBox(height: 12),
                AdminTextListCard(title: 'Khuyến nghị', items: analysis.recommendations, variant: AppBadgeVariant.info),
                const SizedBox(height: 12),
                AdminTextListCard(title: 'Tín hiệu kỹ năng', items: analysis.skillSignals),
              ],
            ),
    );
  }

  Widget _badgeSection(BuildContext context, String title, List<String> items, AppBadgeVariant variant) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: context.appTextPrimary)),
          const SizedBox(height: 6),
          if (items.isEmpty)
            Text('Chưa có', style: context.appLabelStyle)
          else
            Wrap(spacing: 6, runSpacing: 6, children: items.map((e) => AppBadge(label: e, variant: variant)).toList()),
        ],
      ),
    );
  }
}
