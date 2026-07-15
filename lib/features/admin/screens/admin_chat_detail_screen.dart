import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../chat/widgets/chat_message_bubble.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_widgets.dart';

class AdminChatDetailScreen extends ConsumerStatefulWidget {
  const AdminChatDetailScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<AdminChatDetailScreen> createState() =>
      _AdminChatDetailScreenState();
}

class _AdminChatDetailScreenState extends ConsumerState<AdminChatDetailScreen> {
  final _reply = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () =>
          ref.read(adminChatProvider.notifier).selectSession(widget.sessionId),
    );
  }

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminChatProvider);
    final session = state.selected;
    if (session == null && state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (session == null) {
      return Center(child: Text(state.error ?? 'Không tìm thấy session'));
    }
    final isClosed = session.status == 'closed';

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: appScreenPadding(context),
            children: [
              AdminSectionHeader(
                title: session.user?.name ?? session.title,
                subtitle: session.user?.email ?? '',
              ),
              if (state.error != null) ...[
                const SizedBox(height: 8),
                BannerMessage(message: state.error!, isError: true),
              ],
              if (isClosed) ...[
                const SizedBox(height: 8),
                const BannerMessage(
                  message: 'Session đã đóng. Admin không thể thao tác thêm.',
                  isError: false,
                ),
              ],
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
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
                        AppBadge(
                          label: isClosed ? 'Đã đóng' : session.status,
                          variant: isClosed
                              ? AppBadgeVariant.warning
                              : AppBadgeVariant.info,
                        ),
                      ],
                    ),
                    if (session.manualReason?.isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      Text('Lý do manual: ${session.manualReason}'),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed:
                              state.isSaving || isClosed ? null : _switchManual,
                          child: const Text('Chuyển Manual'),
                        ),
                        OutlinedButton(
                          onPressed: state.isSaving || isClosed
                              ? null
                              : () => ref
                                  .read(adminChatProvider.notifier)
                                  .setSessionMode(widget.sessionId, 'AI_AUTO'),
                          child: const Text('Chuyển AI Auto'),
                        ),
                        TextButton(
                          onPressed: state.isSaving || isClosed
                              ? null
                              : () => ref
                                  .read(adminChatProvider.notifier)
                                  .useGlobalMode(widget.sessionId),
                          child: const Text('Dùng Global'),
                        ),
                        if (!isClosed)
                          TextButton.icon(
                            onPressed: state.isSaving ? null : _closeSession,
                            icon: const Icon(Icons.lock_outline),
                            label: const Text('Đóng session'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...session.messages.map(
                (message) => ChatMessageBubble(
                  message: message,
                  adminPerspective: true,
                ),
              ),
            ],
          ),
        ),
        if (isClosed)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.red.withValues(alpha: 0.08),
            child: const SafeArea(
              top: false,
              child: Text(
                'Session đã đóng, admin không thể trả lời.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.appCardColor,
              border: Border(top: BorderSide(color: context.appBorderColor)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _reply,
                      enabled: !state.isSaving,
                      decoration: const InputDecoration(
                        hintText: 'Nhập câu trả lời của admin...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _sendReply(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: state.isSaving ? null : _sendReply,
                    tooltip: 'Gửi trả lời',
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _switchManual() async {
    final reason = await _askReason('Chuyển session sang Manual', 'Lý do');
    if (reason == null) return;
    await ref.read(adminChatProvider.notifier).setSessionMode(
          widget.sessionId,
          'MANUAL',
          reason: reason,
        );
  }

  Future<void> _closeSession() async {
    final reason = await _askReason('Đóng session?', 'Lý do (tùy chọn)');
    if (reason == null) return;
    try {
      await ref.read(adminChatProvider.notifier).closeSession(
            widget.sessionId,
            reason: reason,
          );
    } catch (_) {}
  }

  Future<String?> _askReason(String title, String label) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    controller.dispose();
    return reason;
  }

  Future<void> _sendReply() async {
    final content = _reply.text.trim();
    if (content.isEmpty) return;
    try {
      await ref
          .read(adminChatProvider.notifier)
          .sendReply(widget.sessionId, content);
      _reply.clear();
      if (mounted) {
        AppSnackbar.show(
          context,
          message: 'Đã gửi trả lời',
          variant: AppSnackVariant.success,
        );
      }
    } catch (_) {}
  }
}
