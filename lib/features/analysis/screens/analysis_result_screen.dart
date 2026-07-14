import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../feature_providers.dart';
import '../../../shared/models/app_models.dart';
import '../../../shared/widgets/scroll_list_hints.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../widgets/analysis_list_card.dart';
import '../widgets/analysis_readiness_section.dart';
import '../widgets/analysis_score_section.dart';
import '../widgets/role_match_card.dart';
import '../../roadmaps/models/roadmap_generate_params.dart';
import '../../roadmaps/utils/roadmap_generate_helper.dart';
import '../../roadmaps/widgets/create_roadmap_sheet.dart';

class AnalysisResultScreen extends ConsumerStatefulWidget {
  const AnalysisResultScreen({super.key, required this.repoId});

  final String repoId;

  @override
  ConsumerState<AnalysisResultScreen> createState() =>
      _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends ConsumerState<AnalysisResultScreen> {
  RoleMatchItem? _selectedRoleMatch;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final repoId = widget.repoId;
      final notifier = ref.read(repositoryProvider.notifier);
      final cachedAnalysis = notifier.getAnalysisById(repoId);
      if (cachedAnalysis == null) {
        notifier.fetchAnalysis(repoId);
      } else if (!cachedAnalysis.hasCompleteNarrative) {
        notifier.fetchAnalysis(
          cachedAnalysis.id.isNotEmpty ? cachedAnalysis.id : repoId,
        );
      }
      notifier.fetchAiFeedback(repoId);
      notifier.calculateRoleMatches(sourceMode: 'single_repo', repoId: repoId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(repositoryProvider);
    final analysis = state.analyses
        .where((a) => a.repositoryId == widget.repoId || a.id == widget.repoId)
        .firstOrNull;
    final feedback = state.feedbackFor(widget.repoId);
    final roleMatch = state.roleMatchFor(widget.repoId);
    final isLoadingRoleMatch = state.isLoadingRoleMatch(widget.repoId);
    final roleMatchError = isLoadingRoleMatch
        ? null
        : ref
            .read(repositoryProvider.notifier)
            .roleMatchErrorForKey(widget.repoId);

    if (analysis == null) {
      return ScrollListHints(
        child: ListView(
          padding: appScreenPadding(context),
          children: [
            if (state.error != null) ...[
              BannerMessage(message: state.error!, isError: true),
              const SizedBox(height: 12),
            ],
            AppCard(
              child: Column(
                children: [
                  const Text('Repository này chưa được phân tích',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Chạy phân tích',
                    loading: state.isAnalyzingRepo(widget.repoId),
                    expand: true,
                    onPressed: state.isAnalyzing
                        ? null
                        : () async {
                            try {
                              await ref
                                  .read(repositoryProvider.notifier)
                                  .analyzeRepository(widget.repoId);
                              if (context.mounted) {
                                ref
                                    .read(repositoryProvider.notifier)
                                    .calculateRoleMatches(
                                      sourceMode: 'single_repo',
                                      repoId: widget.repoId,
                                      forceRefresh: true,
                                    );
                              }
                            } catch (_) {
                              if (context.mounted) {
                                AppSnackbar.show(
                                  context,
                                  message: ref.read(repositoryProvider).error ??
                                      'Không thể phân tích repository.',
                                  variant: AppSnackVariant.error,
                                );
                              }
                            }
                          },
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return ScrollListHints(
      child: ListView(
        padding: appScreenPadding(context),
        children: [
          AnalysisScoreSection(analysis: analysis),
          const SizedBox(height: 12),
          AnalysisReadinessSection(analysis: analysis),
          const SizedBox(height: 12),
          AnalysisListCard(
              title: 'Điểm mạnh',
              items: analysis.strengths,
              icon: Icons.check_circle,
              color: AppColors.emerald),
          const SizedBox(height: 12),
          AnalysisListCard(
              title: 'Điểm yếu',
              items: analysis.weaknesses,
              icon: Icons.warning_amber,
              color: AppColors.amber),
          const SizedBox(height: 12),
          AnalysisListCard(
              title: 'Đề xuất',
              items: analysis.recommendations,
              icon: Icons.lightbulb_outline,
              color: AppColors.primary),
          const SizedBox(height: 12),
          RoleMatchCard(
            analysis: analysis,
            roleMatch: roleMatch,
            isLoading: isLoadingRoleMatch,
            errorMessage: roleMatchError,
            onCreateRoadmap: _openCreateRoadmapSheet,
            onRetry: () =>
                ref.read(repositoryProvider.notifier).calculateRoleMatches(
                      sourceMode: 'single_repo',
                      repoId: widget.repoId,
                      forceRefresh: true,
                    ),
            onSelectMatch: (match) =>
                setState(() => _selectedRoleMatch = match),
          ),
          const SizedBox(height: 12),
          _AiFeedbackCard(
            feedback: feedback,
            isGenerating: state.isGeneratingFeedback(widget.repoId),
            onGenerate: () async {
              try {
                await ref
                    .read(repositoryProvider.notifier)
                    .generateAiFeedback(widget.repoId);
              } catch (_) {}
            },
          ),
          const SizedBox(height: 16),
          PrimaryButton(
              label: 'Hỏi AI Mentor',
              icon: Icons.chat,
              expand: true,
              onPressed: () => context.go('/chat')),
        ],
      ),
    );
  }

  void _openCreateRoadmapSheet() {
    final roleMatch = ref.read(repositoryProvider).roleMatchFor(widget.repoId);
    final selected = _selectedRoleMatch ?? roleMatch?.topMatch;
    if (selected != null) {
      ref.read(roadmapProvider.notifier).setTargetRole(selected.role);
    }

    showCreateRoadmapSheet(
      context,
      config: CreateRoadmapSheetConfig(
        sourceMode: 'single_repo',
        repoId: widget.repoId,
        onGenerate: (params) => generateAndOpenRoadmap(
          context,
          ref,
          RoadmapGenerateParams(
            roleId: params.roleId,
            targetRole: params.targetRole,
            sourceMode: 'single_repo',
            repoId: widget.repoId,
            level: params.level,
            durationWeeks: params.durationWeeks,
            language: params.language,
          ),
        ),
      ),
    );
  }
}

class _AiFeedbackCard extends StatelessWidget {
  const _AiFeedbackCard({
    required this.feedback,
    required this.isGenerating,
    required this.onGenerate,
  });

  final AiFeedbackModel? feedback;
  final bool isGenerating;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                  child: Text('AI Feedback',
                      style: TextStyle(fontWeight: FontWeight.w600))),
              PrimaryButton(
                label: feedback == null ? 'Tạo feedback' : 'Tạo lại',
                outlined: true,
                loading: isGenerating,
                onPressed: isGenerating ? null : onGenerate,
              ),
            ],
          ),
          if (feedback != null) ...[
            const SizedBox(height: 8),
            Text(feedback!.summary),
            if (feedback!.learningAdvice.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(feedback!.learningAdvice, style: context.appCaptionStyle),
            ],
            if (feedback!.nextSteps.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...feedback!.nextSteps.map((step) => Text('• $step')),
            ],
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Chưa có AI feedback cho repository này.',
                  style: context.appCaptionStyle),
            ),
        ],
      ),
    );
  }
}
