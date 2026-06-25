import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
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
                          Expanded(child: Text('Tổng quan', style: context.appSectionTitleStyle)),
                          AppBadge(label: feedback.careerDirection, variant: AppBadgeVariant.info),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        feedback.summary.isNotEmpty ? feedback.summary : 'Chưa có tóm tắt.',
                        style: context.appBodyStyle,
                      ),
                      const SizedBox(height: 12),
                      adminDetailRow(context, 'Người dùng', feedback.ownerName),
                      if (feedback.ownerEmail != null) adminDetailRow(context, 'Email', feedback.ownerEmail!),
                      adminDetailRow(context, 'Loại dự án', feedback.projectType ?? 'Chưa rõ'),
                      adminDetailRow(context, 'Ngày tạo', formatDate(feedback.createdAt ?? feedback.generatedAt)),
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
                      Text('Lời khuyên học tập', style: context.appSectionTitleStyle),
                      const SizedBox(height: 8),
                      Text(
                        feedback.learningAdvice ?? 'Chưa có lời khuyên học tập.',
                        style: context.appBodyStyle,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Gợi ý nghề nghiệp', style: context.appSectionTitleStyle),
                      const SizedBox(height: 8),
                      Text(feedback.careerSuggestion ?? 'Chưa có gợi ý nghề nghiệp.', style: context.appBodyStyle),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Gợi ý portfolio', style: context.appSectionTitleStyle),
                      const SizedBox(height: 8),
                      Text(feedback.portfolioAdvice ?? 'Chưa có gợi ý portfolio.', style: context.appBodyStyle),
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
