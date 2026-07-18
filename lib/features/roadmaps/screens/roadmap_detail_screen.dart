import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/async_content.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/roadmap_widgets.dart';
import '../../../shared/widgets/scroll_list_hints.dart';
import '../../../shared/models/app_models.dart';
import '../../chat/providers/chat_provider.dart';
import '../providers/roadmap_provider.dart';
import '../widgets/roadmap_detail_sections.dart';

class RoadmapDetailScreen extends ConsumerStatefulWidget {
  const RoadmapDetailScreen({super.key, required this.roadmapId});

  final String roadmapId;

  @override
  ConsumerState<RoadmapDetailScreen> createState() =>
      _RoadmapDetailScreenState();
}

Future<void> _confirmDeleteRoadmap(
  BuildContext context,
  RoadmapNotifier notifier,
  RoadmapModel roadmap,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Xóa roadmap?'),
      content: Text(
        'Roadmap "${roadmap.title}" sẽ bị xóa khỏi danh sách của bạn.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Xóa'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  try {
    await notifier.deleteRoadmap(roadmap.id);
    if (context.mounted) context.go('/roadmaps');
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể xóa roadmap.')),
      );
    }
  }
}

class _RoadmapDetailScreenState extends ConsumerState<RoadmapDetailScreen> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(roadmapProvider.notifier).fetchRoadmap(widget.roadmapId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roadmapState = ref.watch(roadmapProvider);
    final roadmap =
        ref.read(roadmapProvider.notifier).getById(widget.roadmapId);
    final notifier = ref.read(roadmapProvider.notifier);

    return AsyncPageBody(
      isLoading: roadmapState.isLoading && roadmap == null,
      hasData: roadmap != null,
      error: roadmapState.error,
      onRetry: () => notifier.fetchRoadmap(widget.roadmapId),
      child: roadmap == null
          ? const SizedBox.shrink()
          : _RoadmapDetailBody(
              roadmap: roadmap,
              roadmapState: roadmapState,
              selectedTab: _selectedTab,
              notifier: notifier,
              onTabSelected: (tab) => setState(() => _selectedTab = tab),
            ),
    );
  }
}

class _RoadmapDetailBody extends ConsumerWidget {
  const _RoadmapDetailBody({
    required this.roadmap,
    required this.roadmapState,
    required this.selectedTab,
    required this.notifier,
    required this.onTabSelected,
  });

  final RoadmapModel roadmap;
  final RoadmapState roadmapState;
  final int selectedTab;
  final RoadmapNotifier notifier;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = notifier.progressFor(roadmap);
    final percent = roadmap.progress;

    return ScrollListHints(
      child: ListView(
        padding: appScreenPadding(context),
        children: [
          PageHeader(
            title: roadmap.title,
            subtitle: roadmap.subtitle,
            trailing: null,
          ),
          RoadmapDetailInfoCard(
              roadmap: roadmap, progress: progress, percent: percent),
          const SizedBox(height: 8),
          PrimaryButton(
            label: 'Hỏi AI về roadmap này',
            outlined: true,
            onPressed: () async {
              try {
                await ref.read(chatProvider.notifier).createSession(
                      'Tư vấn roadmap ${roadmap.careerOutcome.isNotEmpty ? roadmap.careerOutcome : roadmap.title}',
                      roadmapId: roadmap.id,
                    );
                if (context.mounted) context.go('/chat');
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ref.read(chatProvider).error ??
                            'Không thể tạo chat cho roadmap.',
                      ),
                    ),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 8),
          PrimaryButton(
            label: 'Xóa roadmap',
            outlined: true,
            loading: roadmapState.deletingRoadmapId == roadmap.id,
            onPressed: roadmapState.deletingRoadmapId != null
                ? null
                : () => _confirmDeleteRoadmap(context, notifier, roadmap),
          ),
          const SizedBox(height: 16),
          RoadmapDetailTabBar(
              selectedTab: selectedTab, onTabSelected: onTabSelected),
          const SizedBox(height: 16),
          if (selectedTab == 0) ...[
            Text('Cây lộ trình', style: context.appSectionTitleStyle),
            const SizedBox(height: 8),
            RoadmapTreeWidget(
              roadmap: roadmap,
              onStatusChange: (nodeId, status) async {
                try {
                  await notifier.updateNodeStatus(roadmap.id, nodeId, status);
                } catch (_) {}
              },
              onBookmarkToggle: notifier.toggleBookmark,
              isBookmarked: notifier.isBookmarked,
              loadingLearningItemId: roadmapState.openingLearningItemId,
              generatingLearningItemId: roadmapState.generatingLearningItemId,
              onOpenLearning: (node) async {
                try {
                  final learning =
                      await notifier.openLearning(roadmap.id, node.id);
                  if (!context.mounted) return;
                  await showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => FractionallySizedBox(
                      heightFactor: 0.9,
                      child: LearningContentSheet(learning: learning),
                    ),
                  );
                } catch (_) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(roadmapState.learningError ??
                          'Không thể mở nội dung học.'),
                      action: SnackBarAction(
                        label: 'Thử lại',
                        onPressed: () =>
                            notifier.openLearning(roadmap.id, node.id),
                      ),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            LearningTimelineWidget(roadmap: roadmap),
          ],
          if (selectedTab == 1) RoadmapObjectivesTab(roadmap: roadmap),
          if (selectedTab == 2) RoadmapSupportTab(roadmap: roadmap),
        ],
      ),
    );
  }
}
