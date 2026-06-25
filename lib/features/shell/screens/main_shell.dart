import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
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
    _MenuItem(path: '/snapshots', label: 'Snapshots', icon: Icons.history_edu),
    _MenuItem(path: '/ai-feedback', label: 'AI Feedback', icon: Icons.auto_awesome_outlined),
    _MenuItem(path: '/profile', label: 'Hồ sơ', icon: Icons.person_outline),
    _MenuItem(path: '/roadmaps', label: 'Lộ trình', icon: Icons.route_outlined),
    _MenuItem(path: '/chat', label: 'AI Mentor', icon: Icons.chat_bubble_outline),
    _MenuItem(path: '/github/connect', label: 'GitHub', icon: Icons.code),
    _MenuItem(path: '/settings', label: 'Cài đặt', icon: Icons.settings_outlined),
  ];

  static const _rootPaths = {
    '/dashboard',
    '/repositories',
    '/snapshots',
    '/ai-feedback',
    '/profile',
    '/roadmaps',
    '/chat',
    '/github/connect',
    '/settings',
    '/notifications',
  };

  String get _location => GoRouterState.of(context).matchedLocation;

  bool get _isRootRoute => _rootPaths.contains(_location);

  bool get _showBackButton => !_isRootRoute;

  bool _routeActive(String path) {
    if (path == '/dashboard') return _location == '/dashboard';
    return _location == path || _location.startsWith('$path/');
  }

  String _title() {
    final segments = GoRouterState.of(context).uri.pathSegments;
    if (segments.isNotEmpty) {
      switch (segments[0]) {
        case 'repositories':
          if (segments.length >= 3) {
            return switch (segments[2]) {
              'snapshots' => 'Lịch sử phân tích',
              'progress' => 'Tiến bộ Repository',
              'analysis' => 'Kết quả phân tích',
              _ => 'Repository',
            };
          }
          if (segments.length >= 2) return 'Repository';
          return 'Repositories';
        case 'snapshots':
          return segments.length >= 2 ? 'Chi tiết Snapshot' : 'Snapshots';
        case 'roadmaps':
          return segments.length >= 2 ? 'Chi tiết lộ trình' : 'Lộ trình';
        case 'analysis':
          return 'Kết quả phân tích';
      }
    }

    for (final item in _navItems) {
      if (_routeActive(item.path)) return item.label;
    }
    return 'GitAnalyzer';
  }

  String? _fallbackParentRoute() {
    final segments = GoRouterState.of(context).uri.pathSegments;
    if (segments.isEmpty) return '/dashboard';

    switch (segments[0]) {
      case 'repositories':
        if (segments.length >= 3) return '/repositories/${segments[1]}';
        if (segments.length >= 2) return '/repositories';
        return null;
      case 'snapshots':
        if (segments.length >= 2) return '/snapshots';
        return null;
      case 'roadmaps':
        if (segments.length >= 2) return '/roadmaps';
        return null;
      case 'analysis':
        return '/repositories';
      default:
        return null;
    }
  }

  void _handleBack() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }

    final parent = _fallbackParentRoute();
    if (parent != null) {
      router.go(parent);
    }
  }

  void _navigateTo(String path) {
    GoRouter.of(context).go(path);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final cs = Theme.of(context).colorScheme;

    return AppGradientBackground(
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        appBar: AppAppBar(
          title: _title(),
          leading: _showBackButton
              ? IconButton(
                  tooltip: 'Quay lại',
                  onPressed: _handleBack,
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
                color: _routeActive('/notifications') ? AppColors.primary : context.appTextSecondary,
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
                          color: _routeActive(item.path) ? AppColors.primary : cs.onSurfaceVariant,
                        ),
                        title: Text(
                          item.label,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: _routeActive(item.path) ? AppColors.primary : cs.onSurface,
                          ),
                        ),
                        selected: _routeActive(item.path),
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
                leading: Icon(Icons.logout, color: cs.onSurfaceVariant),
                title: Text('Đăng xuất', style: TextStyle(color: cs.onSurface)),
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
              child: PopScope(
                canPop: !_showBackButton,
                onPopInvokedWithResult: (didPop, _) {
                  if (!didPop && _showBackButton) _handleBack();
                },
                child: KeyedSubtree(
                  key: ValueKey(_location),
                  child: widget.child,
                ),
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
