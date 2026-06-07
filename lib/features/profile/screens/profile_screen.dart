import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../shared/models/app_models.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/utils/format_utils.dart';
import '../../../shared/widgets/app_image_assets.dart';
import '../../../shared/widgets/app_widgets.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _fullName = TextEditingController();
  final _university = TextEditingController();
  final _major = TextEditingController();
  final _targetCareer = TextEditingController();
  final _skills = TextEditingController();
  final _githubUsername = TextEditingController();
  var _year = 1;
  var _editing = false;
  String? _success;
  var _filled = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final auth = ref.read(authProvider);
      if (auth.profile == null) {
        ref.read(authProvider.notifier).fetchProfile();
      }
    });
  }

  void _fill(ProfileModel? profile, UserModel? user) {
    _fullName.text = profile?.fullName ?? user?.name ?? '';
    _university.text = profile?.university ?? '';
    _major.text = profile?.major ?? '';
    _year = profile?.year ?? 1;
    _targetCareer.text = profile?.targetCareer ?? '';
    _skills.text = profile?.currentSkills.join(', ') ?? '';
    _githubUsername.text = profile?.githubUsername ?? user?.githubUsername ?? '';
    _filled = true;
  }

  @override
  void dispose() {
    _fullName.dispose();
    _university.dispose();
    _major.dispose();
    _targetCareer.dispose();
    _skills.dispose();
    _githubUsername.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final auth = ref.read(authProvider);
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
      setState(() {
        _editing = false;
        _success = 'Đã lưu hồ sơ.';
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final profile = auth.profile;

    if (!_filled && (auth.profile != null || user != null)) {
      _fill(auth.profile, user);
    }

    return ListView(
      padding: appScreenPadding(context),
      children: [
        PageHeader(
          title: 'Hồ sơ của tôi',
          subtitle: _editing ? 'Chỉnh sửa thông tin cá nhân.' : 'Thông tin tài khoản và hồ sơ sinh viên.',
          trailing: PrimaryButton(
            label: _editing ? 'Hủy' : 'Chỉnh sửa',
            icon: _editing ? Icons.close : Icons.edit_outlined,
            outlined: true,
            onPressed: () {
              setState(() {
                if (_editing) {
                  _fill(auth.profile, user);
                  _editing = false;
                } else {
                  _editing = true;
                  _success = null;
                }
              });
            },
          ),
        ),
        if (auth.error != null) ...[const SizedBox(height: 12), BannerMessage(message: auth.error!, isError: true)],
        if (_success != null) ...[const SizedBox(height: 12), BannerMessage(message: _success!)],
        const SizedBox(height: 16),
        if (_editing) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Chỉnh sửa hồ sơ', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                TextField(controller: _fullName, decoration: const InputDecoration(labelText: 'Họ tên')),
                TextField(controller: _university, decoration: const InputDecoration(labelText: 'Trường')),
                TextField(controller: _major, decoration: const InputDecoration(labelText: 'Ngành')),
                TextField(controller: _targetCareer, decoration: const InputDecoration(labelText: 'Hướng nghề nghiệp')),
                TextField(controller: _skills, decoration: const InputDecoration(labelText: 'Kỹ năng (cách nhau bởi dấu phẩy)')),
                TextField(controller: _githubUsername, decoration: const InputDecoration(labelText: 'GitHub username')),
                DropdownButtonFormField<int>(
                  key: ValueKey(_year),
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
                  onPressed: _saveProfile,
                ),
              ],
            ),
          ),
        ] else ...[
          AppCard(
            child: Column(
              children: [
                UserAvatar(imageUrl: user?.avatar, name: user?.name, size: 72),
                const SizedBox(height: 12),
                Text(
                  profile?.fullName ?? user?.name ?? 'Người dùng',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(user?.email ?? '', style: const TextStyle(color: AppColors.slate500)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    AppBadge(
                      label: user?.githubConnected == true ? 'GitHub đã kết nối' : 'GitHub chưa kết nối',
                      variant: user?.githubConnected == true ? AppBadgeVariant.success : AppBadgeVariant.neutral,
                    ),
                    if ((profile?.githubUsername ?? user?.githubUsername) != null)
                      AppBadge(label: '@${profile?.githubUsername ?? user?.githubUsername}', variant: AppBadgeVariant.info),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _infoCard('Thông tin học tập', [
            _row('Trường', profile?.university),
            _row('Ngành', profile?.major),
            _row('Năm học', profile?.year != null ? 'Năm ${profile!.year}' : null),
            _row('Hướng nghề nghiệp', profile?.targetCareer),
          ]),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Kỹ năng hiện có', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                if (profile?.currentSkills.isEmpty ?? true)
                  const Text('Chưa cập nhật kỹ năng', style: TextStyle(color: AppColors.slate500))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: profile!.currentSkills.map((s) => AppBadge(label: s, variant: AppBadgeVariant.info)).toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _infoCard('Tài khoản', [
            _row('Email', user?.email),
            _row('Tham gia', user?.createdAt != null ? formatRelativeTime(user!.createdAt) : null),
            _row('GitHub', (profile?.githubUsername ?? user?.githubUsername) != null ? '@${profile?.githubUsername ?? user?.githubUsername}' : 'Chưa liên kết'),
          ]),
        ],
      ],
    );
  }

  Widget _infoCard(String title, List<Widget> rows) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }

  Widget _row(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(color: AppColors.slate500))),
          Expanded(
            child: Text(
              (value == null || value.isEmpty) ? '—' : value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
