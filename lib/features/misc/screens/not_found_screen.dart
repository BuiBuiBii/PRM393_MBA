import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
            const Icon(Icons.search_off, size: 64, color: AppColors.slate500),
            const SizedBox(height: 16),
            const Text('404 - Không tìm thấy trang', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Đường dẫn không tồn tại hoặc đã bị di chuyển.', textAlign: TextAlign.center),
            const SizedBox(height: 20),
            PrimaryButton(label: 'Về Dashboard', onPressed: () => context.go('/dashboard')),
          ],
        ),
      ),
    );
  }
}
