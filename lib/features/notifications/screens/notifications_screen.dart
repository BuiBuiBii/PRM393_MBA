import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../../shared/widgets/app_widgets.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _unreadOnly = false;
  final _title = TextEditingController();
  final _message = TextEditingController();
  String _createType = 'SYSTEM';

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() => ref.read(notificationProvider.notifier).load(unreadOnly: _unreadOnly);

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);
    final unread = state.items.where((i) => !i.read).length;

    return ListView(
      padding: appScreenPadding(context),
      children: [
        PageHeader(
          title: 'Thông báo',
          subtitle: 'Quản lý thông báo của người dùng.',
          trailing: AppBadge(
            label: '$unread chưa đọc',
            variant: unread > 0 ? AppBadgeVariant.warning : AppBadgeVariant.neutral,
          ),
        ),
        if (state.error != null) ...[const SizedBox(height: 12), BannerMessage(message: state.error!, isError: true)],
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tạo thông báo', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              TextField(controller: _title, decoration: const InputDecoration(labelText: 'Tiêu đề')),
              TextField(controller: _message, decoration: const InputDecoration(labelText: 'Nội dung')),
              DropdownButtonFormField<String>(
                initialValue: _createType,
                items: const [
                  DropdownMenuItem(value: 'SYSTEM', child: Text('Hệ thống')),
                  DropdownMenuItem(value: 'GITHUB_ANALYSIS_REMINDER', child: Text('Nhắc phân tích GitHub')),
                  DropdownMenuItem(value: 'ROADMAP_TASK_REMINDER', child: Text('Nhắc lộ trình')),
                  DropdownMenuItem(value: 'REPOSITORY_IMPROVEMENT', child: Text('Cải thiện repository')),
                ],
                onChanged: (v) => setState(() => _createType = v ?? 'SYSTEM'),
              ),
              const SizedBox(height: 8),
              PrimaryButton(
                label: 'Tạo',
                expand: true,
                onPressed: () async {
                  await ref.read(notificationProvider.notifier).create(_title.text, _message.text, _createType);
                  _title.clear();
                  _message.clear();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _unreadOnly,
                    onChanged: (v) {
                      setState(() => _unreadOnly = v ?? false);
                      _load();
                    },
                  ),
                  const Text('Chỉ hiện chưa đọc'),
                ],
              ),
              if (state.isLoading)
                const Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())
              else if (state.items.isEmpty)
                const EmptyState(title: 'Không có thông báo')
              else
                ...state.items.map(
                  (item) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.notifications, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(item.message, style: const TextStyle(color: AppColors.slate600, fontSize: 13)),
                            ],
                          ),
                        ),
                        if (!item.read)
                          IconButton(
                            icon: const Icon(Icons.check),
                            onPressed: () => ref.read(notificationProvider.notifier).markRead(item.id),
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => ref.read(notificationProvider.notifier).remove(item.id),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
