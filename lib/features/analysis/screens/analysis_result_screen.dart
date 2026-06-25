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
      // Fetch Role Match
      ref.read(repositoryProvider.notifier).fetchRoleMatches(repoId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(repositoryProvider);
    final analysis = state.analyses.where((a) => a.repositoryId == widget.repoId || a.id == widget.repoId).firstOrNull;
    final feedback = state.feedbackFor(widget.repoId);
    final roleMatch = state.roleMatchFor(widget.repoId);
    final isLoadingRoleMatch = state.isLoadingRoleMatch(widget.repoId);

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

    final scores = [
      ('Kiến trúc', analysis.scores.architecture),
      ('Độ hoàn thiện', analysis.scores.completeness),
      ('Commit', analysis.scores.commitQuality),
      ('Tài liệu', analysis.scores.documentation),
      ('Quy ước', analysis.scores.codeConvention),
    ];

    return ListView(
      padding: appScreenPadding(context),
      children: [
        PageHeader(title: analysis.repositoryName, subtitle: '${analysis.projectType} • ${scoreLabel(analysis.scores.overall)}'),
        const SizedBox(height: 8),
        Center(
          child: Column(
            children: [
              Text(
                '${analysis.scores.overall}',
                style: TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: scoreColor(analysis.scores.overall)),
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
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chi tiết điểm', style: context.appSectionTitleStyle),
              const SizedBox(height: 12),
              ...scores.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(s.$1, style: context.appBodyStyle),
                          Text('${s.$2}', style: TextStyle(fontWeight: FontWeight.bold, color: scoreColor(s.$2))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: s.$2 / 100,
                        backgroundColor: Colors.grey.shade200,
                        color: scoreColor(s.$2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
          onCreateRoadmap: () => _openCreateRoadmapSheet(roleMatch),
          onRetry: () => ref.read(repositoryProvider.notifier).fetchRoleMatches(widget.repoId),
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

  void _openCreateRoadmapSheet(RoleMatchModel? roleMatch) {
    final state = ref.read(repositoryProvider);
    final roadmapState = ref.read(roadmapProvider);
    final analyses = state.analyses;

    // Pre-seed the role from role match top result if available
    final suggestedRole = roleMatch?.topRole.isNotEmpty == true
        ? roleMatch!.topRole
        : roadmapState.selectedTargetRole;

    if (suggestedRole.isNotEmpty && suggestedRole != roadmapState.selectedTargetRole) {
      ref.read(roadmapProvider.notifier).setTargetRole(suggestedRole);
    }

    showCreateRoadmapSheet(
      context,
      analyses: analyses,
      roleMatch: roleMatch,
      selectedRole: suggestedRole.isNotEmpty ? suggestedRole : roadmapState.selectedTargetRole,
      isGenerating: roadmapState.isGenerating,
      onGenerate: (role) => generateAndOpenRoadmap(context, ref, role, repoId: widget.repoId),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Role Match Card Widget
// ─────────────────────────────────────────────────────────────────────────────
class _RoleMatchCard extends StatelessWidget {
  const _RoleMatchCard({
    required this.analysis,
    required this.roleMatch,
    required this.isLoading,
    required this.onCreateRoadmap,
    required this.onRetry,
  });

  final AnalysisModel analysis;
  final RoleMatchModel? roleMatch;
  final bool isLoading;
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
          else if (roleMatch != null && roleMatch!.topRole.isNotEmpty) ...[
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

  Widget _buildRoleMatchContent(BuildContext context, RoleMatchModel rm) {
    final top = rm.topMatch;
    final matchScore = top?.matchScore ?? 0.0;
    final matchLevel = top?.matchLevel ?? '';
    final matchLevelLabel = top?.matchLevelLabel ?? matchLevel;
    final levelColor = _matchLevelColor(context, matchLevel);
    final levelVariant = _matchLevelVariant(matchLevel);

    // Gather skill lists preferring top-level lists, fallback to first match's lists
    final matchedSkills = rm.topMatchedSkills.isNotEmpty ? rm.topMatchedSkills : (top?.matchedSkills ?? []);
    final missingSkills = rm.topMissingSkills.isNotEmpty ? rm.topMissingSkills : (top?.missingSkills ?? []);
    final nextSkills = rm.recommendedNextSkills.isNotEmpty ? rm.recommendedNextSkills : (top?.recommendedNextSkills ?? []);

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
                    rm.topRole,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            
          ],
        ),
        

        

        
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
