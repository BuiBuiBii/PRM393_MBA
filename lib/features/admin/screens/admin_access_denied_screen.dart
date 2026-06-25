import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';

class AdminAccessDeniedScreen extends StatelessWidget {
  const AdminAccessDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AppCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 48, color: AppColors.amber),
                  const SizedBox(height: 16),
                  Text('Không có quyền truy cập', style: context.appHeadingStyle.copyWith(fontSize: 18)),
                  const SizedBox(height: 8),
                  Text(
                    'Khu vực Admin chỉ dành cho tài khoản có role admin.',
                    textAlign: TextAlign.center,
                    style: context.appBodyStyle,
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(label: 'Về trang chủ', expand: true, onPressed: () => context.go('/dashboard')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
