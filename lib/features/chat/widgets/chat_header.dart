import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/app_models.dart';
import '../../../shared/widgets/app_widgets.dart';

class ChatHeader extends StatelessWidget {
  const ChatHeader({
    super.key,
    required this.session,
    required this.sessions,
    required this.onOpenSessions,
    required this.onCreateSession,
    required this.onSelectSession,
  });

  final ChatSessionModel? session;
  final List<ChatSessionModel> sessions;
  final VoidCallback onOpenSessions;
  final VoidCallback onCreateSession;
  final ValueChanged<String> onSelectSession;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      decoration: BoxDecoration(
        color: context.appCardColor,
        border: Border(bottom: BorderSide(color: context.appBorderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(onPressed: onOpenSessions, icon: const Icon(Icons.history_rounded), tooltip: 'Lịch sử'),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session?.title ?? 'AI Mentor',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.appSectionTitleStyle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Chat dựa trên repository, phân tích và ngữ cảnh GitHub của bạn.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.appLabelStyle.copyWith(height: 1.3),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onCreateSession,
                icon: const Icon(Icons.add_comment_outlined),
                tooltip: 'Tạo cuộc trò chuyện',
              ),
            ],
          ),
          if (session?.repositoryContext != null) ...[
            const SizedBox(height: 6),
            AppBadge(label: 'Context: ${session!.repositoryContext}', variant: AppBadgeVariant.info),
          ],
          if (sessions.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: sessions.length > 6 ? 6 : sessions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final item = sessions[index];
                  final selected = session?.id == item.id;
                  return InkWell(
                    onTap: () => onSelectSession(item.id),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withValues(alpha: context.isDarkMode ? 0.22 : 0.1)
                            : context.appCardColor,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: selected ? AppColors.primary : context.appBorderColor),
                      ),
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: selected ? AppColors.primary : context.appTextSecondary,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
