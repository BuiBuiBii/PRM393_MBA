import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/async_content.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_widgets.dart';

class AdminReportDetailScreen extends ConsumerStatefulWidget {
  const AdminReportDetailScreen({super.key, required this.reportId});

  final String reportId;

  @override
  ConsumerState<AdminReportDetailScreen> createState() => _AdminReportDetailScreenState();
}

class _AdminReportDetailScreenState extends ConsumerState<AdminReportDetailScreen> {
  final _note = TextEditingController();
  String? _syncedAdminNote;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminReportDetailProvider.notifier).load(widget.reportId));
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(String status) async {
    await ref.read(adminReportDetailProvider.notifier).updateStatus(
          widget.reportId,
          status,
          adminNote: _note.text.trim().isEmpty ? null : _note.text.trim(),
        );
    if (mounted) {
      AppSnackbar.show(context, message: 'Đã cập nhật: $status', variant: AppSnackVariant.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminReportDetailProvider);
    final report = state.report;

    if (report != null) {
      final adminNote = report.adminNote;
      if (adminNote != null && adminNote.isNotEmpty && adminNote != _syncedAdminNote) {
        _syncedAdminNote = adminNote;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _note.text = adminNote;
        });
      }
    }

    return AsyncPageBody(
      isLoading: state.isLoading,
      hasData: report != null,
      error: state.error,
      onRetry: () => ref.read(adminReportDetailProvider.notifier).load(widget.reportId),
      child: ListView(
        padding: appScreenPadding(context),
        children: [
          AdminSectionHeader(title: report!.reason, subtitle: 'Loại: ${report.targetType}'),
          if (state.error != null) ...[
            const SizedBox(height: 12),
            BannerMessage(message: state.error!, isError: true),
          ],
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                adminStatusLabel(report.status),
                const SizedBox(height: 12),
                if (report.description != null && report.description!.isNotEmpty)
                  Text(report.description!, style: const TextStyle(height: 1.45)),
                const SizedBox(height: 12),
                _row('Người báo cáo', report.reporterName ?? report.reporterEmail ?? '—'),
                _row('Target ID', report.targetId ?? '—'),
                _row('Tạo lúc', report.createdAt ?? '—'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ghi chú admin', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _note,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Ghi chú xử lý (tuỳ chọn)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                for (final status in ['reviewing', 'resolved', 'rejected'])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: PrimaryButton(
                      label: 'Đánh dấu: $status',
                      outlined: status != 'resolved',
                      expand: true,
                      loading: state.isSaving,
                      onPressed: state.isSaving ? null : () => _updateStatus(status),
                    ),
                  ),
              ],
            ),
          ),
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
}
