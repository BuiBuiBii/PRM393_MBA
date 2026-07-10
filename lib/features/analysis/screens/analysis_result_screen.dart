import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../feature_providers.dart';
import '../../../shared/models/app_models.dart';
import '../../../shared/widgets/scroll_list_hints.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../roadmaps/widgets/roadmap_mobile_widgets.dart';
import '../widgets/analysis_list_card.dart';
import '../widgets/analysis_score_section.dart';
import '../widgets/role_match_card.dart';

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
      final notifier = ref.read(repositoryProvider.notifier);
      if (notifier.getAnalysisById(repoId) == null) notifier.fetchAnalysis(repoId);
      notifier.fetchAiFeedback(repoId);
      notifier.fetchRoleMatches(repoId);
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
      return ScrollListHints(
        child: ListView(
          padding: appScreenPadding(context),
          children: [
            AppCard(
              child: Column(
                children: [
                  const Text('Repository này chưa được phân tích', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
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
        ),
      );
    }

    return ScrollListHints(
      child: ListView(
        padding: appScreenPadding(context),
        children: [
          AnalysisScoreSection(analysis: analysis),
          const SizedBox(height: 12),
          AnalysisListCard(title: 'Điểm mạnh', items: analysis.strengths, icon: Icons.check_circle, color: AppColors.emerald),
          const SizedBox(height: 12),
          AnalysisListCard(title: 'Điểm yếu', items: analysis.weaknesses, icon: Icons.warning_amber, color: AppColors.amber),
          const SizedBox(height: 12),
          AnalysisListCard(title: 'Đề xuất', items: analysis.recommendations, icon: Icons.lightbulb_outline, color: AppColors.primary),
          const SizedBox(height: 12),
          RoleMatchCard(
            analysis: analysis,
            roleMatch: roleMatch,
            isLoading: isLoadingRoleMatch,
            onCreateRoadmap: () => _openCreateRoadmapSheet(roleMatch),
            onRetry: () => ref.read(repositoryProvider.notifier).fetchRoleMatches(widget.repoId),
          ),
          const SizedBox(height: 12),
          _AiFeedbackCard(
            feedback: feedback,
            isGenerating: state.isGeneratingFeedback(widget.repoId),
            onGenerate: () async {
              try {
                await ref.read(repositoryProvider.notifier).generateAiFeedback(widget.repoId);
              } catch (_) {}
            },
          ),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Hỏi AI Mentor', icon: Icons.chat, expand: true, onPressed: () => context.go('/chat')),
        ],
      ),
    );
  }

  void _openCreateRoadmapSheet(RoleMatchModel? roleMatch) {
    final state = ref.read(repositoryProvider);
    final roadmapState = ref.read(roadmapProvider);
    final suggestedRole = roleMatch?.topRole.isNotEmpty == true ? roleMatch!.topRole : roadmapState.selectedTargetRole;

    if (suggestedRole.isNotEmpty && suggestedRole != roadmapState.selectedTargetRole) {
      ref.read(roadmapProvider.notifier).setTargetRole(suggestedRole);
    }

    showCreateRoadmapSheet(
      context,
      analyses: state.analyses,
      roleMatch: roleMatch,
      selectedRole: suggestedRole.isNotEmpty ? suggestedRole : roadmapState.selectedTargetRole,
      isGenerating: roadmapState.isGenerating,
      onGenerate: (role) => generateAndOpenRoadmap(context, ref, role, repoId: widget.repoId),
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
              const Expanded(child: Text('AI Feedback', style: TextStyle(fontWeight: FontWeight.w600))),
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
              child: Text('Chưa có AI feedback cho repository này.', style: context.appCaptionStyle),
            ),
        ],
      ),
    );
  }
}
