import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_providers.dart';
import '../../../shared/utils/format_utils.dart';
import '../../../shared/widgets/app_widgets.dart';

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
    final analysis = state.analyses.where((a) => a.repositoryId == widget.repoId || a.id == widget.repoId).firstOrNull;
    final feedback = state.feedbackFor(widget.repoId);

    if (analysis == null) {
      return ListView(
        padding: appScreenPadding(context),
        children: [
          TextButton.icon(
            onPressed: () => context.go('/repositories'),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Repositories'),
          ),
          const SizedBox(height: 24),
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
        TextButton.icon(
          onPressed: () => context.go('/repositories'),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Repositories'),
        ),
        PageHeader(title: analysis.repositoryName, subtitle: '${analysis.projectType} • ${scoreLabel(analysis.scores.overall)}'),
        const SizedBox(height: 8),
        Center(
          child: Column(
            children: [
              Text(
                '${analysis.scores.overall}',
                style: TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: scoreColor(analysis.scores.overall)),
              ),
              const Text('Điểm tổng quan'),
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
              const Text('Chi tiết điểm', style: TextStyle(fontWeight: FontWeight.w600)),
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
                          Text(s.$1),
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
        if (analysis.careerDirection != null) ...[
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Hướng nghề nghiệp', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(analysis.careerDirection!),
              ],
            ),
          ),
        ],
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
                  Text(feedback.learningAdvice, style: const TextStyle(color: AppColors.slate500)),
                ],
                if (feedback.nextSteps.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...feedback.nextSteps.map((step) => Text('• $step')),
                ],
              ] else
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Chưa có AI feedback cho repository này.', style: TextStyle(color: AppColors.slate500)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(label: 'Hỏi AI Mentor', icon: Icons.chat, expand: true, onPressed: () => context.go('/chat')),
      ],
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
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Text('Không có dữ liệu', style: TextStyle(color: AppColors.slate500))
          else
            ...items.map((e) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('• $e'))),
        ],
      ),
    );
  }
}
