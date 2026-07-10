import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../feature_providers.dart';
import '../../../shared/models/app_models.dart';
import '../../../shared/utils/format_utils.dart';
import '../../../shared/widgets/async_content.dart';
import '../../../shared/widgets/scroll_list_hints.dart';
import '../../../shared/widgets/collapsible_list.dart';
import '../../../shared/widgets/app_widgets.dart';

class AiFeedbackDashboardScreen extends ConsumerStatefulWidget {
  const AiFeedbackDashboardScreen({super.key});

  @override
  ConsumerState<AiFeedbackDashboardScreen> createState() => _AiFeedbackDashboardScreenState();
}

class _AiFeedbackDashboardScreenState extends ConsumerState<AiFeedbackDashboardScreen> {
  String _search = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(repositoryProvider.notifier).fetchMyAiFeedbacks());
  }

  Future<void> _reload() => ref.read(repositoryProvider.notifier).fetchMyAiFeedbacks();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(repositoryProvider);
    final keyword = _search.toLowerCase();
    final feedbacks = state.myFeedbacks.where((f) {
      if (keyword.isEmpty) return true;
      return [f.repositoryName, f.summary, f.careerSuggestion, f.learningAdvice]
          .any((v) => (v ?? '').toLowerCase().contains(keyword));
    }).toList();

    return ScrollListHints(
      child: RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        padding: appScreenPadding(context),
        children: [
          PageHeader(
            title: 'AI Feedback',
            subtitle: 'Phản hồi AI cho các repository của bạn.',
            trailing: PrimaryButton(
              label: 'Tải lại',
              icon: Icons.refresh,
              outlined: true,
              loading: state.isLoadingMyFeedbacks,
              expand: isCompactPhone(context),
              onPressed: state.isLoadingMyFeedbacks ? null : _reload,
            ),
          ),
          if (state.error != null) ...[
            const SizedBox(height: 12),
            BannerMessage(message: state.error!, isError: true),
          ],
          const SizedBox(height: 16),
          AppCard(
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Tìm repository, summary...',
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${feedbacks.length} feedback',
              style: context.appCaptionStyle,
            ),
          ),
          const SizedBox(height: 12),
          AsyncListBody(
            isLoading: state.isLoadingMyFeedbacks,
            isEmpty: feedbacks.isEmpty,
            error: state.error,
            onRetry: _reload,
            emptyTitle: 'Chưa có AI feedback',
            emptySubtitle: 'Vào Repositories, phân tích repo rồi bấm Tạo feedback.',
            emptyAction: PrimaryButton(
              label: 'Đến Repositories',
              icon: Icons.folder_outlined,
              onPressed: () => context.go('/repositories'),
            ),
            child: CollapsibleItemList(
              resetKey: keyword,
              initialVisibleCount: 4,
              items: feedbacks,
              itemBuilder: (context, feedback) => _FeedbackCard(
                feedback: feedback,
                onTap: () => context.push('/repositories/${feedback.repositoryId}'),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.feedback, required this.onTap});

  final AiFeedbackModel feedback;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feedback.repositoryName,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                    if (feedback.generatedAt != null && feedback.generatedAt!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        formatRelativeTime(feedback.generatedAt),
                        style: context.appLabelStyle,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.appTextSecondary),
            ],
          ),
          if (feedback.summary.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              feedback.summary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: context.appBodyStyle,
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (feedback.strengthFeedback.isNotEmpty)
                AppBadge(
                  label: '${feedback.strengthFeedback.length} điểm mạnh',
                  variant: AppBadgeVariant.success,
                ),
              if (feedback.weaknessFeedback.isNotEmpty)
                AppBadge(
                  label: '${feedback.weaknessFeedback.length} điểm yếu',
                  variant: AppBadgeVariant.warning,
                ),
              if (feedback.careerSuggestion != null && feedback.careerSuggestion!.isNotEmpty)
                AppBadge(label: feedback.careerSuggestion!, variant: AppBadgeVariant.info),
            ],
          ),
        ],
      ),
    );
  }
}
