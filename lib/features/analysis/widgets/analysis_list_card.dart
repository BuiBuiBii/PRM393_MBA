import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';

/// Card danh sách bullet (điểm mạnh / yếu / đề xuất).
class AnalysisListCard extends StatelessWidget {
  const AnalysisListCard({
    super.key,
    required this.title,
    required this.items,
    required this.icon,
    required this.color,
  });

  final String title;
  final List<String> items;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(title, style: context.appSectionTitleStyle.copyWith(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Text('Không có dữ liệu', style: context.appCaptionStyle)
          else
            ...items.map((e) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('• $e'))),
        ],
      ),
    );
  }
}
