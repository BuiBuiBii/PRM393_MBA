import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../feature_providers.dart';
import '../../../shared/widgets/async_content.dart';
import '../../../shared/widgets/scroll_list_hints.dart';
import '../../../shared/widgets/collapsible_list.dart';
import '../../../shared/widgets/app_widgets.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _unreadOnly = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() => ref.read(notificationProvider.notifier).load(unreadOnly: _unreadOnly);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);
    final unread = state.items.where((i) => !i.read).length;

    return ScrollListHints(
      child: ListView(
      padding: appScreenPadding(context),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Quản lý thông báo của bạn.',
                style: context.appCaptionStyle,
              ),
            ),
            AppBadge(
              label: '$unread chưa đọc',
              variant: unread > 0 ? AppBadgeVariant.warning : AppBadgeVariant.neutral,
            ),
          ],
        ),
        if (state.error != null) ...[const SizedBox(height: 12), BannerMessage(message: state.error!, isError: true)],
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
              AsyncListBody(
                isLoading: state.isLoading,
                isEmpty: state.items.isEmpty,
                error: state.error,
                onRetry: _load,
                emptyTitle: 'Không có thông báo',
                child: CollapsibleItemList(
                  resetKey: _unreadOnly,
                  initialVisibleCount: 6,
                  itemSpacing: 8,
                  items: state.items,
                  itemBuilder: (context, item) => Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: context.appBorderColor),
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
                              Text(item.title, style: context.appSectionTitleStyle.copyWith(fontSize: 14)),
                              const SizedBox(height: 4),
                              Text(item.message, style: context.appCaptionStyle),
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
              ),
            ],
          ),
        ),
      ],
    ),
    );
  }
}
