import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/format_utils.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/async_content.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../models/admin_models.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_widgets.dart';

class AdminRoadmapDetailScreen extends ConsumerStatefulWidget {
  const AdminRoadmapDetailScreen({
    super.key,
    required this.roadmapId,
    this.includeDeleted = false,
  });

  final String roadmapId;
  final bool includeDeleted;

  @override
  ConsumerState<AdminRoadmapDetailScreen> createState() =>
      _AdminRoadmapDetailScreenState();
}

class _AdminRoadmapDetailScreenState
    extends ConsumerState<AdminRoadmapDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref
        .read(adminRoadmapDetailProvider.notifier)
        .load(widget.roadmapId, includeDeleted: widget.includeDeleted));
  }

  Future<void> _toggleStatus(AdminRoadmapRecord roadmap) async {
    final next = roadmap.status == 'active' ? 'archived' : 'active';
    await ref
        .read(adminRoadmapDetailProvider.notifier)
        .updateStatus(widget.roadmapId, next);
    if (!mounted) return;
    final error = ref.read(adminRoadmapDetailProvider).error;
    if (error != null) {
      AppSnackbar.show(context, message: error, variant: AppSnackVariant.error);
      return;
    }
    AppSnackbar.show(
      context,
      message: next == 'archived' ? 'Đã ẩn roadmap' : 'Đã khôi phục roadmap',
      variant: AppSnackVariant.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminRoadmapDetailProvider);
    final roadmap = state.roadmap;

    return AsyncPageBody(
      isLoading: state.isLoading,
      hasData: roadmap != null,
      error: state.error,
      onRetry: () => ref
          .read(adminRoadmapDetailProvider.notifier)
          .load(widget.roadmapId, includeDeleted: widget.includeDeleted),
      child: roadmap == null
          ? const SizedBox.shrink()
          : ListView(
              padding: appScreenPadding(context),
              children: [
                AdminSectionHeader(
                  title: roadmap.title,
                  subtitle: 'Mục tiêu: ${roadmap.targetRole}',
                  trailing: roadmap.isDeleted
                      ? const AppBadge(
                          label: 'Đã xóa',
                          variant: AppBadgeVariant.warning,
                        )
                      : PrimaryButton(
                          label: roadmap.status == 'active'
                              ? 'Ẩn roadmap'
                              : 'Khôi phục',
                          icon: roadmap.status == 'active'
                              ? Icons.archive_outlined
                              : Icons.unarchive_outlined,
                          outlined: roadmap.status == 'active',
                          loading: state.isSaving,
                          onPressed: state.isSaving
                              ? null
                              : () => _toggleStatus(roadmap),
                        ),
                ),
                if (state.error != null) ...[
                  const SizedBox(height: 12),
                  BannerMessage(message: state.error!, isError: true),
                ],
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    _StatCard(
                        label: 'Tiến độ',
                        value: '${roadmap.progressSummary.overallProgress}%'),
                    _StatCard(
                        label: 'Hoàn thành',
                        value: '${roadmap.progressSummary.completedItems}'),
                    _StatCard(
                        label: 'Đang học',
                        value: '${roadmap.progressSummary.inProgressItems}'),
                    _StatCard(
                        label: 'Chờ học',
                        value: '${roadmap.progressSummary.pendingItems}'),
                  ],
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('Tổng quan',
                                style: context.appSectionTitleStyle),
                          ),
                          adminStatusLabel(roadmap.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _row(context, 'Người tạo', roadmap.ownerName),
                      if (roadmap.ownerEmail != null)
                        _row(context, 'Email', roadmap.ownerEmail!),
                      _row(
                        context,
                        'Repository',
                        roadmap.repository?.fullName.isNotEmpty == true
                            ? roadmap.repository!.fullName
                            : 'Repository unavailable',
                      ),
                      if (roadmap.effectiveLevel?.isNotEmpty == true)
                        _row(context, 'Trình độ', roadmap.effectiveLevel!),
                      if (roadmap.durationWeeks != null)
                        _row(context, 'Thời lượng',
                            '${roadmap.durationWeeks} tuần'),
                      if (roadmap.isDeleted)
                        _row(context, 'Đã xóa lúc',
                            formatDate(roadmap.deletedAt)),
                      _row(context, 'Tạo lúc', formatDate(roadmap.createdAt)),
                      _row(context, 'Cập nhật', formatDate(roadmap.updatedAt)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _learningProgressSection(context, roadmap.learningProgress),
                const SizedBox(height: 16),
                Text(
                  roadmap.mainPath?.title ?? 'Lộ trình chính',
                  style: context.appSectionTitleStyle,
                ),
                if (roadmap.mainPath?.reason?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(roadmap.mainPath!.reason!,
                      style: context.appCaptionStyle),
                ],
                const SizedBox(height: 12),
                if (roadmap.mainPath?.phases.isEmpty ?? true)
                  AppCard(
                    child: Text('Chưa có giai đoạn học.',
                        style: context.appCaptionStyle),
                  )
                else
                  ...roadmap.mainPath!.phases.asMap().entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _PhaseCard(
                              index: entry.key + 1, phase: entry.value),
                        ),
                      ),
                if (roadmap.supportingPaths.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Lộ trình bổ trợ', style: context.appSectionTitleStyle),
                  const SizedBox(height: 12),
                  ...roadmap.supportingPaths.map(
                    (path) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(path.title ?? 'Lộ trình phụ',
                                style: context.appSectionTitleStyle),
                            if (path.reason?.isNotEmpty == true) ...[
                              const SizedBox(height: 6),
                              Text(path.reason!,
                                  style: context.appCaptionStyle),
                            ],
                            const SizedBox(height: 8),
                            Text('${path.phases.length} giai đoạn',
                                style: context.appLabelStyle),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 110, child: Text(label, style: context.appLabelStyle)),
          Expanded(
              child: Text(value,
                  style: context.appBodyStyle.copyWith(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _learningProgressSection(
    BuildContext context,
    AdminRoadmapLearningProgress? progress,
  ) {
    if (progress == null) {
      return AppCard(
        child: Text('Không có dữ liệu learning progress.',
            style: context.appCaptionStyle),
      );
    }
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Learning progress', style: context.appSectionTitleStyle),
          const SizedBox(height: 12),
          _featuredLearningItem(context, 'Task hiện tại', progress.currentTask),
          const SizedBox(height: 8),
          _featuredLearningItem(
            context,
            'Task đề xuất tiếp theo',
            progress.nextRecommendedTask,
          ),
          _learningGroup(
              context, 'Hoàn thành gần đây', progress.recentlyCompleted),
          _learningGroup(context, 'Đã hoàn thành', progress.completedTasks),
          _learningGroup(context, 'Đang học', progress.inProgressTasks),
          _learningGroup(context, 'Chưa bắt đầu', progress.pendingTasks),
          _learningGroup(context, 'Tất cả task', progress.items),
          _learningGroup(
            context,
            'Progress không còn task tương ứng',
            progress.orphanProgressItems,
            orphan: true,
          ),
        ],
      ),
    );
  }

  Widget _featuredLearningItem(
    BuildContext context,
    String label,
    AdminRoadmapLearningItem? item,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.appLabelStyle),
        const SizedBox(height: 4),
        Text(
          item == null
              ? 'Không có'
              : '${item.title} • ${_learningStatus(item.status)}',
          style: context.appBodyStyle,
        ),
      ],
    );
  }

  Widget _learningGroup(
    BuildContext context,
    String title,
    List<AdminRoadmapLearningItem> items, {
    bool orphan = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$title (${items.length})', style: context.appLabelStyle),
          const SizedBox(height: 6),
          if (items.isEmpty)
            Text('Không có', style: context.appCaptionStyle)
          else
            ...items.map(
              (item) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: orphan
                      ? AppColors.amber.withValues(alpha: 0.08)
                      : context.appBubbleAiBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.appBorderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(item.title, style: context.appLabelStyle),
                        ),
                        AppBadge(label: _learningStatus(item.status)),
                      ],
                    ),
                    if (item.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(item.description!, style: context.appCaptionStyle),
                    ],
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: (item.progressPercent / 100).clamp(0, 1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        '${item.progressPercent}%',
                        if (item.phase?.isNotEmpty == true) item.phase!,
                        if (item.week != null) 'Tuần ${item.week}',
                        if (item.estimatedHours != null)
                          '${item.estimatedHours} giờ',
                        if (item.priority?.isNotEmpty == true)
                          'Ưu tiên ${item.priority}',
                        if (item.startedAt != null)
                          'Bắt đầu ${formatDate(item.startedAt)}',
                        if (item.completedAt != null)
                          'Xong ${formatDate(item.completedAt)}',
                      ].join(' • '),
                      style: context.appCaptionStyle,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _learningStatus(String status) => switch (status) {
        'completed' => 'Hoàn thành',
        'in_progress' => 'Đang học',
        _ => 'Chưa bắt đầu',
      };
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: context.appLabelStyle),
          const SizedBox(height: 6),
          Text(value, style: context.appHeadingStyle.copyWith(fontSize: 22)),
        ],
      ),
    );
  }
}

