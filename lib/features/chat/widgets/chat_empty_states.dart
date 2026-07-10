import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';

class ChatNoSessionEmpty extends StatelessWidget {
  const ChatNoSessionEmpty({super.key, required this.onCreateSession});

  final VoidCallback onCreateSession;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: appScreenPadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const ChatPromptAvatar(),
            const SizedBox(height: 16),
            Text('Hỏi AI Mentor', style: context.appHeadingStyle),
            const SizedBox(height: 8),
            Text(
              'Bạn có thể nhập câu hỏi ngay. Hệ thống sẽ tự tạo cuộc trò chuyện và lưu lại nội dung cho bạn.',
              textAlign: TextAlign.center,
              style: context.appBodyStyle,
            ),
            const SizedBox(height: 16),
            PrimaryButton(label: 'Tạo cuộc trò chuyện', icon: Icons.add, onPressed: onCreateSession),
          ],
        ),
      ),
    );
  }
}

class ChatPromptEmpty extends StatelessWidget {
  const ChatPromptEmpty({super.key, required this.prompts, required this.onPrompt});

  final List<String> prompts;
  final ValueChanged<String> onPrompt;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: appScreenPadding(context),
        child: Column(
          children: [
            const ChatPromptAvatar(),
            const SizedBox(height: 16),
            Text('Bắt đầu hỏi AI Mentor', style: context.appSectionTitleStyle),
            const SizedBox(height: 16),
            ...prompts.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  onTap: () => onPrompt(p),
                  child: Text(p, style: context.appBodyStyle.copyWith(fontSize: 13)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatPromptAvatar extends StatelessWidget {
  const ChatPromptAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [AppColors.primary, AppColors.purple]),
      ),
      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
    );
  }
}
