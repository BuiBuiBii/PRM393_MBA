import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../shared/widgets/app_image_assets.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../auth/providers/auth_provider.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  static const _primaryTabs = [
    _ShellTab(path: '/dashboard', label: 'Trang chủ', icon: Icons.home_outlined, selectedIcon: Icons.home),
    _ShellTab(path: '/repositories', label: 'Repos', icon: Icons.folder_outlined, selectedIcon: Icons.folder),
    _ShellTab(path: '/profile', label: 'Hồ sơ', icon: Icons.person_outline, selectedIcon: Icons.person),
    _ShellTab(path: '/chat', label: 'AI Mentor', icon: Icons.chat_bubble_outline, selectedIcon: Icons.chat_bubble),
  ];

  static const _secondaryItems = [
    _MenuItem(path: '/roadmaps', label: 'Lộ trình', icon: Icons.route_outlined),
    _MenuItem(path: '/settings', label: 'Cài đặt', icon: Icons.settings_outlined),
    _MenuItem(path: '/home', label: 'Giới thiệu', icon: Icons.info_outline),
    _MenuItem(path: '/progress', label: 'Tiến độ', icon: Icons.trending_up),
    _MenuItem(path: '/github/connect', label: 'GitHub', icon: Icons.code),
    _MenuItem(path: '/notifications', label: 'Thông báo', icon: Icons.notifications_outlined),
  ];

  String get _location => GoRouterState.of(context).matchedLocation;

  bool _routeActive(String path) {
    final loc = _location;
    if (path == '/dashboard') return loc == '/dashboard';
    return loc == path || loc.startsWith('$path/');
  }

  int? _selectedIndex() {
    for (var i = 0; i < _primaryTabs.length; i++) {
      if (_routeActive(_primaryTabs[i].path)) return i;
    }
    return null;
  }

  bool _isSecondaryActive() => _secondaryItems.any((item) => _routeActive(item.path));

  void _navigateTo(String path) {
    GoRouter.of(context).go(path);
  }

  void _navigateFromSheet(BuildContext sheetContext, String path) {
    Navigator.pop(sheetContext);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _navigateTo(path);
    });
  }

  String? _pageTitle() {
    return switch (_location) {
      '/profile' => 'Hồ sơ của tôi',
      '/settings' => 'Cài đặt',
      '/notifications' => 'Thông báo',
      '/progress' => 'Tiến độ học tập',
      '/github/connect' => 'Kết nối GitHub',
      '/home' => 'Giới thiệu',
      _ => null,
    };
  }

  void _openMenu() {
    final location = _location;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Menu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const Divider(height: 1),
              for (final item in _secondaryItems)
                ListTile(
                  leading: Icon(
                    item.icon,
                    color: (location == item.path || location.startsWith('${item.path}/'))
                        ? AppColors.primary
                        : AppColors.slate600,
                  ),
                  title: Text(
                    item.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: (location == item.path || location.startsWith('${item.path}/'))
                          ? AppColors.primary
                          : AppColors.slate900,
                    ),
                  ),
                  tileColor: (location == item.path || location.startsWith('${item.path}/'))
                      ? const Color(0xFFEEF2FF)
                      : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () => _navigateFromSheet(sheetContext, item.path),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final selected = _selectedIndex();
    final onSecondary = _isSecondaryActive();

    return AppGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.white.withValues(alpha: 0.8),
          elevation: 0,
          scrolledUnderElevation: 0,
          titleSpacing: 16,
          title: GestureDetector(
            onTap: () => _navigateTo('/dashboard'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppBrandLogo(size: 32, withBackground: true),
                const SizedBox(width: 8),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [AppColors.primary, AppColors.purple],
                  ).createShader(bounds),
                  child: const Text(
                    'GitAnalyzer',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (user?.isAdmin == true)
              _ShellActionButton(
                tooltip: 'Admin Console',
                active: false,
                onPressed: () => _navigateTo('/admin'),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF312E81).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.admin_panel_settings_outlined, size: 18, color: Color(0xFF312E81)),
                ),
              ),
            _ShellActionButton(
              tooltip: 'Hồ sơ',
              active: _routeActive('/profile'),
              onPressed: () => _navigateTo('/profile'),
              child: UserAvatar(imageUrl: user?.avatar, name: user?.name, size: 28),
            ),
            _ShellActionButton(
              tooltip: 'Cài đặt',
              active: _routeActive('/settings'),
              onPressed: () => _navigateTo('/settings'),
              child: Icon(
                Icons.settings_outlined,
                size: 22,
                color: _routeActive('/settings') ? AppColors.primary : AppColors.slate600,
              ),
            ),
            _ShellActionButton(
              tooltip: 'Thông báo',
              active: _routeActive('/notifications'),
              onPressed: () => _navigateTo('/notifications'),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    size: 22,
                    color: _routeActive('/notifications') ? AppColors.primary : AppColors.slate600,
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Column(
          children: [
            if (AppConfig.demoMode)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: BannerMessage(
                  message: 'Đang chạy chế độ demo — dữ liệu mẫu, không cần backend.',
                  isWarning: true,
                ),
              ),
            if (_pageTitle() != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _pageTitle()!,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ),
              ),
            Expanded(
              child: KeyedSubtree(
                key: ValueKey(_location),
                child: widget.child,
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            border: const Border(top: BorderSide(color: Color(0x33CBD5E1))),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  for (var i = 0; i < _primaryTabs.length; i++)
                    Expanded(
                      child: _BottomNavItem(
                        icon: selected == i ? _primaryTabs[i].selectedIcon : _primaryTabs[i].icon,
                        label: _primaryTabs[i].label.split(' ').first,
                        active: selected == i,
                        onTap: () => _navigateTo(_primaryTabs[i].path),
                      ),
                    ),
                  Expanded(
                    child: _BottomNavItem(
                      icon: Icons.menu,
                      label: 'Thêm',
                      active: onSecondary,
                      onTap: _openMenu,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShellActionButton extends StatelessWidget {
  const _ShellActionButton({
    required this.tooltip,
    required this.active,
    required this.onPressed,
    required this.child,
  });

  final String tooltip;
  final bool active;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Semantics(
          button: true,
          label: tooltip,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: DecoratedBox(
                decoration: active
                    ? BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                      )
                    : const BoxDecoration(),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.slate500;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 56,
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShellTab {
  const _ShellTab({required this.path, required this.label, required this.icon, required this.selectedIcon});
  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _MenuItem {
  const _MenuItem({required this.path, required this.label, required this.icon});
  final String path;
  final String label;
  final IconData icon;
}
