import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
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
    '/admin/chat': 'Tin nhắn hỗ trợ',
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
  } else if (location.startsWith('/admin/chat/')) {
    parent = '/admin/chat';
    detailLabel = 'Chi tiết tin nhắn';
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
          Icon(Icons.admin_panel_settings_outlined, size: 14, color: context.appTextSecondary),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Icon(Icons.chevron_right, size: 14, color: context.appTextSecondary),
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
                  color: i == items.length - 1 ? context.appTextPrimary : context.appTextSecondary,
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
          Text(title, style: context.appSectionTitleStyle.copyWith(fontSize: 15)),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Text('Chưa có nội dung.', style: context.appCaptionStyle)
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppBadge(label: 'Mục', variant: variant),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item, style: context.appBodyStyle)),
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
                Text(item.$1, style: context.appLabelStyle),
                const SizedBox(height: 6),
                Text(item.$2, style: context.appHeadingStyle.copyWith(fontSize: 20)),
              ],
            ),
          ),
      ],
    );
  }
}

Widget adminDetailRow(BuildContext context, String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 120, child: Text(label, style: context.appLabelStyle)),
        Expanded(child: Text(value, style: context.appBodyStyle.copyWith(fontSize: 13))),
      ],
    ),
  );
}
