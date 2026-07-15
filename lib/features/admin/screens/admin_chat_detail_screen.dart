import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/realtime/chat_socket_client.dart';
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
  final _scrollController = ScrollController();
  Timer? _outgoingTypingTimer;
  Timer? _remoteTypingTimer;
  ChatSocketBinding? _socketBinding;
  String? _socketIssue;

  @override
  void initState() {
    super.initState();
    _reply.addListener(_onInputChanged);
    Future.microtask(
      () {
        ref.read(adminChatProvider.notifier).selectSession(widget.sessionId);
        _bindRealtime();
      },
    );
  }

  @override
  void dispose() {
    ref.read(chatSocketClientProvider).sendTyping(widget.sessionId, false);
    _socketBinding?.dispose();
    _outgoingTypingTimer?.cancel();
    _remoteTypingTimer?.cancel();
    _reply.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminChatProvider);
    final session = state.selected;
    final socketStatus = ref.watch(chatSocketStatusProvider).asData?.value;
    ref.listen(
      adminChatProvider.select((value) => value.selected?.messages.length),
      (_, __) => _scrollToBottom(),
    );
    ref.listen(chatSocketStatusProvider, (_, next) {
      if (next.asData?.value == ChatSocketStatus.connected &&
          _socketIssue != null &&
          mounted) {
        setState(() => _socketIssue = null);
      }
    });
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
            controller: _scrollController,
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
              if (_socketIssue != null ||
                  socketStatus == ChatSocketStatus.reconnecting) ...[
                const SizedBox(height: 8),
                BannerMessage(
                  message: _socketIssue ?? 'Đang kết nối lại realtime chat...',
                  isError: _socketIssue != null,
                ),
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
                          label: 'Mode: ${session.mode}',
                          variant: session.mode == 'MANUAL'
                              ? AppBadgeVariant.warning
                              : AppBadgeVariant.success,
                        ),
                        AppBadge(
                          label: 'Nguồn: ${session.modeSource}',
                          variant: AppBadgeVariant.neutral,
                        ),
                        AppBadge(
                          label: 'Hiệu lực: ${session.effectiveMode}',
                          variant: session.effectiveMode == 'MANUAL'
                              ? AppBadgeVariant.warning
                              : AppBadgeVariant.success,
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
              if (state.remoteTyping)
                const SizedBox(height: 42, child: ChatTypingIndicator()),
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
      ref.read(chatSocketClientProvider).sendTyping(widget.sessionId, false);
      _scrollToBottom();
      if (mounted) {
        AppSnackbar.show(
          context,
          message: 'Đã gửi trả lời',
          variant: AppSnackVariant.success,
        );
      }
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _bindRealtime() async {
    if (_socketIssue != null && mounted) {
      setState(() => _socketIssue = null);
    }
    final binding = await ref.read(chatSocketClientProvider).bindSession(
          sessionId: widget.sessionId,
          onMessageCreated: (event) {
            if (mounted) {
              ref.read(adminChatProvider.notifier).applyRealtimeMessage(event);
            }
          },
          onSessionUpdated: (event) {
            if (mounted) {
              ref
                  .read(adminChatProvider.notifier)
                  .applyRealtimeSessionUpdate(event);
            }
          },
          onTyping: (event) {
            if (!mounted) return;
            final typing = event['isTyping'] == true;
            ref.read(adminChatProvider.notifier).setRemoteTyping(typing);
            _remoteTypingTimer?.cancel();
            if (typing) {
              _remoteTypingTimer = Timer(const Duration(seconds: 4), () {
                if (mounted) {
                  ref.read(adminChatProvider.notifier).setRemoteTyping(false);
                }
              });
            }
          },
          onReadUpdated: (event) {
            if (mounted) {
              ref
                  .read(adminChatProvider.notifier)
                  .applyRealtimeReadUpdate(event);
            }
          },
          onError: (issue) {
            if (mounted) {
              setState(() => _socketIssue = '${issue.code}: ${issue.message}');
            }
          },
        );
    if (!mounted) {
      binding?.dispose();
      return;
    }
    _socketBinding = binding;
  }

  void _onInputChanged() {
    final socket = ref.read(chatSocketClientProvider);
    final typing = _reply.text.trim().isNotEmpty;
    socket.sendTyping(widget.sessionId, typing);
    _outgoingTypingTimer?.cancel();
    if (typing) {
      _outgoingTypingTimer = Timer(const Duration(seconds: 2), () {
        socket.sendTyping(widget.sessionId, false);
      });
    }
  }
}
