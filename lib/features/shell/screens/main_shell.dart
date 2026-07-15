import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_navigator_keys.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_app_bar.dart';
import '../../../shared/widgets/app_image_assets.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../widgets/app_drawer.dart';
import '../../feature_providers.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    if (!AppConfig.demoMode) {
      Future.microtask(() => ref.read(roleCatalogProvider.future));
    }
  }

  static const _navItems = [
    ShellNavItem(
        path: '/dashboard', label: 'Tổng quan', icon: Icons.dashboard_outlined),
    ShellNavItem(
        path: '/repositories',
        label: 'Repositories',
        icon: Icons.folder_outlined),
    ShellNavItem(
        path: '/snapshots', label: 'Snapshots', icon: Icons.history_edu),
    ShellNavItem(
        path: '/ai-feedback',
        label: 'AI Feedback',
        icon: Icons.auto_awesome_outlined),
    ShellNavItem(path: '/profile', label: 'Hồ sơ', icon: Icons.person_outline),
    ShellNavItem(
        path: '/roadmaps', label: 'Lộ trình', icon: Icons.route_outlined),
    ShellNavItem(
        path: '/chat', label: 'AI Mentor', icon: Icons.chat_bubble_outline),
    ShellNavItem(path: '/github/connect', label: 'GitHub', icon: Icons.code),
    ShellNavItem(
        path: '/settings', label: 'Cài đặt', icon: Icons.settings_outlined),
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

  bool get _shellCanPop =>
      mainShellNavigatorKey.currentState?.canPop() ?? false;

  bool get _showBackButton {
    if (!_isRootRoute) return true;
    return _shellCanPop || GoRouter.of(context).canPop();
  }

  String? get _backTooltip {
    final parent = _fallbackParentRoute();
    if (parent == null) return 'Quay lại';
    return switch (parent) {
      '/dashboard' => 'Về Tổng quan',
      '/repositories' => 'Về Repositories',
      '/snapshots' => 'Về Snapshots',
      '/roadmaps' => 'Về Lộ trình',
      '/settings' => 'Về Cài đặt',
      '/profile' => 'Về Hồ sơ',
      '/notifications' => 'Về Thông báo',
      '/github/connect' => 'Về GitHub',
      _
          when parent.startsWith('/repositories/') &&
              parent.split('/').length == 3 =>
        'Về Repository',
      _ when parent.endsWith('/snapshots') => 'Về lịch sử phân tích',
      _ => 'Quay lại',
    };
  }

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

    if (_location == '/notifications') return 'Thông báo';

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
        if (segments.length >= 3) {
          return switch (segments[2]) {
            'progress' => '/repositories/${segments[1]}/snapshots',
            'snapshots' || 'analysis' => '/repositories/${segments[1]}',
            _ => '/repositories/${segments[1]}',
          };
        }
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
      case 'notifications':
        return '/dashboard';
      case 'profile':
        return '/dashboard';
      case 'github':
        if (segments.length >= 2 && segments[1] == 'connect') {
          return '/settings';
        }
        return '/dashboard';
      default:
        return null;
    }
  }

  void _handleBack() {
    // Trang con: điều hướng về parent bằng path (ShellRoute không luôn có stack pop).
    if (!_isRootRoute) {
      final parent = _fallbackParentRoute();
      if (parent != null) {
        GoRouter.of(context).go(parent);
        return;
      }
    }

    // Trang push lên shell navigator (vd. notifications).
    final shellNav = mainShellNavigatorKey.currentState;
    if (shellNav != null && shellNav.canPop()) {
      shellNav.pop();
      return;
    }

    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }

    if (!_isRootRoute) {
      router.go('/dashboard');
    }
  }

  void _navigateTo(String path) {
    GoRouter.of(context).go(path);
  }

  void _openNotifications() {
    if (_location == '/notifications') return;
    context.push('/notifications');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user;

    return AppGradientBackground(
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        appBar: AppAppBar(
          title: _showBackButton ? _title() : '',
          showBrand: !_showBackButton,
          leading: _showBackButton
              ? IconButton(
                  tooltip: _backTooltip ?? 'Quay lại',
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
                icon: const Icon(Icons.admin_panel_settings_outlined,
                    color: Color(0xFF312E81)),
              ),
            IconButton(
              tooltip: 'Thông báo',
              onPressed: _openNotifications,
              icon: Icon(
                Icons.notifications_outlined,
                color: _routeActive('/notifications')
                    ? AppColors.primary
                    : context.appTextSecondary,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _navigateTo('/profile'),
                child: UserAvatar(
                    imageUrl: user?.avatar, name: user?.name, size: 30),
              ),
            ),
          ],
        ),
        drawer: AppDrawer(
          navItems: _navItems,
          routeActive: _routeActive,
          onNavigate: _navigateTo,
        ),
        body: Column(
          children: [
            if (AppConfig.demoMode)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: BannerMessage(
                  message:
                      'Đang chạy chế độ demo — dữ liệu mẫu, không cần backend.',
                  isWarning: true,
                ),
              ),
            Expanded(
              child: PopScope(
                canPop: !_showBackButton,
                onPopInvokedWithResult: (didPop, _) {
                  if (!didPop && _showBackButton) _handleBack();
                },
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
