import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
                  const Text('Không có quyền truy cập', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text(
                    'Khu vực Admin chỉ dành cho tài khoản có role admin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.slate500),
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
