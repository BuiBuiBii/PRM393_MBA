import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.enabled,
    required this.bottomInset,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final double bottomInset;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + bottomInset),
      decoration: BoxDecoration(
        color: context.appCardColor,
        border: Border(top: BorderSide(color: context.appBorderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              style: TextStyle(color: context.appTextPrimary),
              decoration: InputDecoration(
                hintText: 'Nhập câu hỏi...',
                filled: true,
                fillColor: context.isDarkMode ? AppTheme.darkSurface : const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.appBorderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.appBorderColor),
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: enabled ? onSend : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Icon(Icons.send_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}
