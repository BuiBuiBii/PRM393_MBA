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
  var _menuOpen = false;

  static const _primaryTabs = [
    _ShellTab(path: '/dashboard', label: 'Trang chủ', icon: Icons.home_outlined, selectedIcon: Icons.home),
    _ShellTab(path: '/repositories', label: 'Repos', icon: Icons.folder_outlined, selectedIcon: Icons.folder),
    _ShellTab(path: '/roadmaps', label: 'Lộ trình', icon: Icons.route_outlined, selectedIcon: Icons.route),
    _ShellTab(path: '/chat', label: 'AI Mentor', icon: Icons.chat_bubble_outline, selectedIcon: Icons.chat_bubble),
  ];

  static const _secondaryItems = [
    _MenuItem(path: '/dashboard', label: 'Tổng quan', icon: Icons.dashboard_outlined),
    _MenuItem(path: '/progress', label: 'Tiến độ', icon: Icons.trending_up),
    _MenuItem(path: '/github/connect', label: 'GitHub', icon: Icons.code),
    _MenuItem(path: '/notifications', label: 'Thông báo', icon: Icons.notifications_outlined),
    _MenuItem(path: '/settings', label: 'Cài đặt', icon: Icons.settings_outlined),
  ];

  int? _selectedIndex(String location) {
    for (var i = 0; i < _primaryTabs.length; i++) {
      if (location.startsWith(_primaryTabs[i].path)) return i;
    }
    return null;
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final selected = _selectedIndex(location);

    return AppGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.white.withValues(alpha: 0.8),
          elevation: 0,
          scrolledUnderElevation: 0,
          titleSpacing: 16,
          title: GestureDetector(
            onTap: () => context.go('/dashboard'),
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
            IconButton(
              tooltip: 'Thông báo',
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_outlined),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    ),
                  ),
                ],
              ),
              onPressed: () => context.push('/notifications'),
            ),
            IconButton(
              tooltip: 'Đăng xuất',
              icon: const Icon(Icons.logout),
              onPressed: _logout,
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                if (AppConfig.demoMode)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: BannerMessage(
                      message: 'Đang chạy chế độ demo — dữ liệu mẫu, không cần backend.',
                      isWarning: true,
                    ),
                  ),
                Expanded(child: widget.child),
              ],
            ),
            if (_menuOpen)
              _MobileMenuSheet(
                items: _secondaryItems,
                currentPath: location,
                onClose: () => setState(() => _menuOpen = false),
                onNavigate: (path) {
                  setState(() => _menuOpen = false);
                  context.push(path);
                },
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
              height: 52,
              child: Row(
                children: [
                  for (var i = 0; i < _primaryTabs.length; i++)
                    Expanded(
                      child: _BottomNavItem(
                        icon: selected == i ? _primaryTabs[i].selectedIcon : _primaryTabs[i].icon,
                        label: _primaryTabs[i].label.split(' ').first,
                        active: selected == i,
                        onTap: () {
                          setState(() => _menuOpen = false);
                          context.go(_primaryTabs[i].path);
                        },
                      ),
                    ),
                  Expanded(
                    child: _BottomNavItem(
                      icon: Icons.menu,
                      label: 'Thêm',
                      active: false,
                      onTap: () => setState(() => _menuOpen = true),
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
    return InkWell(
      onTap: onTap,
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
    );
  }
}

class _MobileMenuSheet extends StatelessWidget {
  const _MobileMenuSheet({
    required this.items,
    required this.currentPath,
    required this.onClose,
    required this.onNavigate,
  });

  final List<_MenuItem> items;
  final String currentPath;
  final VoidCallback onClose;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          GestureDetector(
            onTap: onClose,
            child: Container(color: Colors.black.withValues(alpha: 0.5)),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
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
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(8),
                      children: [
                        for (final item in items)
                          ListTile(
                            leading: Icon(
                              item.icon,
                              color: currentPath.startsWith(item.path) ? AppColors.primary : AppColors.slate600,
                            ),
                            title: Text(
                              item.label,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: currentPath.startsWith(item.path) ? AppColors.primary : AppColors.slate900,
                              ),
                            ),
                            tileColor: currentPath.startsWith(item.path) ? const Color(0xFFEEF2FF) : null,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            onTap: () => onNavigate(item.path),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: MediaQuery.paddingOf(context).bottom + 8),
                ],
              ),
            ),
          ),
        ],
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
