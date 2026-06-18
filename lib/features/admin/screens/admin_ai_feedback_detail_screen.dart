import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/format_utils.dart';
import '../../../shared/widgets/async_content.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_detail_widgets.dart';
import '../widgets/admin_widgets.dart';

class AdminAiFeedbackDetailScreen extends ConsumerStatefulWidget {
  const AdminAiFeedbackDetailScreen({super.key, required this.feedbackId});

  final String feedbackId;

  @override
  ConsumerState<AdminAiFeedbackDetailScreen> createState() => _AdminAiFeedbackDetailScreenState();
}

class _AdminAiFeedbackDetailScreenState extends ConsumerState<AdminAiFeedbackDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminFeedbackDetailProvider.notifier).load(widget.feedbackId));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminFeedbackDetailProvider);
    final feedback = state.feedback;

    return AsyncPageBody(
      isLoading: state.isLoading,
      hasData: feedback != null,
      error: state.error,
      onRetry: () => ref.read(adminFeedbackDetailProvider.notifier).load(widget.feedbackId),
      child: feedback == null
          ? const SizedBox.shrink()
          : ListView(
              padding: appScreenPadding(context),
              children: [
                AdminSectionHeader(
                  title: feedback.repoName,
                  subtitle: 'Chi tiết phản hồi AI cho repository.',
                  trailing: PrimaryButton(
                    label: 'Làm mới',
                    icon: Icons.refresh,
                    outlined: true,
                    onPressed: () => ref.read(adminFeedbackDetailProvider.notifier).load(widget.feedbackId),
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(child: Text('Tổng quan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
                          AppBadge(label: feedback.careerDirection, variant: AppBadgeVariant.info),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        feedback.summary.isNotEmpty ? feedback.summary : 'Chưa có tóm tắt.',
                        style: const TextStyle(color: AppColors.slate600, height: 1.45),
                      ),
                      const SizedBox(height: 12),
                      adminDetailRow('Người dùng', feedback.ownerName),
                      if (feedback.ownerEmail != null) adminDetailRow('Email', feedback.ownerEmail!),
                      adminDetailRow('Loại dự án', feedback.projectType ?? 'Chưa rõ'),
                      adminDetailRow('Ngày tạo', formatDate(feedback.createdAt ?? feedback.generatedAt)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AdminTextListCard(title: 'Điểm mạnh', items: feedback.strengthFeedback, variant: AppBadgeVariant.success),
                const SizedBox(height: 12),
                AdminTextListCard(title: 'Điểm cần cải thiện', items: feedback.weaknessFeedback, variant: AppBadgeVariant.warning),
                const SizedBox(height: 12),
                AdminTextListCard(title: 'Bước tiếp theo', items: feedback.nextSteps, variant: AppBadgeVariant.info),
                const SizedBox(height: 12),
                AdminTextListCard(title: 'Chủ đề nên học', items: feedback.recommendedTopics),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Lời khuyên học tập', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(
                        feedback.learningAdvice ?? 'Chưa có lời khuyên học tập.',
                        style: const TextStyle(color: AppColors.slate600, height: 1.45),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Gợi ý nghề nghiệp', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(feedback.careerSuggestion ?? 'Chưa có gợi ý nghề nghiệp.', style: const TextStyle(color: AppColors.slate600, height: 1.45)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Gợi ý portfolio', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(feedback.portfolioAdvice ?? 'Chưa có gợi ý portfolio.', style: const TextStyle(color: AppColors.slate600, height: 1.45)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AdminTextListCard(title: 'Rủi ro cần lưu ý', items: feedback.riskNotes, variant: AppBadgeVariant.warning),
              ],
            ),
    );
  }
}
