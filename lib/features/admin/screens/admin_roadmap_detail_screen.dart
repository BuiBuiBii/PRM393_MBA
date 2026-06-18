import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/format_utils.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/async_content.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../models/admin_models.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_widgets.dart';

class AdminRoadmapDetailScreen extends ConsumerStatefulWidget {
  const AdminRoadmapDetailScreen({super.key, required this.roadmapId});

  final String roadmapId;

  @override
  ConsumerState<AdminRoadmapDetailScreen> createState() => _AdminRoadmapDetailScreenState();
}

class _AdminRoadmapDetailScreenState extends ConsumerState<AdminRoadmapDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminRoadmapDetailProvider.notifier).load(widget.roadmapId));
  }

  Future<void> _toggleStatus(AdminRoadmapRecord roadmap) async {
    final next = roadmap.status == 'active' ? 'archived' : 'active';
    await ref.read(adminRoadmapDetailProvider.notifier).updateStatus(widget.roadmapId, next);
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
      onRetry: () => ref.read(adminRoadmapDetailProvider.notifier).load(widget.roadmapId),
      child: roadmap == null
          ? const SizedBox.shrink()
          : ListView(
              padding: appScreenPadding(context),
              children: [
                AdminSectionHeader(
                  title: roadmap.title,
                  subtitle: 'Mục tiêu: ${roadmap.targetRole}',
                  trailing: PrimaryButton(
                    label: roadmap.status == 'active' ? 'Ẩn roadmap' : 'Khôi phục',
                    icon: roadmap.status == 'active' ? Icons.archive_outlined : Icons.unarchive_outlined,
                    outlined: roadmap.status == 'active',
                    loading: state.isSaving,
                    onPressed: state.isSaving ? null : () => _toggleStatus(roadmap),
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
                    _StatCard(label: 'Giai đoạn', value: '${roadmap.phaseCount}'),
                    _StatCard(label: 'Việc học', value: '${roadmap.taskCount}'),
                    _StatCard(label: 'Giờ ước tính', value: '${roadmap.hourCount}'),
                    _StatCard(label: 'Repositories', value: '${roadmap.repositoriesCount}'),
                  ],
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text('Tổng quan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                          ),
                          adminStatusLabel(roadmap.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        roadmap.summary?.isNotEmpty == true
                            ? roadmap.summary!
                            : 'Roadmap này chưa có phần tóm tắt.',
                        style: const TextStyle(color: AppColors.slate600, height: 1.45),
                      ),
                      const SizedBox(height: 16),
                      _row('Người tạo', roadmap.ownerName),
                      if (roadmap.ownerEmail != null) _row('Email', roadmap.ownerEmail!),
                      _row('Tạo lúc', formatDate(roadmap.createdAt)),
                      _row('Cập nhật', formatDate(roadmap.updatedAt)),
                    ],
                  ),
                ),
                if (roadmap.currentGithubDirection?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Định hướng GitHub hiện tại', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text(roadmap.currentGithubDirection!, style: const TextStyle(color: AppColors.slate600, height: 1.45)),
                      ],
                    ),
                  ),
                ],
                if (roadmap.sourceContextSummary != null) ...[
                  const SizedBox(height: 12),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ngữ cảnh GitHub', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        const Text('Kỹ năng phát hiện', style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.emerald)),
                        const SizedBox(height: 6),
                        _skillWrap(roadmap.sourceContextSummary!.detectedSkills),
                        const SizedBox(height: 12),
                        const Text('Kỹ năng thiếu', style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.amber)),
                        const SizedBox(height: 6),
                        _skillWrap(roadmap.sourceContextSummary!.missingSkills),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  roadmap.mainPath?.title ?? 'Lộ trình chính',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                if (roadmap.mainPath?.reason?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(roadmap.mainPath!.reason!, style: const TextStyle(color: AppColors.slate500)),
                ],
                const SizedBox(height: 12),
                if (roadmap.mainPath?.phases.isEmpty ?? true)
                  const AppCard(
                    child: Text('Chưa có giai đoạn học.', style: TextStyle(color: AppColors.slate500)),
                  )
                else
                  ...roadmap.mainPath!.phases.asMap().entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _PhaseCard(index: entry.key + 1, phase: entry.value),
                        ),
                      ),
                if (roadmap.supportingPaths.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Lộ trình bổ trợ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  ...roadmap.supportingPaths.map(
                    (path) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(path.title ?? 'Lộ trình phụ', style: const TextStyle(fontWeight: FontWeight.w600)),
                            if (path.reason?.isNotEmpty == true) ...[
                              const SizedBox(height: 6),
                              Text(path.reason!, style: const TextStyle(color: AppColors.slate500)),
                            ],
                            const SizedBox(height: 8),
                            Text('${path.phases.length} giai đoạn', style: const TextStyle(color: AppColors.slate500, fontSize: 12)),
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

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: AppColors.slate500, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _skillWrap(List<String> skills) {
    if (skills.isEmpty) {
      return const Text('Không có dữ liệu', style: TextStyle(color: AppColors.slate500, fontSize: 13));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skills.map((s) => AppBadge(label: s)).toList(),
    );
  }
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
          Text(label, style: const TextStyle(color: AppColors.slate500, fontSize: 12)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
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
                backgroundColor: const Color(0xFFE0E7FF),
                child: Text('$index', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(phase.title ?? 'Giai đoạn $index', style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              if (phase.status != null) AppBadge(label: phase.status!, variant: AppBadgeVariant.neutral),
            ],
          ),
          if (phase.goal?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(phase.goal!, style: const TextStyle(color: AppColors.slate600, height: 1.4)),
          ],
          if (phase.skills.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: phase.skills.map((s) => AppBadge(label: s, variant: AppBadgeVariant.info)).toList(),
            ),
          ],
          if (phase.tasks.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Việc học', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
            const SizedBox(height: 6),
            ...phase.tasks.map(
              (task) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.title ?? 'Nhiệm vụ', style: const TextStyle(fontWeight: FontWeight.w500)),
                    if (task.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(task.description!, style: const TextStyle(color: AppColors.slate500, fontSize: 13)),
                    ],
                    if (task.estimatedHours > 0) ...[
                      const SizedBox(height: 4),
                      Text('${task.estimatedHours} giờ', style: const TextStyle(color: AppColors.slate500, fontSize: 12)),
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
