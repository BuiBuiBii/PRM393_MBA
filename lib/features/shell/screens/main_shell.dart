import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../shared/widgets/app_app_bar.dart';
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
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _navItems = [
    _MenuItem(path: '/dashboard', label: 'Tổng quan', icon: Icons.dashboard_outlined),
    _MenuItem(path: '/repositories', label: 'Repositories', icon: Icons.folder_outlined),
    _MenuItem(path: '/ai-feedback', label: 'AI Feedback', icon: Icons.auto_awesome_outlined),
    _MenuItem(path: '/profile', label: 'Hồ sơ', icon: Icons.person_outline),
    _MenuItem(path: '/roadmaps', label: 'Lộ trình', icon: Icons.route_outlined),
    _MenuItem(path: '/chat', label: 'AI Mentor', icon: Icons.chat_bubble_outline),
    _MenuItem(path: '/progress', label: 'Tiến độ', icon: Icons.trending_up),
    _MenuItem(path: '/github/connect', label: 'GitHub', icon: Icons.code),
    _MenuItem(path: '/notifications', label: 'Thông báo', icon: Icons.notifications_outlined),
    _MenuItem(path: '/settings', label: 'Cài đặt', icon: Icons.settings_outlined),
    _MenuItem(path: '/home', label: 'Giới thiệu', icon: Icons.info_outline),
  ];

  String get _location => GoRouterState.of(context).matchedLocation;

  bool _routeActive(String path) {
    if (path == '/dashboard') return _location == '/dashboard';
    return _location == path || _location.startsWith('$path/');
  }

  String _title() {
    for (final item in _navItems) {
      if (_routeActive(item.path)) return item.label;
    }
    return 'GitAnalyzer';
  }

  void _navigateTo(String path) {
    GoRouter.of(context).go(path);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final canPop = GoRouter.of(context).canPop();

    return AppGradientBackground(
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        appBar: AppAppBar(
          title: _title(),
          leading: canPop
              ? IconButton(
                  tooltip: 'Quay lại',
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                )
              : IconButton(
                  tooltip: 'Menu',
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  icon: const Icon(Icons.menu),
                ),
          actions: [
            if (user?.isAdmin == true)
              IconButton(
                tooltip: 'Admin Console',
                onPressed: () => _navigateTo('/admin'),
                icon: const Icon(Icons.admin_panel_settings_outlined, color: Color(0xFF312E81)),
              ),
            IconButton(
              tooltip: 'Thông báo',
              onPressed: () => _navigateTo('/notifications'),
              icon: Icon(
                Icons.notifications_outlined,
                color: _routeActive('/notifications') ? AppColors.primary : AppColors.slate600,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _navigateTo('/profile'),
                child: UserAvatar(imageUrl: user?.avatar, name: user?.name, size: 30),
              ),
            ),
          ],
        ),
        drawer: Drawer(
          child: Column(
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF312E81), Color(0xFF4F46E5)],
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const AppBadge(label: 'Học viên', variant: AppBadgeVariant.info),
                      const SizedBox(height: 8),
                      Text(
                        user?.name ?? 'Người dùng',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  children: [
                    for (final item in _navItems)
                      ListTile(
                        leading: Icon(
                          item.icon,
                          color: _routeActive(item.path) ? AppColors.primary : AppColors.slate600,
                        ),
                        title: Text(
                          item.label,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: _routeActive(item.path) ? AppColors.primary : AppColors.slate900,
                          ),
                        ),
                        selected: _routeActive(item.path),
                        selectedTileColor: const Color(0xFFEEF2FF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onTap: () {
                          Navigator.pop(context);
                          _navigateTo(item.path);
                        },
                      ),
                    if (user?.isAdmin == true)
                      ListTile(
                        leading: const Icon(Icons.admin_panel_settings_outlined, color: Color(0xFF312E81)),
                        title: const Text(
                          'Admin Console',
                          style: TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF312E81)),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onTap: () {
                          Navigator.pop(context);
                          _navigateTo('/admin');
                        },
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.slate600),
                title: const Text('Đăng xuất'),
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                },
              ),
            ],
          ),
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
            Expanded(
              child: KeyedSubtree(
                key: ValueKey(_location),
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem({required this.path, required this.label, required this.icon});
  final String path;
  final String label;
  final IconData icon;
}
