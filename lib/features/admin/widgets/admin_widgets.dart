import 'package:flutter/material.dart';

import '../../../shared/widgets/app_widgets.dart';
import '../models/admin_models.dart';

class AdminSectionHeader extends StatelessWidget {
  const AdminSectionHeader({super.key, required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return PageHeader(title: title, subtitle: subtitle, trailing: trailing);
  }
}

class AdminPaginationBar extends StatelessWidget {
  const AdminPaginationBar({
    super.key,
    required this.pagination,
    required this.onPrev,
    required this.onNext,
  });

  final AdminPagination pagination;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Trang ${pagination.page}/${pagination.totalPages == 0 ? 1 : pagination.totalPages} • ${pagination.total} mục',
              style: const TextStyle(color: AppColors.slate500, fontSize: 13),
            ),
          ),
          IconButton(
            onPressed: pagination.hasPrev ? onPrev : null,
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            onPressed: pagination.hasNext ? onNext : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class AdminSearchField extends StatelessWidget {
  const AdminSearchField({super.key, required this.controller, required this.hint, required this.onSubmitted});

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      ),
      textInputAction: TextInputAction.search,
      onSubmitted: onSubmitted,
    );
  }
}

class AdminListTileCard extends StatelessWidget {
  const AdminListTileCard({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.badges = const [],
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> badges;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: const TextStyle(color: AppColors.slate500, fontSize: 13)),
                ],
                if (badges.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6, children: badges),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

AppBadgeVariant adminStatusBadge(String status) {
  switch (status) {
    case 'active':
    case 'resolved':
      return AppBadgeVariant.success;
    case 'pending':
    case 'reviewing':
      return AppBadgeVariant.warning;
    case 'banned':
    case 'rejected':
      return AppBadgeVariant.info;
    default:
      return AppBadgeVariant.neutral;
  }
}

AppBadge adminStatusLabel(String status) {
  final labels = {
    'active': 'Hoạt động',
    'inactive': 'Ngưng',
    'banned': 'Bị cấm',
    'pending': 'Chờ xử lý',
    'reviewing': 'Đang xem',
    'resolved': 'Đã xử lý',
    'rejected': 'Từ chối',
    'archived': 'Lưu trữ',
  };
  return AppBadge(label: labels[status] ?? status, variant: adminStatusBadge(status));
}

AppBadge adminRoleBadge(String role) {
  final variant = role == 'admin'
      ? AppBadgeVariant.info
      : role == 'mentor'
          ? AppBadgeVariant.success
          : AppBadgeVariant.neutral;
  return AppBadge(label: role, variant: variant);
}

class AdminQuickNavCard extends StatelessWidget {
  const AdminQuickNavCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.count,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? count;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(subtitle, style: const TextStyle(color: AppColors.slate500, fontSize: 12)),
              ],
            ),
          ),
          if (count != null) ...[
            Text(count!, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 18)),
            const SizedBox(width: 4),
          ],
          const Icon(Icons.chevron_right, color: AppColors.slate500),
        ],
      ),
    );
  }
}
