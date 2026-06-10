import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_image_assets.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../auth/providers/auth_provider.dart';

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _navItems = [
    _AdminNavItem(path: '/admin', label: 'Tổng quan', icon: Icons.dashboard_outlined),
    _AdminNavItem(path: '/admin/users', label: 'Người dùng', icon: Icons.people_outline),
    _AdminNavItem(path: '/admin/reports', label: 'Báo cáo', icon: Icons.flag_outlined),
    _AdminNavItem(path: '/admin/repositories', label: 'Repositories', icon: Icons.folder_copy_outlined),
    _AdminNavItem(path: '/admin/analysis', label: 'Phân tích', icon: Icons.analytics_outlined),
    _AdminNavItem(path: '/admin/ai-feedback', label: 'AI Feedback', icon: Icons.auto_awesome_outlined),
    _AdminNavItem(path: '/admin/roadmaps', label: 'Roadmaps', icon: Icons.route_outlined),
  ];

  String get _location => GoRouterState.of(context).matchedLocation;

  bool _active(String path) {
    if (path == '/admin') return _location == '/admin';
    return _location == path || _location.startsWith('$path/');
  }

  String _title() {
    for (final item in _navItems) {
      if (_active(item.path)) return item.label;
    }
    return 'Admin';
  }

  bool get _isDetailRoute => GoRouterState.of(context).uri.pathSegments.length > 2;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final canPop = GoRouter.of(context).canPop();

    return AppGradientBackground(
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E1B4B).withValues(alpha: 0.95),
          foregroundColor: Colors.white,
          elevation: 0,
          leading: _isDetailRoute && canPop
              ? IconButton(
                  tooltip: 'Quay lại',
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                )
              : IconButton(
                  tooltip: 'Menu admin',
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  icon: const Icon(Icons.menu),
                ),
          title: Row(
            children: [
              const AppBrandLogo(size: 28, withBackground: true),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Admin Console', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  Text(_title(), style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.75))),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Về app học viên',
              onPressed: () => context.go('/dashboard'),
              icon: const Icon(Icons.school_outlined, size: 22),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: UserAvatar(imageUrl: user?.avatar, name: user?.name, size: 30),
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
                      const AppBadge(label: 'Quản trị hệ thống', variant: AppBadgeVariant.info),
                      const SizedBox(height: 8),
                      Text(user?.name ?? 'Admin', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(user?.email ?? '', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    for (final item in _navItems)
                      ListTile(
                        leading: Icon(item.icon, color: _active(item.path) ? AppColors.primary : AppColors.slate600),
                        title: Text(
                          item.label,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: _active(item.path) ? AppColors.primary : AppColors.slate900,
                          ),
                        ),
                        selected: _active(item.path),
                        selectedTileColor: const Color(0xFFEEF2FF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onTap: () {
                          Navigator.pop(context);
                          context.go(item.path);
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
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                },
              ),
            ],
          ),
        ),
        body: KeyedSubtree(key: ValueKey(_location), child: widget.child),
      ),
    );
  }
}

class _AdminNavItem {
  const _AdminNavItem({required this.path, required this.label, required this.icon});
  final String path;
  final String label;
  final IconData icon;
}
