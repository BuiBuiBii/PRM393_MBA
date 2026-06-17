import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../shared/widgets/roadmap_widgets.dart';
import '../../app_providers.dart';
import '../../../shared/models/app_models.dart';
import '../data/roadmap_mock_data.dart';
import '../../../shared/widgets/app_widgets.dart';

List<RoadmapModel> _filterRoadmaps(RoadmapState state) {
  return state.roadmaps.where((r) {
    final f = state.filters;
    if (f.search.isNotEmpty) {
      final q = f.search.toLowerCase();
      if (![r.title, r.subtitle, ...r.tags].any((v) => v.toLowerCase().contains(q))) return false;
    }
    if (f.category != 'All' && r.category != f.category) return false;
    if (f.difficulty != 'All' && r.difficulty != f.difficulty) return false;
    if (f.duration == 'Short' && r.estimatedWeeks > 6) return false;
    if (f.duration == 'Medium' && (r.estimatedWeeks <= 6 || r.estimatedWeeks > 10)) return false;
    if (f.duration == 'Long' && r.estimatedWeeks <= 10) return false;
    return true;
  }).toList();
}

class RoadmapsScreen extends ConsumerStatefulWidget {
  const RoadmapsScreen({super.key});

  @override
  ConsumerState<RoadmapsScreen> createState() => _RoadmapsScreenState();
}

class _RoadmapsScreenState extends ConsumerState<RoadmapsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(roadmapProvider.notifier).loadRoadmaps());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(roadmapProvider);
    final filtered = _filterRoadmaps(state);
    final featured = filtered.where((r) => r.isFeatured).toList();
    final ai = filtered.where((r) => r.isAIRecommended).toList();

    return ListView(
      padding: appScreenPadding(context),
      children: [
        const AppBadge(label: 'Lộ trình học bằng AI', variant: AppBadgeVariant.info),
        const SizedBox(height: 8),
        PageHeader(
          title: 'Lộ trình học',
          subtitle: 'Chọn lộ trình thủ công hoặc tạo từ kết quả phân tích GitHub.',
          trailing: PrimaryButton(
            label: 'Tạo roadmap AI',
            icon: Icons.psychology,
            expand: isCompactPhone(context),
            onPressed: () => context.push('/roadmaps/ai'),
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Tìm roadmap, kỹ năng...'),
                onChanged: (v) => ref.read(roadmapProvider.notifier).setFilters(state.filters.copyWith(search: v)),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: state.filters.category,
                decoration: const InputDecoration(labelText: 'Danh mục'),
                items: roadmapCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => ref.read(roadmapProvider.notifier).setFilters(state.filters.copyWith(category: v ?? 'All')),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _section(context, 'Roadmap nổi bật', featured),
        const SizedBox(height: 16),
        _section(context, 'Đề xuất bởi AI', ai),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Xu hướng kỹ năng', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['GitHub Actions', 'PostgreSQL', 'Playwright', 'Docker', 'System Design']
                    .map((s) => AppBadge(label: s, variant: AppBadgeVariant.info))
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _section(BuildContext context, String title, List<RoadmapModel> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)), AppBadge(label: '${items.length} lộ trình')],
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const EmptyState(title: 'Không có roadmap phù hợp')
        else
          ...items.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  onTap: () => context.push('/roadmaps/${r.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
                          if (r.isAIRecommended) const AppBadge(label: 'AI', variant: AppBadgeVariant.info),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(r.subtitle, style: const TextStyle(color: AppColors.slate500, fontSize: 13)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          AppBadge(label: r.category),
                          AppBadge(label: r.difficulty),
                          AppBadge(label: '${r.estimatedWeeks} tuần'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(value: r.progress / 100, backgroundColor: Colors.grey.shade200, color: AppColors.primary),
                      const SizedBox(height: 4),
                      Text('${r.progress}% hoàn thành'),
                    ],
                  ),
                ),
              )),
      ],
    );
  }
}

class AIRoadmapScreen extends ConsumerStatefulWidget {
  const AIRoadmapScreen({super.key});

  @override
  ConsumerState<AIRoadmapScreen> createState() => _AIRoadmapScreenState();
}

