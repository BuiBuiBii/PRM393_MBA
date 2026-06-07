import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/app_models.dart';
import '../../../shared/widgets/app_image_assets.dart';
import '../../../shared/widgets/app_widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _fullName = TextEditingController();
  final _university = TextEditingController();
  final _major = TextEditingController();
  final _targetCareer = TextEditingController();
  final _skills = TextEditingController();
  final _githubUsername = TextEditingController();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  int _year = 1;
  String? _success;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(authProvider.notifier).fetchProfile());
  }

  void _fill(ProfileModel? profile, UserModel? user) {
    _fullName.text = profile?.fullName ?? user?.name ?? '';
    _university.text = profile?.university ?? '';
    _major.text = profile?.major ?? '';
    _year = profile?.year ?? 1;
    _targetCareer.text = profile?.targetCareer ?? '';
    _skills.text = profile?.currentSkills.join(', ') ?? '';
    _githubUsername.text = profile?.githubUsername ?? user?.githubUsername ?? '';
  }

  @override
  void dispose() {
    _fullName.dispose();
    _university.dispose();
    _major.dispose();
    _targetCareer.dispose();
    _skills.dispose();
    _githubUsername.dispose();
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    if (_fullName.text.isEmpty && (auth.profile != null || user != null)) {
      _fill(auth.profile, user);
    }

    return ListView(
      padding: appScreenPadding(context),
      children: [
        const PageHeader(
          title: 'Cài đặt',
          subtitle: 'Quản lý hồ sơ, bảo mật và tích hợp GitHub.',
        ),
        if (auth.error != null) ...[const SizedBox(height: 12), BannerMessage(message: auth.error!, isError: true)],
        if (_success != null) ...[const SizedBox(height: 12), BannerMessage(message: _success!)],
        const SizedBox(height: 16),
        AppCard(
          child: Row(
            children: [
              UserAvatar(imageUrl: user?.avatar, name: user?.name, size: 56),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.name ?? 'Người dùng', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    Text(user?.email ?? '', style: const TextStyle(color: AppColors.slate500)),
                    const SizedBox(height: 4),
                    AppBadge(
                      label: user?.githubConnected == true ? 'GitHub đã kết nối' : 'GitHub chưa kết nối',
                      variant: user?.githubConnected == true ? AppBadgeVariant.success : AppBadgeVariant.neutral,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Hồ sơ sinh viên', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              TextField(controller: _fullName, decoration: const InputDecoration(labelText: 'Họ tên')),
              TextField(controller: _university, decoration: const InputDecoration(labelText: 'Trường')),
              TextField(controller: _major, decoration: const InputDecoration(labelText: 'Ngành')),
              TextField(controller: _targetCareer, decoration: const InputDecoration(labelText: 'Hướng nghề nghiệp')),
              TextField(controller: _skills, decoration: const InputDecoration(labelText: 'Kỹ năng (cách nhau bởi dấu phẩy)')),
              TextField(controller: _githubUsername, decoration: const InputDecoration(labelText: 'GitHub username')),
              DropdownButtonFormField<int>(
                initialValue: _year,
                decoration: const InputDecoration(labelText: 'Năm học'),
                items: List.generate(5, (i) => DropdownMenuItem(value: i + 1, child: Text('Năm ${i + 1}'))),
                onChanged: (v) => setState(() => _year = v ?? 1),
              ),
              const SizedBox(height: 8),
              PrimaryButton(
                label: 'Lưu hồ sơ',
                icon: Icons.save,
                loading: auth.isLoading,
                expand: true,
                onPressed: () async {
                  final profile = ProfileModel(
                    fullName: _fullName.text.trim(),
                    university: _university.text.trim(),
                    major: _major.text.trim(),
                    year: _year,
                    targetCareer: _targetCareer.text.trim(),
                    currentSkills: _skills.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                    githubUsername: _githubUsername.text.trim().isEmpty ? null : _githubUsername.text.trim(),
                  );
                  try {
                    await ref.read(authProvider.notifier).saveProfile(profile, exists: auth.profile != null);
                    setState(() => _success = 'Đã lưu hồ sơ.');
                  } catch (_) {}
                },
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
        PrimaryButton(label: 'Tiến độ học tập', outlined: true, expand: true, onPressed: () => context.push('/progress')),
        const SizedBox(height: 8),
        PrimaryButton(label: 'Kết nối GitHub', outlined: true, expand: true, onPressed: () => context.push('/github/connect')),
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
