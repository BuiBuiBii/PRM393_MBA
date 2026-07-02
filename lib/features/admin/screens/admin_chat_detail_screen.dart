import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/app_models.dart';
import '../../../shared/utils/format_utils.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_widgets.dart';

class AdminChatDetailScreen extends ConsumerStatefulWidget {
  const AdminChatDetailScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<AdminChatDetailScreen> createState() => _AdminChatDetailScreenState();
}

class _AdminChatDetailScreenState extends ConsumerState<AdminChatDetailScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminChatSettingsProvider.notifier).loadSession(widget.sessionId));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    try {
      await ref.read(adminChatSettingsProvider.notifier).sendAdminMessage(widget.sessionId, text);
      _controller.clear();
      _scrollToBottom();
    } catch (_) {
      if (mounted) {
        AppSnackbar.show(
          context,
          message: ref.read(adminChatSettingsProvider).error ?? 'Khong gui duoc phan hoi',
          variant: AppSnackVariant.error,
        );
      }
    }
  }

  Future<void> _setMode(String mode) async {
    try {
      await ref.read(adminChatSettingsProvider.notifier).updateSessionMode(
            widget.sessionId,
            mode,
            reason: mode == 'MANUAL' ? 'Admin muon ho tro truc tiep' : null,
          );
    } catch (_) {
      if (mounted) {
        AppSnackbar.show(
          context,
          message: ref.read(adminChatSettingsProvider).error ?? 'Khong doi duoc mode',
          variant: AppSnackVariant.error,
        );
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminChatSettingsProvider);
    final detail = ref.watch(adminChatSessionDetailProvider(widget.sessionId));
    final session = detail?.session;
    final messages = detail?.messages ?? session?.messages ?? const <ChatMessageModel>[];

    return Column(
      children: [
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: BannerMessage(message: state.error!, isError: true),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: _DetailHeader(
            session: session,
            isSaving: state.isSending,
            onRefresh: () => ref.read(adminChatSettingsProvider.notifier).loadSession(widget.sessionId),
            onManual: () => _setMode('MANUAL'),
            onAiAuto: () => _setMode('AI_AUTO'),
            onUseGlobal: () => ref.read(adminChatSettingsProvider.notifier).useGlobalMode(widget.sessionId),
          ),
        ),
        Expanded(
          child: state.isLoading && session == null
              ? const Center(child: CircularProgressIndicator())
              : messages.isEmpty
                  ? const EmptyState(title: 'Chua co message')
                  : RefreshIndicator(
                      onRefresh: () => ref.read(adminChatSettingsProvider.notifier).loadSession(widget.sessionId),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) => _AdminMessageBubble(message: messages[index]),
                      ),
                    ),
        ),
        _Composer(controller: _controller, isSending: state.isSending, onSend: _send),
      ],
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.session,
    required this.isSaving,
    required this.onRefresh,
    required this.onManual,
    required this.onAiAuto,
    required this.onUseGlobal,
  });

  final AdminChatSessionModel? session;
  final bool isSaving;
  final VoidCallback onRefresh;
  final VoidCallback onManual;
  final VoidCallback onAiAuto;
  final VoidCallback onUseGlobal;

  @override
  Widget build(BuildContext context) {
    final user = session == null ? '' : _userText(session!.user, const ['name', 'fullName', 'username', 'email']);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSectionHeader(
            title: user.isEmpty ? 'Không rõ user' : user,
            subtitle: session?.id,
            trailing: IconButton(onPressed: onRefresh, icon: const Icon(Icons.refresh), tooltip: 'Refresh'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if ((session?.status ?? '').isNotEmpty) AppBadge(label: session!.status!),
              if ((session?.effectiveMode ?? session?.mode ?? '').isNotEmpty)
                AppBadge(label: session!.effectiveMode ?? session!.mode!, variant: AppBadgeVariant.info),
              if ((session?.modeSource ?? '').isNotEmpty) AppBadge(label: session!.modeSource!),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PrimaryButton(label: 'Chuyển MANUAL', outlined: true, onPressed: isSaving ? null : onManual),
              PrimaryButton(label: 'Chuyển AI_AUTO', outlined: true, onPressed: isSaving ? null : onAiAuto),
              PrimaryButton(label: 'Dùng global mode', outlined: true, onPressed: isSaving ? null : onUseGlobal),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminMessageBubble extends StatelessWidget {
  const _AdminMessageBubble({required this.message});

  final ChatMessageModel message;

  @override
  Widget build(BuildContext context) {
    final senderType = message.senderType ?? (message.role == 'user' ? 'USER' : 'AI');
    final isUser = senderType == 'USER';
    final isAdmin = senderType == 'ADMIN';
    final label = isUser
        ? 'User'
        : isAdmin
            ? 'Admin'
            : 'AI Mentor';
    final color = isUser
        ? AppColors.primary
        : isAdmin
            ? AppColors.amber
            : AppColors.cyan;
    return Align(
      alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: context.isDarkMode ? 0.18 : 0.1),
          border: Border.all(color: color.withValues(alpha: 0.28)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 6),
            Text(message.content, style: context.appBodyStyle),
            const SizedBox(height: 6),
            Text(formatRelativeTime(message.timestamp), style: context.appCaptionStyle),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.isSending, required this.onSend});

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom + MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + bottom),
      decoration: BoxDecoration(
        color: context.appCardColor,
        border: Border(top: BorderSide(color: context.appBorderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !isSending,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'Nhập phản hồi cho user...'),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: isSending ? null : onSend,
            child: isSending
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send_rounded),
          ),
        ],
      ),
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
