import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/app_image_assets.dart';
import '../../../shared/widgets/app_widgets.dart';

class GitHubCallbackScreen extends ConsumerStatefulWidget {
  const GitHubCallbackScreen({super.key});

  @override
  ConsumerState<GitHubCallbackScreen> createState() => _GitHubCallbackScreenState();
}

class _GitHubCallbackScreenState extends ConsumerState<GitHubCallbackScreen> {
  var _handled = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_handled) {
      _handled = true;
      _handleCallback(GoRouterState.of(context).uri);
    }
  }

  Future<void> _handleCallback(Uri uri) async {
    final params = uri.queryParameters;

    try {
      if (params.containsKey('code')) {
        final api = ref.read(appApiProvider);
        await api.completeGitHubOAuthCallback(params);
      }

      if (!mounted) return;

      if (!ref.read(authProvider).isAuthenticated) {
        context.go('/login');
        return;
      }

      await ref.read(authProvider.notifier).refreshGitHubAccount();
      if (mounted) context.go('/github/connect');
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
        await Future<void>.delayed(const Duration(seconds: 2));
        if (mounted) context.go('/github/connect');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const AppSvgIcon(asset: AppAssets.githubIcon, size: 28, color: Colors.white),
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.amber))
              else ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                const Text('Đang hoàn tất kết nối GitHub...', style: TextStyle(color: AppColors.slate500)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