class _PhaseCard extends StatelessWidget {
  const _PhaseCard({required this.index, required this.phase});

  final int index;
  final AdminRoadmapPhase phase;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: context.isDarkMode
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : const Color(0xFFE0E7FF),
                child: Text('$index',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(phase.title ?? 'Giai đoạn $index',
                    style: context.appSectionTitleStyle),
              ),
              if (phase.status != null)
                AppBadge(
                    label: phase.status!, variant: AppBadgeVariant.neutral),
            ],
          ),
          if (phase.goal?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(phase.goal!, style: context.appBodyStyle),
          ],
          if (phase.skills.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: phase.skills
                  .map((s) => AppBadge(label: s, variant: AppBadgeVariant.info))
                  .toList(),
            ),
          ],
          if (phase.tasks.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Việc học',
                style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: context.appTextPrimary)),
            const SizedBox(height: 6),
            ...phase.tasks.map(
              (task) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.appBubbleAiBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.appBorderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.title ?? 'Nhiệm vụ',
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: context.appTextPrimary)),
                    if (task.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(task.description!, style: context.appCaptionStyle),
                    ],
                    if (task.estimatedHours > 0) ...[
                      const SizedBox(height: 4),
                      Text('${task.estimatedHours} giờ',
                          style: context.appLabelStyle),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
