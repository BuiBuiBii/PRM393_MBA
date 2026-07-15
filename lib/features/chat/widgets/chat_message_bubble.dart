import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/app_models.dart';
import '../../../shared/utils/format_utils.dart';
import '../../../shared/widgets/app_widgets.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    this.adminPerspective = false,
  });

  final ChatMessageModel message;
  final bool adminPerspective;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final isOwnMessage = adminPerspective ? !isUser : isUser;
    final showSenderLabel = !isUser || adminPerspective;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isOwnMessage)
            adminPerspective && isUser
                ? const ChatUserAvatar(size: 32)
                : const ChatMentorAvatar(size: 32),
          if (!isOwnMessage) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isOwnMessage ? AppColors.primary : context.appBubbleAiBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showSenderLabel) ...[
                    Text(
                      isUser
                          ? 'User'
                          : message.isAdmin
                              ? 'Admin / Support'
                              : 'AI Mentor',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isOwnMessage
                            ? Colors.white70
                            : message.isAdmin
                                ? AppColors.amber
                                : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    message.content,
                    style: TextStyle(
                      color:
                          isOwnMessage ? Colors.white : context.appTextPrimary,
                      height: 1.45,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatRelativeTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: isOwnMessage
                          ? Colors.white70
                          : context.appTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatUserAvatar extends StatelessWidget {
  const ChatUserAvatar({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: 0.14),
      ),
      child: Icon(Icons.person_outline,
          color: AppColors.primary, size: size * 0.6),
    );
  }
}

class ChatMentorAvatar extends StatelessWidget {
  const ChatMentorAvatar({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [AppColors.primary, AppColors.purple]),
      ),
      child: Icon(Icons.auto_awesome, color: Colors.white, size: size * 0.5),
    );
  }
}

class ChatTypingIndicator extends StatelessWidget {
  const ChatTypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const ChatMentorAvatar(size: 32),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: context.appBubbleAiBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TypingDot(delayMs: 0),
                SizedBox(width: 4),
                _TypingDot(delayMs: 150),
                SizedBox(width: 4),
                _TypingDot(delayMs: 300),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  const _TypingDot({required this.delayMs});

  final int delayMs;

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
            color: context.appTextSecondary, shape: BoxShape.circle),
      ),
    );
  }
}
