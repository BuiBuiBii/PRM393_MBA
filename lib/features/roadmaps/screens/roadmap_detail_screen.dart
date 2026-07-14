import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/async_content.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/roadmap_widgets.dart';
import '../../../shared/widgets/scroll_list_hints.dart';
import '../../../shared/models/app_models.dart';
import '../../repositories/providers/repository_provider.dart';
import '../providers/roadmap_provider.dart';
import '../widgets/roadmap_detail_sections.dart';

class RoadmapDetailScreen extends ConsumerStatefulWidget {
  const RoadmapDetailScreen({super.key, required this.roadmapId});

  final String roadmapId;

  @override
  ConsumerState<RoadmapDetailScreen> createState() =>
      _RoadmapDetailScreenState();
}

class _RoadmapDetailScreenState extends ConsumerState<RoadmapDetailScreen> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (ref.read(roadmapProvider.notifier).getById(widget.roadmapId) ==
          null) {
        await ref.read(roadmapProvider.notifier).fetchRoadmap(widget.roadmapId);
      }
    });
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
    final percent = progress.total == 0
        ? 0
        : ((progress.completed / progress.total) * 100).round();

    return ScrollListHints(
      child: ListView(
        padding: appScreenPadding(context),
        children: [
          PageHeader(
            title: roadmap.title,
            subtitle: roadmap.subtitle,
            trailing: roadmap.isArchived
                ? null
                : PrimaryButton(
                    label: 'Lưu trữ',
                    outlined: true,
                    loading: roadmapState.isArchiving,
                    onPressed: roadmapState.isArchiving
                        ? null
                        : () async {
                            try {
                              await notifier.archiveRoadmap(roadmap.id);
                              if (!context.mounted) return;
                              context.go('/roadmaps');
                            } catch (_) {}
                          },
                  ),
          ),
          if (roadmap.isArchived) ...[
            const AppBadge(
                label: 'Đã lưu trữ', variant: AppBadgeVariant.warning),
            const SizedBox(height: 8),
          ],
          RoadmapDetailInfoCard(
              roadmap: roadmap, progress: progress, percent: percent),
          const SizedBox(height: 8),
          PrimaryButton(
            label: 'Hỏi AI về roadmap này',
            outlined: true,
            onPressed: () => context.push(
                '/chat?roadmapId=${Uri.encodeQueryComponent(roadmap.id)}'),
          ),
          if ((roadmap.roadmapSource?['repositoryId'] ?? '')
              .toString()
              .isNotEmpty) ...[
            const SizedBox(height: 8),
            PrimaryButton(
              label: 'Tạo feedback theo tiến độ roadmap',
              outlined: true,
              onPressed: () async {
                final repositoryId =
                    roadmap.roadmapSource!['repositoryId'].toString();
                try {
                  await ref
                      .read(repositoryProvider.notifier)
                      .generateAiFeedback(repositoryId, roadmapId: roadmap.id);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Đã cập nhật feedback theo roadmap hiện tại.'),
                    ),
                  );
                } catch (_) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ref.read(repositoryProvider).error ??
                            'Không thể tạo feedback theo roadmap.',
                      ),
                    ),
                  );
                }
              },
            ),
          ],
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
