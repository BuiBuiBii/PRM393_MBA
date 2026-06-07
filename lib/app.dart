import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/network/dio_client.dart';
import 'core/router/app_router.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';

class GitAnalyzerApp extends ConsumerWidget {
  const GitAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}

class AppBootstrap extends StatelessWidget {
  const AppBootstrap({super.key, required this.tokenStorage});

  final TokenStorage tokenStorage;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(tokenStorage),
        unauthorizedHandlerProvider.overrideWith((ref) {
          return () {
            ref.read(authProvider.notifier).logout();
            ref.read(routerProvider).go('/login');
          };
        }),
      ],
      child: const GitAnalyzerApp(),
    );
  }
}
