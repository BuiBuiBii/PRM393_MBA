import 'package:flutter/material.dart';

import 'app_image_assets.dart';
import 'app_widgets.dart';

class AuthGradientBackground extends StatelessWidget {
  const AuthGradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFFF8FAFC), Color(0xFFEEF2FF)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF0EA5E9).withValues(alpha: 0.16),
                    const Color(0xFF0EA5E9).withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AuthGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 448),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const AppBrandLogo(size: 44, withBackground: true),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GitAnalyzer AI',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.slate900),
                            ),
                            Text(
                              'Phân tích GitHub trên mobile',
                              style: TextStyle(fontSize: 12, color: AppColors.slate500),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
