import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/async_content.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_widgets.dart';

class AdminChatScreen extends ConsumerStatefulWidget {
  const AdminChatScreen({super.key});

  @override
  ConsumerState<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends ConsumerState<AdminChatScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminChatProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminChatProvider);
    return ListView(
      padding: appScreenPadding(context),
      children: [
        const AdminSectionHeader(
          title: 'Quản lý chat',
          subtitle: 'Theo dõi AI Auto, tiếp nhận và trả lời chat Manual.',
        ),
        const SizedBox(height: 12),
        if (state.error != null) ...[
          BannerMessage(message: state.error!, isError: true),
          const SizedBox(height: 12),
        ],
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chế độ chat toàn hệ thống',
                  style: context.appSectionTitleStyle),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'AI_AUTO', label: Text('AI Auto')),
                  ButtonSegment(value: 'MANUAL', label: Text('Manual')),
                ],
                selected: {state.settings?.mode ?? 'AI_AUTO'},
                onSelectionChanged: state.isSaving
                    ? null
                    : (value) => _changeGlobalMode(value.first),
              ),
              const SizedBox(height: 8),
              Text(
                'Session dùng Global sẽ theo thiết lập này. Session Override không bị thay đổi.',
                style: context.appCaptionStyle,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _statusChip('All', null),
              _statusChip('Waiting admin', 'waiting_admin'),
              _statusChip('Active AI', 'active'),
              _statusChip('Answered', 'answered'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String?>(
                initialValue: state.modeFilter,
                decoration: const InputDecoration(labelText: 'Mode'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Tất cả')),
                  DropdownMenuItem(value: 'AI_AUTO', child: Text('AI Auto')),
                  DropdownMenuItem(value: 'MANUAL', child: Text('Manual')),
                ],
                onChanged: (value) => ref.read(adminChatProvider.notifier).load(
                      mode: value,
                      clearMode: value == null,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String?>(
                initialValue: state.modeSourceFilter,
                decoration: const InputDecoration(labelText: 'Nguồn mode'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Tất cả')),
                  DropdownMenuItem(value: 'GLOBAL', child: Text('Global')),
                  DropdownMenuItem(value: 'SESSION', child: Text('Override')),
                ],
                onChanged: (value) => ref.read(adminChatProvider.notifier).load(
                      modeSource: value,
                      clearModeSource: value == null,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AsyncListBody(
          isLoading: state.isLoading,
          isEmpty: state.sessions.isEmpty,
          error: state.sessions.isEmpty ? state.error : null,
          onRetry: () => ref.read(adminChatProvider.notifier).load(),
          emptyTitle: 'Không có cuộc trò chuyện',
          emptySubtitle: 'Không có session phù hợp với bộ lọc.',
          child: Column(
            children: state.sessions.map((session) {
              final user = session.user;
              final preview = session.lastMessage?.content ?? '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AdminListTileCard(
                  title: user?.name ?? session.title,
                  subtitle: [
                    if (user?.email.isNotEmpty == true) user!.email,
                    if (preview.isNotEmpty) preview,
                  ].join(' • '),
                  badges: [
                    AppBadge(
                      label: session.effectiveMode == 'MANUAL'
                          ? 'Manual'
                          : 'AI Auto',
                      variant: session.effectiveMode == 'MANUAL'
                          ? AppBadgeVariant.warning
                          : AppBadgeVariant.success,
                    ),
                    AppBadge(
                      label: session.modeSource == 'SESSION'
                          ? 'Override'
                          : 'Global',
                      variant: AppBadgeVariant.neutral,
                    ),
                    if (session.unreadByAdmin)
                      const AppBadge(
                        label: 'Chưa đọc',
                        variant: AppBadgeVariant.info,
                      ),
                  ],
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/admin/chat/${session.id}'),
                ),
              );
            }).toList(),
          ),
        ),
        AdminPaginationBar(
          pagination: state.pagination,
          onPrev: state.pagination.hasPrev
              ? () => ref
                  .read(adminChatProvider.notifier)
                  .load(page: state.pagination.page - 1)
              : null,
          onNext: state.pagination.hasNext
              ? () => ref
                  .read(adminChatProvider.notifier)
                  .load(page: state.pagination.page + 1)
              : null,
        ),
      ],
    );
  }

  Widget _statusChip(String label, String? status) {
    final selected = ref.watch(adminChatProvider).statusFilter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => ref.read(adminChatProvider.notifier).load(
              status: status,
              clearStatus: status == null,
            ),
      ),
    );
  }

  Future<void> _changeGlobalMode(String mode) async {
    if (mode == 'MANUAL') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Chuyển toàn hệ thống sang Manual?'),
          content: const Text(
            'Tin nhắn mới trong các session Global sẽ chờ admin và không gọi AI.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await ref.read(adminChatProvider.notifier).updateGlobalMode(mode);
  }
}
