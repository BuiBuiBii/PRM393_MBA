import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: appScreenPadding(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: context.appTextSecondary),
            const SizedBox(height: 16),
            Text('404 - Không tìm thấy trang', style: context.appHeadingStyle),
            const SizedBox(height: 8),
            Text('Đường dẫn không tồn tại hoặc đã bị di chuyển.', textAlign: TextAlign.center, style: context.appBodyStyle),
            const SizedBox(height: 20),
            PrimaryButton(label: 'Về Dashboard', onPressed: () => context.go('/dashboard')),
          ],
        ),
      ),
    );
  }
}
