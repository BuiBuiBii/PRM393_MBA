import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/app_models.dart';
import '../../../shared/utils/format_utils.dart';
import '../../../shared/widgets/app_widgets.dart';

/// Card hiển thị 1 repository trong danh sách.
class RepositoryCard extends StatelessWidget {
  const RepositoryCard({
    super.key,
    required this.repo,
    required this.hasAnalysis,
    required this.isAnalyzing,
    required this.analyzeDisabled,
    required this.onAnalyze,
  });

  final RepositoryModel repo;
  final bool hasAnalysis;
  final bool isAnalyzing;
  final bool analyzeDisabled;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => context.push('/repositories/${repo.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(repo.name, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
                      if (repo.description != null)
                        Text(
                          repo.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.appCaptionStyle,
                        ),
                    ],
                  ),
                ),
              ),
              AppBadge(label: repo.language),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _MetaChip(icon: Icons.star, text: '${repo.stars}'),
              _MetaChip(icon: Icons.call_split, text: '${repo.forks}'),
              AppBadge(
                label: hasAnalysis ? 'Đã phân tích' : 'Chưa phân tích',
                variant: hasAnalysis ? AppBadgeVariant.success : AppBadgeVariant.neutral,
              ),
              Text(formatRelativeTime(repo.updatedAt), style: context.appLabelStyle),
            ],
          ),
          const SizedBox(height: 12),
          if (hasAnalysis)
            PrimaryButton(
              label: 'Xem phân tích',
              outlined: true,
              expand: true,
              onPressed: () => context.push('/repositories/${repo.id}/analysis'),
            ),
          const SizedBox(height: 8),
          PrimaryButton(
            label: isAnalyzing ? 'Đang phân tích...' : (hasAnalysis ? 'Phân tích lại' : 'Phân tích'),
            icon: hasAnalysis ? Icons.refresh : Icons.play_arrow,
            loading: isAnalyzing,
            expand: true,
            onPressed: analyzeDisabled ? null : onAnalyze,
          ),
          TextButton.icon(
            onPressed: () => launchUrl(Uri.parse(repo.url), mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Mở GitHub'),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: context.appTextSecondary),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 13, color: context.appTextPrimary)),
      ],
    );
  }
}
