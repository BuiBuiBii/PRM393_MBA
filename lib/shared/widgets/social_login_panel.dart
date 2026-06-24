import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_utils.dart';
import '../../features/auth/providers/auth_provider.dart';
import 'app_image_assets.dart';
import 'app_widgets.dart';

/// Google + GitHub login — khớp Web: `/auth/google`, `POST /auth/github` + redirectUrl.
class SocialLoginPanel extends ConsumerStatefulWidget {
  const SocialLoginPanel({
    super.key,
    required this.dividerLabel,
    required this.onSuccess,
  });

  final String dividerLabel;
  final VoidCallback onSuccess;

  @override
  ConsumerState<SocialLoginPanel> createState() => _SocialLoginPanelState();
}

class _SocialLoginPanelState extends ConsumerState<SocialLoginPanel> {
  var _notice = '';

  Future<void> _submitGoogle() async {
    if (AppConfig.demoMode) {
      setState(() => _notice = 'Demo mode không hỗ trợ đăng nhập Google.');
      return;
    }
    if (!AppConfig.isGoogleLoginConfigured) {
      setState(() => _notice = 'Chưa cấu hình GOOGLE_CLIENT_ID.');
      return;
    }

    setState(() => _notice = '');
    try {
      await ref.read(authProvider.notifier).loginWithGoogle();
      if (mounted) widget.onSuccess();
    } catch (error) {
      if (mounted) {
        ref.read(authProvider.notifier).clearError();
        setState(() => _notice = getApiErrorMessage(error));
      }
    }
  }

  Future<void> _submitGithub() async {
    if (AppConfig.demoMode) {
      setState(() => _notice = 'Demo mode không hỗ trợ đăng nhập GitHub.');
      return;
    }
    setState(() => _notice = '');
    try {
      await ref.read(authProvider.notifier).loginWithGithub();
      if (mounted) widget.onSuccess();
    } catch (error) {
      if (mounted) {
        ref.read(authProvider.notifier).clearError();
        setState(() => _notice = getApiErrorMessage(error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider.select((state) => state.isLoading));

    return Column(
      children: [
        AuthDivider(label: widget.dividerLabel),
        if (_notice.isNotEmpty) ...[
          const SizedBox(height: 16),
          BannerMessage(message: _notice, isWarning: true),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: PrimaryButton(
                label: 'GitHub',
                outlined: true,
                loading: isLoading,
                leading: const AppSvgIcon(asset: AppAssets.githubIcon, size: 18),
                onPressed: isLoading ? null : _submitGithub,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryButton(
                label: 'Google',
                outlined: true,
                loading: isLoading,
                leading: const AppSvgIcon(asset: AppAssets.googleIcon, size: 18),
                onPressed: isLoading ? null : _submitGoogle,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
