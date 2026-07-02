import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../app_providers.dart';
import '../../../shared/models/app_models.dart';
import '../../../shared/utils/format_utils.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../roadmaps/widgets/roadmap_mobile_widgets.dart';

class AnalysisResultScreen extends ConsumerStatefulWidget {
  const AnalysisResultScreen({super.key, required this.repoId});

  final String repoId;

  @override
  ConsumerState<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends ConsumerState<AnalysisResultScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final repoId = widget.repoId;
      if (ref.read(repositoryProvider.notifier).getAnalysisById(repoId) == null) {
        ref.read(repositoryProvider.notifier).fetchAnalysis(repoId);
      }
      ref.read(repositoryProvider.notifier).fetchAiFeedback(repoId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(repositoryProvider);
    final analysis = _findAnalysisByRepoId(state.analyses, widget.repoId);
    final feedback = state.feedbackFor(widget.repoId);
    final roleMatchAsync = ref.watch(roleMatchProvider(widget.repoId));
    final roleCatalogAsync = ref.watch(roleCatalogProvider);
    final roleMatch = roleMatchAsync.valueOrNull;
    final roleCatalog = roleCatalogAsync.valueOrNull ?? const <RoleCatalogItem>[];
    final isLoadingRoleMatch = roleMatchAsync.isLoading;

    if (analysis == null) {
      return ListView(
        padding: appScreenPadding(context),
        children: [
          AppCard(
            child: Column(
              children: [
                const Text(
                  'Repository này chưa được phân tích',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Chạy phân tích',
                  loading: state.isAnalyzingRepo(widget.repoId),
                  expand: true,
                  onPressed: state.isAnalyzing
                      ? null
                      : () async {
                          try {
                            await ref.read(repositoryProvider.notifier).analyzeRepository(widget.repoId);
                          } catch (_) {}
                        },
                ),
              ],
            ),
          ),
        ],
      );
    }

    final overallScore = (analysis.summary?.userReadinessScore ??
            analysis.summary?.overallScore ??
            analysis.scores.overall)
        .round();

    return ListView(
      padding: appScreenPadding(context),
      children: [
        PageHeader(title: analysis.repositoryName, subtitle: '${analysis.projectType} • ${scoreLabel(overallScore)}'),
        const SizedBox(height: 8),
        Center(
          child: Column(
            children: [
              Text(
                '$overallScore',
                style: TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: scoreColor(overallScore)),
              ),
              Text('Điểm tổng quan', style: context.appCaptionStyle),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: analysis.techStack.map((t) => AppBadge(label: t, variant: AppBadgeVariant.info)).toList(),
        ),
        if (analysis.analysisScope != null || analysis.summary != null || analysis.topSkillItems.isNotEmpty || analysis.missingSkillItems.isNotEmpty) ...[
          const SizedBox(height: 16),
          _analysisCompactCard(analysis),
        ],
        if (_hasAnalysisDetails(analysis)) ...[
          const SizedBox(height: 16),
          _analysisDetailCard(analysis),
        ],
        const SizedBox(height: 12),
        _listCard('Điểm mạnh', analysis.strengths, Icons.check_circle, AppColors.emerald),
        const SizedBox(height: 12),
        _listCard('Điểm yếu', analysis.weaknesses, Icons.warning_amber, AppColors.amber),
        const SizedBox(height: 12),
        _listCard('Đề xuất', analysis.recommendations, Icons.lightbulb_outline, AppColors.primary),
        const SizedBox(height: 12),
        // ──────────────────────────────────────────────
        // ROLE MATCH CARD
        // ──────────────────────────────────────────────
        _RoleMatchCard(
          analysis: analysis,
          roleMatch: roleMatch,
          isLoading: isLoadingRoleMatch,
          error: roleMatchAsync.hasError ? 'Khong the tai role match' : null,
          onCreateRoadmap: () => _openCreateRoadmapSheet(roleMatch, roleCatalog),
          onRetry: () => ref.invalidate(roleMatchProvider(widget.repoId)),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('AI Feedback', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  PrimaryButton(
                    label: feedback == null ? 'Tạo feedback' : 'Tạo lại',
                    outlined: true,
                    loading: state.isGeneratingFeedback(widget.repoId),
                    onPressed: state.isGeneratingFeedback(widget.repoId)
                        ? null
                        : () async {
                            try {
                              await ref.read(repositoryProvider.notifier).generateAiFeedback(widget.repoId);
                            } catch (_) {}
                          },
                  ),
                ],
              ),
              if (feedback != null) ...[
                const SizedBox(height: 8),
                Text(feedback.summary),
                if (feedback.learningAdvice.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(feedback.learningAdvice, style: context.appCaptionStyle),
                ],
                if (feedback.nextSteps.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...feedback.nextSteps.map((step) => Text('• $step')),
                ],
              ] else
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Chưa có AI feedback cho repository này.', style: context.appCaptionStyle),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(label: 'Hỏi AI Mentor', icon: Icons.chat, expand: true, onPressed: () => context.go('/chat')),
      ],
    );
  }

  void _openCreateRoadmapSheet(RoleMatchResponse? roleMatch, List<RoleCatalogItem> roleCatalog) {
    final state = ref.read(repositoryProvider);
    final roadmapState = ref.read(roadmapProvider);
    final analyses = state.analyses;

    // Pre-seed the role from role match top result if available
    final suggestedRole = roleMatch?.matches.isNotEmpty == true
        ? roleMatch!.matches.first.displayRoleName
        : roadmapState.selectedTargetRole;

    if (suggestedRole.isNotEmpty && suggestedRole != roadmapState.selectedTargetRole) {
      ref.read(roadmapProvider.notifier).setTargetRole(suggestedRole);
    }

    showCreateRoadmapSheet(
      context,
      analyses: analyses,
      roleMatch: roleMatch,
      roleCatalog: roleCatalog,
      selectedRole: suggestedRole.isNotEmpty ? suggestedRole : roadmapState.selectedTargetRole,
      isGenerating: roadmapState.isGenerating,
      initialSourceMode: 'single_repo',
      currentRepoId: widget.repoId,
      onGenerate: (request) => generateAndOpenRoadmap(context, ref, request),
    );
  }

  Widget _listCard(String title, List<String> items, IconData icon, Color color) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(title, style: context.appSectionTitleStyle.copyWith(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Text('Không có dữ liệu', style: context.appCaptionStyle)
          else
            ...items.map((e) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('• $e'))),
        ],
      ),
    );
  }

  bool _hasAnalysisDetails(AnalysisModel analysis) {
    final summary = analysis.summary;
    final scope = analysis.analysisScope;
    return summary?.userLevel?.isNotEmpty == true ||
        summary?.userReadinessScore != null ||
        summary?.overallScore != null ||
        summary?.careerDirection?.isNotEmpty == true ||
        summary?.projectType?.isNotEmpty == true ||
        summary?.confidence != null ||
        scope?.userCommits != null ||
        scope?.totalRepoCommits != null ||
        scope?.activeDays != null;
  }

  Widget _analysisDetailCard(AnalysisModel analysis) {
    final summary = analysis.summary;
    final scope = analysis.analysisScope;
    final rows = <(String, String)>[
      if ((summary?.userLevel ?? '').isNotEmpty) ('Mức độ', summary!.userLevel!),
      if (summary?.userReadinessScore != null) ('Readiness', summary!.userReadinessScore!.toStringAsFixed(1)),
      if (summary?.overallScore != null) ('Overall', summary!.overallScore!.toStringAsFixed(1)),
      if ((summary?.careerDirection ?? '').isNotEmpty) ('Career direction', summary!.careerDirection!),
      if ((summary?.projectType ?? '').isNotEmpty) ('Project type', summary!.projectType!),
      if (summary?.confidence != null) ('Confidence', summary!.confidence!.toStringAsFixed(1)),
      if (scope?.userCommits != null) ('Commits của user', '${scope!.userCommits}'),
      if (scope?.totalRepoCommits != null) ('Tổng commits repo', '${scope!.totalRepoCommits}'),
      if (scope?.activeDays != null) ('Active days', '${scope!.activeDays}'),
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Chi tiết phân tích', style: context.appSectionTitleStyle),
          const SizedBox(height: 12),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(child: Text(row.$1, style: context.appCaptionStyle)),
                  Text(row.$2, style: context.appBodyStyle.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _analysisCompactCard(AnalysisModel analysis) {
    final scope = analysis.analysisScope;
    final summary = analysis.summary;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tong quan phan tich', style: context.appSectionTitleStyle),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (scope?.githubUsername?.isNotEmpty == true) AppBadge(label: '@${scope!.githubUsername}', variant: AppBadgeVariant.info),
              if (scope?.userCommits != null) AppBadge(label: '${scope!.userCommits} commits'),
              if (scope?.activeDays != null) AppBadge(label: '${scope!.activeDays} active days'),
              if (summary?.careerDirection?.isNotEmpty == true) AppBadge(label: summary!.careerDirection!, variant: AppBadgeVariant.info),
              if (summary?.userLevel?.isNotEmpty == true) AppBadge(label: summary!.userLevel!, variant: AppBadgeVariant.success),
              if (summary?.userReadinessScore != null) AppBadge(label: 'Ready ${summary!.userReadinessScore}'),
            ],
          ),
          if (analysis.topSkillItems.isNotEmpty) ...[
            const SizedBox(height: 12),
            _skillItems('Ky nang noi bat', analysis.topSkillItems, AppBadgeVariant.success),
          ],
          if (analysis.missingSkillItems.isNotEmpty) ...[
            const SizedBox(height: 12),
            _skillItems('Ky nang con thieu', analysis.missingSkillItems, AppBadgeVariant.warning),
          ],
        ],
      ),
    );
  }

  Widget _skillItems(String title, List<AnalysisSkillModel> items, AppBadgeVariant variant) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.appLabelStyle.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: items.take(8).map((item) {
            final meta = [
              if ((item.category ?? '').isNotEmpty) item.category,
              if (item.score != null) item.score.toString(),
              if ((item.level ?? '').isNotEmpty) item.level,
              if ((item.priority ?? '').isNotEmpty) item.priority,
            ].whereType<String>().join(' - ');
            return AppBadge(label: meta.isEmpty ? item.displayName : '${item.displayName} ($meta)', variant: variant);
          }).toList(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Role Match Card Widget
// ─────────────────────────────────────────────────────────────────────────────
class _RoleMatchCard extends StatelessWidget {
  const _RoleMatchCard({
    required this.analysis,
    required this.roleMatch,
    required this.isLoading,
    this.error,
    required this.onCreateRoadmap,
    required this.onRetry,
  });

  final AnalysisModel analysis;
  final RoleMatchResponse? roleMatch;
  final bool isLoading;
  final String? error;
  final VoidCallback onCreateRoadmap;
  final VoidCallback onRetry;

  Color _matchLevelColor(BuildContext context, String level) {
    switch (level.toLowerCase()) {
      case 'strong':
      case 'high':
        return AppColors.emerald;
      case 'moderate':
      case 'medium':
        return AppColors.cyan;
      case 'low':
      case 'weak':
        return AppColors.amber;
      default:
        return context.appTextSecondary;
    }
  }

  AppBadgeVariant _matchLevelVariant(String level) {
    switch (level.toLowerCase()) {
      case 'strong':
      case 'high':
        return AppBadgeVariant.success;
      case 'moderate':
      case 'medium':
        return AppBadgeVariant.info;
      case 'low':
      case 'weak':
        return AppBadgeVariant.warning;
      default:
        return AppBadgeVariant.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              const Icon(Icons.work_outline, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Hướng nghề nghiệp', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              // Tạo Roadmap button
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                onPressed: onCreateRoadmap,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 14),
                    SizedBox(width: 4),
                    Text('Tạo Roadmap'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (error != null && !isLoading) ...[
            Text(error!, style: const TextStyle(color: AppColors.amber, fontSize: 12)),
            const SizedBox(height: 8),
          ],

          // Loading state
          if (isLoading) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    const CircularProgressIndicator(strokeWidth: 2),
                    const SizedBox(height: 8),
                    Text('Đang phân tích role phù hợp...', style: context.appCaptionStyle),
                  ],
                ),
              ),
            ),
          ]

          // Role match data available
          else if (roleMatch != null && roleMatch!.matches.isNotEmpty) ...[
            _buildRoleMatchContent(context, roleMatch!),
          ]

          // careerDirection fallback from analysis
          else if (analysis.careerDirection != null && analysis.careerDirection!.isNotEmpty) ...[
            _buildCareerDirectionFallback(context, analysis),
          ]

          // Empty state with retry
          else ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Chưa có dữ liệu Role Match. Nhấn để phân tích lại.',
                    style: context.appCaptionStyle,
                  ),
                ),
                TextButton(onPressed: onRetry, child: const Text('Thử lại')),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoleMatchContent(BuildContext context, RoleMatchResponse rm) {
    final top = rm.matches.isNotEmpty ? rm.matches.first : null;
    final matchScore = top?.matchScore ?? 0.0;
    final matchLevel = top?.matchLevel ?? '';
    final matchLevelLabel = top?.matchLevelLabel ?? matchLevel;
    final levelColor = _matchLevelColor(context, matchLevel);
    final levelVariant = _matchLevelVariant(matchLevel);

    final matchedSkills = top?.matchedSkillNames.isNotEmpty == true ? top!.matchedSkillNames : (top?.matchedSkills ?? []);
    final weakSkills = top?.weakSkillNames ?? const <String>[];
    final missingSkills = top?.missingSkillNames.isNotEmpty == true ? top!.missingSkillNames : (top?.missingSkills ?? []);
    final nextSkills = top?.recommendedNextSkills ?? const <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top role chip
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bạn phù hợp nhất với', style: context.appLabelStyle),
                  const SizedBox(height: 4),
                  Text(
                    top?.displayRoleName ?? '',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${matchScore.toStringAsFixed(0)}%', style: TextStyle(fontWeight: FontWeight.w800, color: levelColor)),
                if (matchLevelLabel.isNotEmpty) AppBadge(label: matchLevelLabel, variant: levelVariant),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (matchedSkills.isNotEmpty)
          _skillSection(
            icon: Icons.check_circle_outline,
            color: AppColors.emerald,
            title: 'Ky nang khop',
            skills: matchedSkills.take(6).toList(),
            variant: AppBadgeVariant.success,
          ),
        if (weakSkills.isNotEmpty) ...[
          const SizedBox(height: 10),
          _skillSection(
            icon: Icons.trending_up,
            color: AppColors.cyan,
            title: 'Ky nang can cung co',
            skills: weakSkills.take(6).toList(),
            variant: AppBadgeVariant.info,
          ),
        ],
        if (missingSkills.isNotEmpty) ...[
          const SizedBox(height: 10),
          _skillSection(
            icon: Icons.warning_amber_rounded,
            color: AppColors.amber,
            title: 'Ky nang thieu',
            skills: missingSkills.take(6).toList(),
            variant: AppBadgeVariant.warning,
          ),
        ],
        if (nextSkills.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('Nen hoc tiep: ${nextSkills.take(4).join(', ')}', style: context.appLabelStyle),
        ],
        if (rm.matches.length > 1) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: rm.matches.skip(1).take(4).map((item) => _OtherRoleChip(item: item)).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildCareerDirectionFallback(BuildContext context, AnalysisModel analysis) {
    return Text(analysis.careerDirection ?? '');
  }

  Widget _skillSection({
    required IconData icon,
    required Color color,
    required String title,
    required List<String> skills,
    required AppBadgeVariant variant,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: skills.map((s) => AppBadge(label: s, variant: variant)).toList(),
        ),
      ],
    );
  }
}

class _OtherRoleChip extends StatelessWidget {
  const _OtherRoleChip({required this.item});
  final RoleMatchItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.appBubbleAiBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.appBorderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(item.role, style: context.appLabelStyle.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(width: 6),
          Text(
            '${item.matchScore.toStringAsFixed(0)}%',
            style: context.appLabelStyle.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

AnalysisModel? _findAnalysisByRepoId(List<AnalysisModel> analyses, String repoId) {
  for (final item in analyses) {
    if (item.repositoryId == repoId || item.id == repoId) return item;
  }
  return null;
}
