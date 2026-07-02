import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_utils.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/app_models.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../../app_providers.dart';

class RoadmapLearningItemScreen extends ConsumerStatefulWidget {
  const RoadmapLearningItemScreen({
    super.key,
    required this.roadmapId,
    required this.itemId,
    this.generateOnOpen = false,
  });

  final String roadmapId;
  final String itemId;
  final bool generateOnOpen;

  @override
  ConsumerState<RoadmapLearningItemScreen> createState() => _RoadmapLearningItemScreenState();
}

class _RoadmapLearningItemScreenState extends ConsumerState<RoadmapLearningItemScreen> {
  RoadmapLearningItemResponse? _item;
  bool _loading = true;
  bool _markingComplete = false;
  bool _generatedFromRoute = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _load(generate: widget.generateOnOpen, fromRoute: true));
  }

  Future<void> _load({bool generate = false, bool fromRoute = false}) async {
    final shouldGenerate = generate && !(fromRoute && _generatedFromRoute);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(appApiProvider);
      final item = shouldGenerate
          ? await safeRequest(
              () => api.generateRoadmapLearningItem(
                roadmapId: widget.roadmapId,
                itemId: widget.itemId,
                forceRegenerate: false,
                includeResources: true,
              ),
            )
          : await safeRequest(
              () => api.getRoadmapLearningItem(
                roadmapId: widget.roadmapId,
                itemId: widget.itemId,
                includeResources: true,
              ),
            );
      if (!mounted) return;
      setState(() {
        _item = item;
        _loading = false;
        if (shouldGenerate && fromRoute) _generatedFromRoute = true;
      });
      ref.invalidate(roadmapLearningProvider(widget.roadmapId));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _learningErrorMessage(getApiErrorMessage(e));
        if (shouldGenerate && fromRoute) _generatedFromRoute = true;
      });
    }
  }

  Future<void> _markComplete() async {
    setState(() => _markingComplete = true);
    try {
      await safeRequest(
        () => ref.read(appApiProvider).updateRoadmapProgressItem(
              roadmapId: widget.roadmapId,
              itemId: widget.itemId,
              status: 'completed',
              progressPercent: 100,
            ),
      );
      if (!mounted) return;
      setState(() => _markingComplete = false);
      ref.invalidate(roadmapProgressProvider(widget.roadmapId));
      AppSnackbar.show(context, message: 'Da danh dau hoan thanh', variant: AppSnackVariant.success);
    } catch (e) {
      if (!mounted) return;
      setState(() => _markingComplete = false);
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
          PrimaryButton(label: 'Tai lai noi dung', icon: Icons.refresh, onPressed: () => _load()),
          const SizedBox(height: 8),
          PrimaryButton(label: 'Tao bai hoc', icon: Icons.auto_awesome, outlined: true, onPressed: () => _load(generate: true)),
        ],
      );
    }

    final item = _item;
    final learning = item?.learning;
    final task = item?.task;
    final contextInfo = item?.personalizedContext;

    return RefreshIndicator(
      onRefresh: () => _load(),
      child: ListView(
        padding: appScreenPadding(context),
        children: [
          PageHeader(
            title: learning?.title ?? task?.title ?? 'Learning item',
            subtitle: task?.skillName ?? task?.canonicalSkillName,
            trailing: PrimaryButton(
              label: 'Hoan thanh',
              icon: Icons.check_circle_outline,
              loading: _markingComplete,
              onPressed: _markComplete,
            ),
          ),
          const SizedBox(height: 12),
          if (task != null) _taskCard(task, item?.progress),
          if (learning == null) ...[
            const SizedBox(height: 12),
            EmptyState(
              title: 'Chua co noi dung hoc',
              subtitle: 'Ban co the tao bai hoc cho task nay.',
              action: PrimaryButton(label: 'Tao bai hoc', icon: Icons.auto_awesome, onPressed: () => _load(generate: true)),
            ),
          ] else ...[
            _textSection('Tong quan', learning.overview),
            _textSection('Vi sao can hoc', learning.whyLearn),
            _textSection('Cach ap dung', learning.howToApply),
            _listSection('Use cases', learning.useCases),
            _listSection('Vi du', learning.examples),
            _listSection('Checklist', learning.checklist),
            _listSection('Bai tap', learning.exercises),
            _listSection('Loi thuong gap', learning.commonMistakes),
            _listSection('Ky nang tiep theo', learning.nextSkills),
            if (learning.resources.isNotEmpty) _resources(learning.resources),
          ],
          if (contextInfo != null) _contextCard(contextInfo),
        ],
      ),
    );
  }

  String _learningErrorMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('gemini') || lower.contains('api key') || lower.contains('llm')) {
      return 'Không tạo được bài học. Có thể BE chưa cấu hình Gemini API key hoặc Gemini lỗi. Vui lòng kiểm tra server.';
    }
    return message;
  }

  Widget _taskCard(RoadmapLearningTask task, RoadmapProgressItem? progress) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(task.title ?? 'Task', style: context.appSectionTitleStyle),
          if ((task.description ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(task.description!, style: context.appCaptionStyle),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if ((task.canonicalSkillName ?? task.skillName ?? '').isNotEmpty)
                AppBadge(label: task.canonicalSkillName ?? task.skillName!, variant: AppBadgeVariant.success),
              if ((task.category ?? '').isNotEmpty) AppBadge(label: task.category!, variant: AppBadgeVariant.info),
              if ((task.targetRole ?? '').isNotEmpty) AppBadge(label: task.targetRole!),
              if ((task.level ?? '').isNotEmpty) AppBadge(label: task.level!),
              if ((task.priority ?? '').isNotEmpty) AppBadge(label: task.priority!, variant: AppBadgeVariant.warning),
              if (task.week != null) AppBadge(label: 'week ${task.week}'),
              if (task.estimatedHours != null) AppBadge(label: '${task.estimatedHours}h'),
              if (progress != null) AppBadge(label: '${progress.status} ${progress.progressPercent}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _textSection(String title, String? text) {
    if ((text ?? '').isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: context.appSectionTitleStyle.copyWith(fontSize: 15)),
            const SizedBox(height: 6),
            Text(text!, style: context.appBodyStyle),
          ],
        ),
      ),
    );
  }

  Widget _listSection(String title, List<String> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: context.appSectionTitleStyle.copyWith(fontSize: 15)),
            const SizedBox(height: 6),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('- $item', style: context.appBodyStyle),
                )),
          ],
        ),
      ),
    );
  }

  Widget _resources(List<LearningResourceItem> resources) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tai nguyen', style: context.appSectionTitleStyle.copyWith(fontSize: 15)),
            const SizedBox(height: 8),
            ...resources.map((resource) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(resource.title ?? resource.url ?? 'Resource', style: context.appBodyStyle.copyWith(fontWeight: FontWeight.w600)),
                      if ((resource.type ?? '').isNotEmpty || (resource.source ?? '').isNotEmpty)
                        Text([resource.type, resource.source].where((e) => (e ?? '').isNotEmpty).join(' - '), style: context.appLabelStyle),
                      if ((resource.url ?? '').isNotEmpty) Text(resource.url!, style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _contextCard(RoadmapPersonalizedContext info) {
    final chips = [
      info.sourceMode,
      info.repoName,
      info.projectType,
      ...info.repositoryNames,
    ].whereType<String>().where((e) => e.isNotEmpty).toList();
    if (chips.isEmpty && (info.practiceTask ?? '').isEmpty && (info.roadmapReason ?? '').isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ngu canh ca nhan hoa', style: context.appSectionTitleStyle.copyWith(fontSize: 15)),
            if (chips.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: chips.map((e) => AppBadge(label: e)).toList()),
            ],
            if ((info.practiceTask ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(info.practiceTask!, style: context.appBodyStyle),
            ],
            if ((info.roadmapReason ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(info.roadmapReason!, style: context.appCaptionStyle),
            ],
          ],
        ),
      ),
    );
  }
}
