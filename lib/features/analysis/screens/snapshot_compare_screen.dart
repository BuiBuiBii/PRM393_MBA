import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../providers/snapshot_provider.dart';

class SnapshotCompareScreen extends ConsumerStatefulWidget {
  const SnapshotCompareScreen({super.key, required this.repoId});

  final String repoId;

  @override
  ConsumerState<SnapshotCompareScreen> createState() => _SnapshotCompareScreenState();
}

class _SnapshotCompareScreenState extends ConsumerState<SnapshotCompareScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(snapshotProvider.notifier).fetchProgressComparison(widget.repoId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(snapshotProvider);
    final comparison = state.getProgressComparison(widget.repoId);
    final isComparing = state.comparingSnapshots;
    final error = state.error;

    return isComparing
        ? const Center(child: CircularProgressIndicator())
        : error != null && comparison == null
            ? Center(child: Text(error, style: const TextStyle(color: AppColors.rose)))
            : comparison == null
                ? const Center(child: Text('Không đủ dữ liệu để so sánh.'))
                : _buildComparison(context, comparison);
  }

  Widget _buildComparison(BuildContext context, dynamic comparison) {
    final comp = comparison;

    final changeColor = comp.overallChange > 0
        ? AppColors.emerald
        : (comp.overallChange < 0 ? AppColors.rose : context.appTextSecondary);
        
    final changeIcon = comp.overallChange > 0 
        ? Icons.arrow_upward
        : (comp.overallChange < 0 ? Icons.arrow_downward : Icons.horizontal_rule);

    final sign = comp.overallChange > 0 ? '+' : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Score change card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('Tổng quan điểm số', style: context.appCaptionStyle.copyWith(fontSize: 14)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _scoreWidget(context, 'Điểm trước', comp.overallBefore),
                      Icon(Icons.arrow_forward_rounded, color: context.appTextSecondary.withValues(alpha: 0.5), size: 24),
                      _scoreWidget(context, 'Điểm sau', comp.overallAfter),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: changeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(changeIcon, color: changeColor, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Đã thay đổi: $sign${comp.overallChange.toStringAsFixed(1)} điểm',
                          style: TextStyle(
                            color: changeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          if (comp.summary.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.insights, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      comp.summary,
                      style: TextStyle(color: Colors.blue.shade900, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (comp.resolvedMissingSkills.isNotEmpty) ...[
            _buildSectionCard(
              context: context,
              title: 'Kỹ năng đã khắc phục',
              icon: Icons.check_circle,
              iconColor: AppColors.emerald,
              skills: comp.resolvedMissingSkills,
              bgColor: AppColors.emerald.withValues(alpha: 0.1),
              textColor: Colors.green.shade800,
            ),
            const SizedBox(height: 16),
          ],
          
          if (comp.remainingMissingSkills.isNotEmpty) ...[
            _buildSectionCard(
              context: context,
              title: 'Kỹ năng vẫn còn thiếu',
              icon: Icons.warning_rounded,
              iconColor: AppColors.amber,
              skills: comp.remainingMissingSkills,
              bgColor: AppColors.amber.withValues(alpha: 0.1),
              textColor: Colors.amber.shade900,
            ),
            const SizedBox(height: 16),
          ],
          
          if (comp.newMissingSkills.isNotEmpty) ...[
             _buildSectionCard(
              context: context,
              title: 'Vấn đề/Kỹ năng thiếu mới phát sinh',
              icon: Icons.error_outline,
              iconColor: AppColors.rose,
              skills: comp.newMissingSkills,
              bgColor: AppColors.rose.withValues(alpha: 0.1),
              textColor: Colors.red.shade900,
            ),
          ],
        ],
      ),
    );
  }

  Widget _scoreWidget(BuildContext context, String label, double score) {
    return Column(
      children: [
        Text(score.toStringAsFixed(1), style: context.appHeadingStyle.copyWith(fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(label, style: context.appLabelStyle),
      ],
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<String> skills,
    required Color bgColor,
    required Color textColor,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Text(title, style: context.appSectionTitleStyle),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills.map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(s, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500)),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
