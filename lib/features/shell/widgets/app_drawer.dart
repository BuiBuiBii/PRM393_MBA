import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_widgets.dart';
import '../../auth/providers/auth_provider.dart';

class ShellNavItem {
  const ShellNavItem({required this.path, required this.label, required this.icon});

  final String path;
  final String label;
  final IconData icon;
}

class AppDrawer extends ConsumerWidget {
  const AppDrawer({
    super.key,
    required this.navItems,
    required this.routeActive,
    required this.onNavigate,
  });

  final List<ShellNavItem> navItems;
  final bool Function(String path) routeActive;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final cs = Theme.of(context).colorScheme;

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF312E81), Color(0xFF4F46E5)]),
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
                for (final item in navItems)
                  ListTile(
                    leading: Icon(
                      item.icon,
                      color: routeActive(item.path) ? AppColors.primary : cs.onSurfaceVariant,
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: routeActive(item.path) ? AppColors.primary : cs.onSurface,
                      ),
                    ),
                    selected: routeActive(item.path),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () {
                      Navigator.pop(context);
                      onNavigate(item.path);
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
                      onNavigate('/admin');
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
    );
  }
}
