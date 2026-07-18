import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/app_models.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../auth/providers/auth_provider.dart';

class SnapshotDetailScreen extends ConsumerStatefulWidget {
  const SnapshotDetailScreen({super.key, required this.snapshotId});

  final String snapshotId;

  @override
  ConsumerState<SnapshotDetailScreen> createState() => _SnapshotDetailScreenState();
}

class _SnapshotDetailScreenState extends ConsumerState<SnapshotDetailScreen> {
  RepoAnalysisSnapshotModel? _snapshot;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSnapshot();
  }

  Future<void> _fetchSnapshot() async {
    try {
      final api = ref.read(appApiProvider);
      final snapshot = await api.getSnapshot(widget.snapshotId);
      if (mounted) {
        setState(() {
          _snapshot = snapshot;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.rose)))
            : _snapshot == null
                ? const Center(child: Text('Không tìm thấy snapshot'))
                : _buildBody(context, _snapshot!);
  }

  Widget _buildBody(BuildContext context, RepoAnalysisSnapshotModel snap) {
    final date = DateTime.tryParse(snap.createdAt) ?? DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.history, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Kết quả tại thời điểm phân tích: $formattedDate',
                    style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          Text('Kết quả phân tích', style: context.appHeadingStyle.copyWith(fontSize: 18)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildScoreCard(
                  context,
                  'Sẵn sàng',
                  snap.readinessScore,
                  AppColors.primary,
                ),
              ),
              if (snap.userLevel != null && snap.userLevel!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _buildScoreCard(
                    context,
                    'Level',
                    snap.userLevel!,
                    AppColors.emerald,
                    isText: true,
                  ),
                ),
              ],
            ],
          ),
          if (snap.careerDirection != null &&
              snap.careerDirection!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Text(
                'Hướng nghề: ${snap.careerDirection}',
                style: context.appBodyStyle.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (snap.analysisScope != null) ...[
            const SizedBox(height: 12),
            Text(
              '${snap.analysisScope!.userCommits}/${snap.analysisScope!.totalRepoCommits} commits • '
              '${snap.analysisScope!.activeDays} ngày hoạt động',
              style: context.appCaptionStyle,
            ),
          ],
          const SizedBox(height: 24),

          if (snap.topSkills.isNotEmpty)
            _buildListSection(
              context,
              'Kỹ năng nổi bật',
              Icons.star_outline,
              AppColors.emerald,
              snap.topSkills,
            ),
          if (snap.missingSkills.isNotEmpty)
            _buildListSection(context, 'Skill còn thiếu', Icons.remove_circle_outline, AppColors.amber, snap.missingSkills),
            
          if (snap.recommendations.isNotEmpty)
            _buildListSection(context, 'Khuyến nghị', Icons.lightbulb_outline, Colors.blue, snap.recommendations),
        ],
      ),
    );
  }

  Widget _buildScoreCard(
    BuildContext context,
    String title,
    Object value,
    Color color, {
    bool isText = false,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      color: color.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Text(
              value.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isText ? 16 : 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(title, style: context.appLabelStyle),
          ],
        ),
      ),
    );
  }

  Widget _buildListSection(BuildContext context, String title, IconData icon, Color color, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: context.appSectionTitleStyle),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 16, height: 1.2)),
                Expanded(child: Text(e, style: context.appBodyStyle)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
