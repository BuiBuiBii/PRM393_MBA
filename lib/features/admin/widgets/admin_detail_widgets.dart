import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_widgets.dart';

class AdminBreadcrumbItem {
  const AdminBreadcrumbItem({required this.label, this.path});

  final String label;
  final String? path;
}

List<AdminBreadcrumbItem> adminBreadcrumbItems(String location) {
  const labels = {
    '/admin': 'Tổng quan',
    '/admin/users': 'Người dùng',
    '/admin/reports': 'Báo cáo',
    '/admin/repositories': 'Repositories',
    '/admin/analysis': 'Phân tích',
    '/admin/ai-feedback': 'AI Feedback',
    '/admin/roadmaps': 'Roadmaps',
  };

  if (location == '/admin') {
    return [const AdminBreadcrumbItem(label: 'Tổng quan')];
  }

  String? parent;
  String detailLabel = 'Chi tiết';
  if (location.startsWith('/admin/users/')) {
    parent = '/admin/users';
    detailLabel = 'Chi tiết người dùng';
  } else if (location.startsWith('/admin/reports/')) {
    parent = '/admin/reports';
    detailLabel = 'Chi tiết báo cáo';
  } else if (location.startsWith('/admin/repositories/')) {
    parent = '/admin/repositories';
    detailLabel = 'Chi tiết repository';
  } else if (location.startsWith('/admin/analysis/')) {
    parent = '/admin/analysis';
    detailLabel = 'Chi tiết phân tích';
  } else if (location.startsWith('/admin/ai-feedback/')) {
    parent = '/admin/ai-feedback';
    detailLabel = 'Chi tiết feedback';
  } else if (location.startsWith('/admin/roadmaps/')) {
    parent = '/admin/roadmaps';
    detailLabel = 'Chi tiết roadmap';
  }

  if (parent != null) {
    return [
      AdminBreadcrumbItem(label: labels[parent] ?? 'Admin', path: parent),
      AdminBreadcrumbItem(label: detailLabel),
    ];
  }

  final label = labels[location];
  if (label != null) return [AdminBreadcrumbItem(label: label)];
  return [const AdminBreadcrumbItem(label: 'Admin', path: '/admin')];
}

class AdminBreadcrumb extends StatelessWidget {
  const AdminBreadcrumb({super.key, required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    final items = adminBreadcrumbItems(location);
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          const Icon(Icons.admin_panel_settings_outlined, size: 14, color: AppColors.slate500),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              const Icon(Icons.chevron_right, size: 14, color: AppColors.slate500),
            if (items[i].path != null && i < items.length - 1)
              InkWell(
                onTap: () => context.go(items[i].path!),
                child: Text(
                  items[i].label,
                  style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                ),
              )
            else
              Text(
                items[i].label,
                style: TextStyle(
                  fontSize: 12,
                  color: i == items.length - 1 ? AppColors.slate900 : AppColors.slate500,
                  fontWeight: i == items.length - 1 ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class AdminTextListCard extends StatelessWidget {
  const AdminTextListCard({
    super.key,
    required this.title,
    required this.items,
    this.variant = AppBadgeVariant.neutral,
  });

  final String title;
  final List<String> items;
  final AppBadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const Text('Chưa có nội dung.', style: TextStyle(color: AppColors.slate500, fontSize: 13))
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppBadge(label: 'Mục', variant: variant),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item, style: const TextStyle(height: 1.4))),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AdminDetailStatGrid extends StatelessWidget {
  const AdminDetailStatGrid({super.key, required this.items});

  final List<(String label, String value)> items;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        for (final item in items)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.$1, style: const TextStyle(color: AppColors.slate500, fontSize: 12)),
                const SizedBox(height: 6),
                Text(item.$2, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              ],
            ),
          ),
      ],
    );
  }
}

Widget adminDetailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 120, child: Text(label, style: const TextStyle(color: AppColors.slate500, fontSize: 13))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ],
    ),
  );
}
