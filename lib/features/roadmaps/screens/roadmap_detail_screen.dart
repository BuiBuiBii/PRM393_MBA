import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_utils.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/models/app_models.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/roadmap_widgets.dart';
import '../../app_providers.dart';

class RoadmapDetailScreenV2 extends ConsumerStatefulWidget {
  const RoadmapDetailScreenV2({super.key, required this.roadmapId});

  final String roadmapId;

  @override
  ConsumerState<RoadmapDetailScreenV2> createState() => _RoadmapDetailScreenV2State();
}

class _RoadmapDetailScreenV2State extends ConsumerState<RoadmapDetailScreenV2> {
  RoadmapModel? _roadmap;
  RoadmapProgressResponse? _progress;
  RoadmapLearningListResponse? _learning;
  bool _loading = true;
  String? _error;
  String? _updatingItemId;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (AppConfig.demoMode) {
        final roadmap = ref.read(roadmapProvider.notifier).getById(widget.roadmapId);
        if (!mounted) return;
        setState(() {
          _roadmap = roadmap;
          _progress = RoadmapProgressResponse(
            roadmapId: widget.roadmapId,
            progressSummary: RoadmapProgressSummary(
              totalItems: roadmap?.modules.fold<int>(0, (sum, module) => sum + module.nodes.length) ?? 0,
              completedItems: roadmap?.modules.fold<int>(
                    0,
                    (sum, module) => sum + module.nodes.where((node) => node.status == 'completed').length,
                  ) ??
                  0,
              overallProgress: roadmap?.progress ?? 0,
            ),
          );
          _learning = RoadmapLearningListResponse(roadmapId: widget.roadmapId);
          _loading = false;
        });
        return;
      }
      final api = ref.read(appApiProvider);
      final roadmap = await safeRequest(() => api.getRoadmap(widget.roadmapId));
      final progress = await safeRequest(() => api.getRoadmapProgress(roadmap.roadmapId ?? roadmap.id));
      final learning = await safeRequest(() => api.getRoadmapLearning(roadmap.roadmapId ?? roadmap.id));
      if (!mounted) return;
      setState(() {
        _roadmap = roadmap;
        _progress = progress;
        _learning = learning;
        _loading = false;
      });
      ref.invalidate(roadmapProgressProvider(roadmap.roadmapId ?? roadmap.id));
      ref.invalidate(roadmapLearningProvider(roadmap.roadmapId ?? roadmap.id));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = getApiErrorMessage(e);
      });
    }
  }

  Future<void> _updateProgress(_TaskView task, String status, int percent) async {
    final roadmapId = _roadmap?.roadmapId ?? _roadmap?.id ?? widget.roadmapId;
    setState(() => _updatingItemId = task.itemId);
    try {
      final next = await safeRequest(
        () => ref.read(appApiProvider).updateRoadmapProgressItem(
              roadmapId: roadmapId,
              itemId: task.itemId,
              status: status,
              progressPercent: percent,
            ),
      );
      if (!mounted) return;
      setState(() {
        _progress = next;
        _updatingItemId = null;
      });
      ref.invalidate(roadmapProgressProvider(roadmapId));
    } catch (e) {
      if (!mounted) return;
      setState(() => _updatingItemId = null);
      AppSnackbar.show(context, message: getApiErrorMessage(e), variant: AppSnackVariant.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return ListView(
        padding: appScreenPadding(context),
        children: const [
          AppCard(child: Center(child: CircularProgressIndicator())),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        padding: appScreenPadding(context),
        children: [
          BannerMessage(message: _error!, isError: true),
          const SizedBox(height: 12),
          PrimaryButton(label: 'Thu lai', icon: Icons.refresh, onPressed: _load),
        ],
      );
    }

    final roadmap = _roadmap;
    if (roadmap == null) {
      return const SizedBox.shrink();
    }

    final roadmapId = roadmap.roadmapId ?? roadmap.id;
    final tasks = _buildTasks(roadmap, _progress, _learning);
    final summary = _progress?.progressSummary ?? roadmap.progressSummary;
    final percent = summary?.overallProgress ?? 0;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: appScreenPadding(context),
        children: [
          PageHeader(
            title: roadmap.title,
            subtitle: roadmap.careerOutcome,
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if ((roadmap.effectiveLevel ?? '').isNotEmpty) AppBadge(label: roadmap.effectiveLevel!, variant: AppBadgeVariant.success),
                    if ((roadmap.requestedLevel ?? '').isNotEmpty) AppBadge(label: 'requested ${roadmap.requestedLevel}'),
                    if ((roadmap.language ?? '').isNotEmpty) AppBadge(label: roadmap.language!),
                    if ((roadmap.roadmapSourceInfo?.sourceMode ?? '').isNotEmpty)
                      AppBadge(label: roadmap.roadmapSourceInfo!.sourceMode!, variant: AppBadgeVariant.info),
                  ],
                ),
                if ((roadmap.description).isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(roadmap.description, style: context.appBodyStyle),
                ],
                const SizedBox(height: 14),
                RoadmapProgressBar(
                  percent: percent,
                  caption: summary == null
                      ? 'Chua co tien do server'
                      : '${summary.completedItems}/${summary.totalItems} task hoan thanh - ${summary.inProgressItems} dang hoc',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (tasks.isEmpty)
            const EmptyState(title: 'Chua co task', subtitle: 'Roadmap nay chua co mainRoadmap phases/tasks.')
          else
            ...tasks.map((task) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TaskCard(
                    task: task,
                    isUpdating: _updatingItemId == task.itemId,
                    onStart: () => _updateProgress(task, 'in_progress', 50),
                    onComplete: () => _updateProgress(task, 'completed', 100),
                    onReset: () => _updateProgress(task, 'not_started', 0),
                    onLearning: task.learningStatus == null
                        ? null
                        : () {
                            final generate = task.learningStatus == 'missing';
                            context.push('/roadmaps/$roadmapId/learning/${task.itemId}${generate ? '?generate=1' : ''}');
                          },
                  ),
                )),
          if (roadmap.alternativeRoadmaps.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Lo trinh thay the', style: context.appSectionTitleStyle),
            const SizedBox(height: 8),
            ...roadmap.alternativeRoadmaps.map((path) => AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(path.title ?? 'Alternative roadmap', style: context.appSectionTitleStyle.copyWith(fontSize: 14)),
                      if ((path.reason ?? '').isNotEmpty) Text(path.reason!, style: context.appCaptionStyle),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

List<_TaskView> _buildTasks(
  RoadmapModel roadmap,
  RoadmapProgressResponse? progress,
  RoadmapLearningListResponse? learning,
) {
  final List<RoadmapProgressItem> progressItems = progress?.items ?? <RoadmapProgressItem>[];
  final progressById = <String, RoadmapProgressItem>{
    for (final item in progressItems) item.itemId: item,
  };
  final List<RoadmapLearningStatusItem> learningItems = learning?.items ?? <RoadmapLearningStatusItem>[];
  final learningById = <String, RoadmapLearningStatusItem>{
    for (final item in learningItems) item.itemId: item,
  };

  final tasks = <_TaskView>[];
  final phases = roadmap.mainRoadmap?.phases ?? const <Map<String, dynamic>>[];
  for (var phaseIndex = 0; phaseIndex < phases.length; phaseIndex++) {
    final phase = phases[phaseIndex];
    final rawTasks = phase['tasks'];
    if (rawTasks is! List) continue;
    for (final raw in rawTasks.whereType<Map>()) {
      final map = raw.map((key, value) => MapEntry(key.toString(), value));
      final itemId = (map['itemId'] ?? '').toString();
      if (itemId.isEmpty) continue;
      final p = progressById[itemId];
      final l = learningById[itemId];
      tasks.add(_TaskView(
        itemId: itemId,
        phaseTitle: (phase['title'] ?? 'Phase ${phaseIndex + 1}').toString(),
        title: (map['title'] ?? p?.title ?? l?.taskTitle ?? 'Task').toString(),
        description: (map['description'] ?? '').toString(),
        skillName: (map['canonicalSkillName'] ?? map['skillName'] ?? p?.canonicalSkillName ?? p?.skillName ?? l?.canonicalSkillName ?? l?.skillName)?.toString(),
        category: (map['category'] ?? p?.category)?.toString(),
        targetRole: (map['targetRole'] ?? p?.targetRole)?.toString(),
        level: (map['level'] ?? p?.level)?.toString(),
        priority: (map['priority'] ?? p?.priority ?? l?.priority)?.toString(),
        week: int.tryParse((map['week'] ?? l?.week ?? '').toString()),
        estimatedHours: int.tryParse((map['estimatedHours'] ?? '').toString()),
        status: p?.status ?? (map['status'] ?? 'not_started').toString(),
        progressPercent: p?.progressPercent ?? 0,
        learningStatus: l?.learningStatus,
      ));
    }
  }
  return tasks;
}

class _TaskView {
  const _TaskView({
    required this.itemId,
    required this.phaseTitle,
    required this.title,
    required this.description,
    this.skillName,
    this.category,
    this.targetRole,
    this.level,
    this.priority,
    this.week,
    this.estimatedHours,
    required this.status,
    required this.progressPercent,
    this.learningStatus,
  });

  final String itemId;
  final String phaseTitle;
  final String title;
  final String description;
  final String? skillName;
  final String? category;
  final String? targetRole;
  final String? level;
  final String? priority;
  final int? week;
  final int? estimatedHours;
  final String status;
  final int progressPercent;
  final String? learningStatus;
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.isUpdating,
    required this.onStart,
    required this.onComplete,
    required this.onReset,
    required this.onLearning,
  });

  final _TaskView task;
  final bool isUpdating;
  final VoidCallback onStart;
  final VoidCallback onComplete;
  final VoidCallback onReset;
  final VoidCallback? onLearning;

  @override
  Widget build(BuildContext context) {
    final isCompleted = task.status == 'completed';
    final isInProgress = task.status == 'in_progress';
    final learningLabel = switch (task.learningStatus) {
      'available' => 'Hoc ngay',
      'missing' => 'Tao bai hoc',
      _ => 'Chua kiem tra',
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(task.phaseTitle, style: context.appLabelStyle),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(task.title, style: context.appSectionTitleStyle.copyWith(fontSize: 15))),
              AppBadge(label: task.status),
            ],
          ),
          if (task.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(task.description, style: context.appCaptionStyle),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if ((task.skillName ?? '').isNotEmpty) AppBadge(label: task.skillName!, variant: AppBadgeVariant.success),
              if ((task.category ?? '').isNotEmpty) AppBadge(label: task.category!, variant: AppBadgeVariant.info),
              if ((task.level ?? '').isNotEmpty) AppBadge(label: task.level!),
              if ((task.priority ?? '').isNotEmpty) AppBadge(label: task.priority!, variant: AppBadgeVariant.warning),
              if (task.week != null) AppBadge(label: 'week ${task.week}'),
              if (task.estimatedHours != null) AppBadge(label: '${task.estimatedHours}h'),
              if (task.progressPercent > 0) AppBadge(label: '${task.progressPercent}%'),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!isInProgress && !isCompleted)
                PrimaryButton(label: 'Bat dau', outlined: true, loading: isUpdating, onPressed: onStart),
              if (!isCompleted)
                PrimaryButton(label: 'Hoan thanh', outlined: true, loading: isUpdating, onPressed: onComplete),
              if (isCompleted || isInProgress)
                PrimaryButton(label: 'Reset', outlined: true, loading: isUpdating, onPressed: onReset),
              PrimaryButton(
                label: learningLabel,
                icon: task.learningStatus == 'missing' ? Icons.auto_awesome : Icons.menu_book_outlined,
                outlined: task.learningStatus != 'available',
                onPressed: onLearning,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
