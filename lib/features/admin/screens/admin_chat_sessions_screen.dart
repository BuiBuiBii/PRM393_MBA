import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/app_models.dart';
import '../../../shared/utils/format_utils.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_widgets.dart';

class AdminChatSessionsScreen extends ConsumerStatefulWidget {
  const AdminChatSessionsScreen({super.key});

  @override
  ConsumerState<AdminChatSessionsScreen> createState() => _AdminChatSessionsScreenState();
}

class _AdminChatSessionsScreenState extends ConsumerState<AdminChatSessionsScreen> {
  static const _statuses = <String?>[null, 'waiting_admin', 'active', 'answered', 'closed'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(adminChatSettingsProvider.notifier).loadSettings();
      ref.read(adminChatSessionsProvider.notifier).loadSessions();
    });
  }

  Future<void> _setGlobalMode(String mode) async {
    try {
      await ref.read(adminChatSettingsProvider.notifier).updateGlobalMode(mode);
      if (mounted) AppSnackbar.show(context, message: 'Da cap nhat global mode');
    } catch (_) {
      if (mounted) {
        AppSnackbar.show(
          context,
          message: ref.read(adminChatSettingsProvider).error ?? 'Khong cap nhat duoc global mode',
          variant: AppSnackVariant.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminChatSessionsProvider);
    final notifier = ref.read(adminChatSessionsProvider.notifier);

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: ListView(
        padding: appScreenPadding(context),
        children: [
          AdminSectionHeader(
            title: 'Tin nhắn hỗ trợ',
            subtitle: 'Quản lý session chat, chế độ AI tự động và phản hồi thủ công.',
            trailing: PrimaryButton(
              label: 'Refresh',
              icon: Icons.refresh,
              outlined: true,
              onPressed: state.isLoading ? null : notifier.refresh,
            ),
          ),
          if (state.error != null) ...[
            const SizedBox(height: 12),
            BannerMessage(message: state.error!, isError: true),
          ],
          const SizedBox(height: 16),
          _GlobalSettingsCard(
            settings: state.settings,
            isLoading: state.isLoading,
            onMode: _setGlobalMode,
          ),
          const SizedBox(height: 16),
          _StatusFilters(
            selected: state.statusFilter,
            statuses: _statuses,
            onSelected: (status) => notifier.loadSessions(status: status),
          ),
          const SizedBox(height: 12),
          if (state.isLoading && state.sessions.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (state.sessions.isEmpty)
            EmptyState(
              title: 'Chưa có chat session',
              subtitle: 'Thử đổi filter hoặc bấm refresh để tải lại danh sách.',
              action: PrimaryButton(label: 'Refresh', icon: Icons.refresh, onPressed: notifier.refresh),
            )
          else
            ...state.sessions.map(
              (session) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SessionCard(
                  session: session,
                  onTap: () => context.go('/admin/chat/${session.id}'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GlobalSettingsCard extends StatelessWidget {
  const _GlobalSettingsCard({
    required this.settings,
    required this.isLoading,
    required this.onMode,
  });

  final ChatSettingsModel? settings;
  final bool isLoading;
  final ValueChanged<String> onMode;

  @override
  Widget build(BuildContext context) {
    final mode = settings?.mode ?? 'AI_AUTO';
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Chế độ chat toàn hệ thống', style: context.appSectionTitleStyle)),
              AppBadge(label: mode, variant: mode == 'MANUAL' ? AppBadgeVariant.warning : AppBadgeVariant.info),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('AI tự động'),
                selected: mode == 'AI_AUTO',
                onSelected: isLoading ? null : (_) => onMode('AI_AUTO'),
              ),
              ChoiceChip(
                label: const Text('Admin thủ công'),
                selected: mode == 'MANUAL',
                onSelected: isLoading ? null : (_) => onMode('MANUAL'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusFilters extends StatelessWidget {
  const _StatusFilters({required this.selected, required this.statuses, required this.onSelected});

  final String? selected;
  final List<String?> statuses;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final status in statuses) ...[
            ChoiceChip(
              label: Text(_statusLabel(status)),
              selected: selected == status,
              onSelected: (_) => onSelected(status),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.onTap});

  final AdminChatSessionModel session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final userName = _userText(session.user, const ['name', 'fullName', 'username', 'email']);
    final lastMessage = session.messages.isNotEmpty ? session.messages.last.content : '';
    final time = session.createdAt.isEmpty ? '' : formatRelativeTime(session.createdAt);
    return AdminListTileCard(
      title: userName.isEmpty ? 'Không rõ user' : userName,
      subtitle: [
        if (lastMessage.isNotEmpty) lastMessage,
        if (time.isNotEmpty) time,
      ].join(' - '),
      onTap: onTap,
      trailing: Icon(Icons.chevron_right, color: context.appTextSecondary),
      badges: [
        if ((session.status ?? '').isNotEmpty)
          AppBadge(
            label: session.status!,
            variant: session.status == 'waiting_admin'
                ? AppBadgeVariant.warning
                : session.status == 'answered'
                    ? AppBadgeVariant.success
                    : AppBadgeVariant.neutral,
          ),
        if ((session.effectiveMode ?? session.mode ?? '').isNotEmpty)
          AppBadge(label: session.effectiveMode ?? session.mode!, variant: AppBadgeVariant.info),
        if ((session.modeSource ?? '').isNotEmpty) AppBadge(label: session.modeSource!),
      ],
    );
  }
}

String _userText(Map<String, dynamic> user, List<String> keys) {
  for (final key in keys) {
    final value = user[key]?.toString() ?? '';
    if (value.isNotEmpty) return value;
  }
  return '';
}

String _statusLabel(String? status) {
  switch (status) {
    case null:
      return 'Tất cả';
    case 'waiting_admin':
      return 'Đang chờ admin';
    case 'answered':
      return 'Đã trả lời';
    case 'active':
      return 'Đang active';
    case 'closed':
      return 'Đã đóng';
    default:
      return status;
  }
}