class _AIRoadmapScreenState extends ConsumerState<AIRoadmapScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(roadmapProvider.notifier).loadRoadmaps());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(roadmapProvider);
    final rec = state.aiRecommendation;

    if (state.isLoading && rec == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: appScreenPadding(context),
      children: [
        TextButton.icon(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back), label: const Text('Lộ trình')),
        PageHeader(
          title: 'Roadmap bằng AI',
          subtitle: 'Được tạo từ phân tích repository GitHub của bạn.',
          trailing: PrimaryButton(
            label: 'Tạo lại',
            loading: state.isGenerating,
            onPressed: state.isGenerating ? null : () async {
              try {
                await ref.read(roadmapProvider.notifier).generateAI(forceRegenerate: true);
                if (!context.mounted) return;
                context.go('/roadmaps');
              } catch (_) {}
            },
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Vai trò mục tiêu', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: state.selectedTargetRole,
                isExpanded: true,
                items: AppConfig.targetRoles.map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
                onChanged: state.isGenerating ? null : (value) {
                  if (value != null) ref.read(roadmapProvider.notifier).setTargetRole(value);
                },
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: rec == null ? 'Tạo roadmap AI' : 'Tạo roadmap mới',
                icon: Icons.psychology,
                expand: true,
                loading: state.isGenerating,
                onPressed: state.isGenerating ? null : () async {
                  try {
                    await ref.read(roadmapProvider.notifier).generateAI();
                    if (!context.mounted) return;
                    context.go('/roadmaps');
                  } catch (_) {}
                },
              ),
            ],
          ),
        ),
        if (state.error != null) ...[
          const SizedBox(height: 12),
          AppCard(child: Text(state.error!, style: const TextStyle(color: AppColors.amber))),
        ],
        if (rec != null) ...[
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Độ tin cậy', style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    AppBadge(label: '${rec.confidence}%', variant: AppBadgeVariant.success),
                  ],
                ),
                const SizedBox(height: 8),
                Text(rec.summary),
                const SizedBox(height: 12),
                Text('Hướng đề xuất: ${rec.careerSuggestion}', style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _bulletCard('Điểm mạnh', rec.strengths, AppColors.emerald),
          const SizedBox(height: 12),
          _bulletCard('Điểm yếu', rec.weaknesses, AppColors.amber),
          const SizedBox(height: 12),
          _bulletCard('Kỹ năng thiếu', rec.missingSkills, AppColors.primary),
          const SizedBox(height: 16),
          RoadmapTreeWidget(
            roadmap: rec.roadmap,
            onStatusChange: (nodeId, status) => ref.read(roadmapProvider.notifier).updateNodeStatus(rec.roadmap.id, nodeId, status),
            onBookmarkToggle: (nodeId) => ref.read(roadmapProvider.notifier).toggleBookmark(nodeId),
            isBookmarked: (nodeId) => ref.read(roadmapProvider.notifier).isBookmarked(nodeId),
          ),
          const SizedBox(height: 16),
          LearningTimelineWidget(roadmap: rec.roadmap),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Xem roadmap đề xuất', expand: true, onPressed: () => context.push('/roadmaps/${rec.roadmap.id}')),
        ],
      ],
    );
  }

  Widget _bulletCard(String title, List<String> items, Color color) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 8),
          ...items.map((e) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('• $e'))),
        ],
      ),
    );
  }
}

class RoadmapDetailScreen extends ConsumerStatefulWidget {
  const RoadmapDetailScreen({super.key, required this.roadmapId});

  final String roadmapId;

  @override
  ConsumerState<RoadmapDetailScreen> createState() => _RoadmapDetailScreenState();
}

class _RoadmapDetailScreenState extends ConsumerState<RoadmapDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (ref.read(roadmapProvider.notifier).getById(widget.roadmapId) == null) {
        await ref.read(roadmapProvider.notifier).fetchRoadmap(widget.roadmapId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final roadmapState = ref.watch(roadmapProvider);
    final roadmap = ref.read(roadmapProvider.notifier).getById(widget.roadmapId);
    if (roadmap == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final progress = ref.read(roadmapProvider.notifier).progressFor(roadmap);
    final notifier = ref.read(roadmapProvider.notifier);

    return ListView(
      padding: appScreenPadding(context),
      children: [
        TextButton.icon(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back), label: const Text('Lộ trình')),
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
                            if (context.mounted) context.go('/roadmaps');
                          } catch (_) {}
                        },
                ),
        ),
        if (roadmap.isArchived) const AppBadge(label: 'Đã lưu trữ', variant: AppBadgeVariant.warning),
        const SizedBox(height: 8),
        Text(roadmap.description),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            AppBadge(label: roadmap.category),
            AppBadge(label: roadmap.difficulty),
            AppBadge(label: '${roadmap.estimatedHours} giờ'),
            AppBadge(label: '${progress.hoursRemaining}h còn lại'),
            AppBadge(label: roadmap.careerOutcome, variant: AppBadgeVariant.info),
          ],
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: roadmap.progress / 100,
          minHeight: 8,
          borderRadius: BorderRadius.circular(8),
          color: AppColors.primary,
        ),
        const SizedBox(height: 4),
        Text('${roadmap.progress}% hoàn thành • ${progress.completed}/${progress.total} node'),
        const SizedBox(height: 16),
        const Text('Cây lộ trình', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        RoadmapTreeWidget(
          roadmap: roadmap,
          onStatusChange: (nodeId, status) => notifier.updateNodeStatus(roadmap.id, nodeId, status),
          onBookmarkToggle: notifier.toggleBookmark,
          isBookmarked: notifier.isBookmarked,
        ),
        const SizedBox(height: 16),
        LearningTimelineWidget(roadmap: roadmap),
      ],
    );
  }
}
