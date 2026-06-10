import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/app_image_assets.dart';
import '../../../shared/widgets/app_widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  String? _success;

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final themeMode = ref.watch(themeModeProvider);
    final user = auth.user;

    return ListView(
      padding: appScreenPadding(context),
      children: [
        const PageHeader(
          title: 'Cài đặt',
          subtitle: 'Bảo mật tài khoản, giao diện và các tùy chọn ứng dụng.',
        ),
        if (auth.error != null) ...[const SizedBox(height: 12), BannerMessage(message: auth.error!, isError: true)],
        if (_success != null) ...[const SizedBox(height: 12), BannerMessage(message: _success!)],
        const SizedBox(height: 16),
        AppCard(
          onTap: () => context.go('/profile'),
          child: Row(
            children: [
              UserAvatar(imageUrl: user?.avatar, name: user?.name, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.name ?? 'Người dùng', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    const Text('Xem và chỉnh sửa hồ sơ sinh viên', style: TextStyle(color: AppColors.slate500, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.slate500),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.palette_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Giao diện', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: 'Light',
                      outlined: themeMode != ThemeMode.light,
                      onPressed: () => ref.read(themeModeProvider.notifier).setTheme(ThemeMode.light),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Dark',
                      outlined: themeMode != ThemeMode.dark,
                      onPressed: () => ref.read(themeModeProvider.notifier).setTheme(ThemeMode.dark),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Đổi mật khẩu', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              TextField(controller: _currentPassword, obscureText: true, decoration: const InputDecoration(labelText: 'Mật khẩu hiện tại')),
              TextField(controller: _newPassword, obscureText: true, decoration: const InputDecoration(labelText: 'Mật khẩu mới')),
              TextField(controller: _confirmPassword, obscureText: true, decoration: const InputDecoration(labelText: 'Xác nhận mật khẩu')),
              const SizedBox(height: 8),
              PrimaryButton(
                label: 'Đổi mật khẩu',
                icon: Icons.lock,
                loading: auth.isLoading,
                expand: true,
                onPressed: () async {
                  try {
                    await ref.read(authProvider.notifier).changePassword(
                          _currentPassword.text,
                          _newPassword.text,
                          _confirmPassword.text,
                        );
                    setState(() => _success = 'Đã đổi mật khẩu.');
                    _currentPassword.clear();
                    _newPassword.clear();
                    _confirmPassword.clear();
                  } catch (_) {}
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(label: 'Tiến độ học tập', outlined: true, expand: true, onPressed: () => context.go('/progress')),
        const SizedBox(height: 8),
        PrimaryButton(label: 'Kết nối GitHub', outlined: true, expand: true, onPressed: () => context.go('/github/connect')),
        const SizedBox(height: 8),
        PrimaryButton(
          label: 'Đăng xuất',
          expand: true,
          onPressed: () async {
            await ref.read(authProvider.notifier).logout();
            if (context.mounted) context.go('/login');
          },
        ),
      ],
    );
  }
}
