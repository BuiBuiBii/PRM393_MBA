import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../providers/snapshot_provider.dart';

class SnapshotListScreen extends ConsumerStatefulWidget {
  const SnapshotListScreen({super.key, required this.repoId});

  final String repoId;

  @override
  ConsumerState<SnapshotListScreen> createState() => _SnapshotListScreenState();
}

class _SnapshotListScreenState extends ConsumerState<SnapshotListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(snapshotProvider.notifier).fetchSnapshots(widget.repoId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(snapshotProvider);
    final snapshots = state.getSnapshots(widget.repoId);
    final isLoading = state.isLoadingSnapshots(widget.repoId);

    if (isLoading && snapshots.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshots.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (snapshots.length > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () =>
                    context.push('/repositories/${widget.repoId}/progress'),
                icon: const Icon(Icons.compare_arrows, size: 18),
                label: const Text('So sánh tiến độ'),
              ),
            ),
          ),
        Expanded(child: _buildList(snapshots)),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history, size: 64, color: AppColors.slate300),
          const SizedBox(height: 16),
          Text(
            'Chưa có lịch sử phân tích nào.',
            style: context.appCaptionStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildList(List snapshots) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: snapshots.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final snap = snapshots[index];
        final date = DateTime.tryParse(snap.createdAt) ?? DateTime.now();
        final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: context.appBorderColor),
          ),
          child: InkWell(
            onTap: () {
              context.push('/snapshots/${snap.id}');
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Lần phân tích ngày $formattedDate',
                        style:
                            context.appSectionTitleStyle.copyWith(fontSize: 15),
                      ),
                      const Icon(Icons.chevron_right,
                          color: AppColors.slate400),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStatBadge('Overall', snap.scores.overall),
                      const SizedBox(width: 8),
                      _buildStatBadge('Architecture', snap.scores.architecture),
                      const SizedBox(width: 8),
                      _buildStatBadge('Completeness', snap.scores.completeness),
                    ],
                  ),
                  if (snap.missingSkills.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Skill còn thiếu:',
                      style: context.appCaptionStyle,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: snap.missingSkills.take(3).map<Widget>((s) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            s,
                            style: TextStyle(
                                fontSize: 11, color: Colors.amber.shade800),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatBadge(String label, int score) {
    Color color = AppColors.emerald;
    if (score < 50) {
      color = AppColors.rose;
    } else if (score < 75) color = AppColors.amber;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8)),
          ),
          Text(
            score.toString(),
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
