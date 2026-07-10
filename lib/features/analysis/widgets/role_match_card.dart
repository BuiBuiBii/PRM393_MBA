import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/app_models.dart';
import '../../../shared/widgets/app_widgets.dart';

/// Card hiển thị kết quả Role Match Dev2Vec và nút tạo roadmap.
class RoleMatchCard extends StatefulWidget {
  const RoleMatchCard({
    super.key,
    required this.analysis,
    required this.roleMatch,
    required this.isLoading,
    required this.onCreateRoadmap,
    required this.onRetry,
    this.onSelectMatch,
    this.errorMessage,
  });

  final AnalysisModel analysis;
  final RoleMatchModel? roleMatch;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onCreateRoadmap;
  final VoidCallback onRetry;
  final ValueChanged<RoleMatchItem>? onSelectMatch;

  @override
  State<RoleMatchCard> createState() => _RoleMatchCardState();
}

class _RoleMatchCardState extends State<RoleMatchCard> {
  int _selectedIndex = 0;

  @override
  void didUpdateWidget(RoleMatchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.roleMatch != oldWidget.roleMatch) {
      _selectedIndex = 0;
    }
  }

  RoleMatchItem? get _selectedMatch {
    final matches = widget.roleMatch?.matches ?? [];
    if (matches.isEmpty) return null;
    if (_selectedIndex >= matches.length) return matches.first;
    return matches[_selectedIndex];
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.work_outline, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Hướng nghề nghiệp (Dev2Vec)', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                onPressed: widget.roleMatch?.matches.isNotEmpty == true ? widget.onCreateRoadmap : null,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 14),
                    SizedBox(width: 4),
                    Text('Tạo Roadmap'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    const CircularProgressIndicator(strokeWidth: 2),
                    const SizedBox(height: 8),
                    Text('Đang phân tích role phù hợp...', style: context.appCaptionStyle),
                  ],
                ),
              ),
            )
          else if (widget.roleMatch != null && widget.roleMatch!.matches.isNotEmpty)
            _RoleMatchContent(
              roleMatch: widget.roleMatch!,
              selectedIndex: _selectedIndex,
              onSelectIndex: (index) {
                setState(() => _selectedIndex = index);
                final match = widget.roleMatch!.matches[index];
                widget.onSelectMatch?.call(match);
              },
            )
          else if (widget.errorMessage != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BannerMessage(message: widget.errorMessage!, isError: true),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(onPressed: widget.onRetry, child: const Text('Thử lại')),
                ),
              ],
            )
          else if (widget.analysis.careerDirection != null && widget.analysis.careerDirection!.isNotEmpty)
            Text(widget.analysis.careerDirection!)
          else
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Chưa có dữ liệu Role Match. Phân tích repository trước.',
                    style: context.appCaptionStyle,
                  ),
                ),
                TextButton(onPressed: widget.onRetry, child: const Text('Thử lại')),
              ],
            ),
          if (_selectedMatch != null && _selectedMatch!.recommendedNextSkills.isNotEmpty) ...[
            const SizedBox(height: 12),
            _PriorityCallout(skills: _selectedMatch!.recommendedNextSkills),
          ],
        ],
      ),
    );
  }
}

class _RoleMatchContent extends StatelessWidget {
  const _RoleMatchContent({
    required this.roleMatch,
    required this.selectedIndex,
    required this.onSelectIndex,
  });

  final RoleMatchModel roleMatch;
  final int selectedIndex;
  final ValueChanged<int> onSelectIndex;

  @override
  Widget build(BuildContext context) {
    final selected = roleMatch.matches[selectedIndex.clamp(0, roleMatch.matches.length - 1)];
    final matchScore = selected.matchScore;
    final matchLevelLabel = selected.matchLevelLabel.isNotEmpty ? selected.matchLevelLabel : selected.matchLevel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bạn phù hợp nhất với', style: context.appLabelStyle),
                  const SizedBox(height: 4),
                  Text(
                    selected.role,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                  if (selected.scoringMethod != null && selected.scoringMethod!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Nguồn: ${selected.scoringMethod}', style: context.appCaptionStyle),
                  ],
                ],
              ),
            ),
            if (matchScore > 0)
              AppBadge(
                label: '${matchLevelLabel.isNotEmpty ? matchLevelLabel : 'Match'} · ${matchScore.toStringAsFixed(0)}%',
                variant: _matchLevelVariant(selected.matchLevel),
              ),
          ],
        ),
        if (selected.matchedSkills.isNotEmpty) ...[
          const SizedBox(height: 12),
          RoleMatchSkillSection(
            icon: Icons.check_circle_outline,
            color: AppColors.emerald,
            title: 'Kỹ năng đã có (${selected.matchedSkills.length})',
            skills: selected.matchedSkills,
            variant: AppBadgeVariant.success,
          ),
        ],
        if (selected.missingSkills.isNotEmpty) ...[
          const SizedBox(height: 12),
          RoleMatchSkillSection(
            icon: Icons.warning_amber_outlined,
            color: AppColors.amber,
            title: 'Kỹ năng còn thiếu (${selected.missingSkills.length})',
            skills: selected.missingSkills,
            variant: AppBadgeVariant.warning,
          ),
        ],
        if (roleMatch.matches.length > 1) ...[
          const SizedBox(height: 12),
          Text('Vai trò khác (chạm để chọn)', style: context.appLabelStyle),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < roleMatch.matches.length; i++)
                OtherRoleChip(
                  item: roleMatch.matches[i],
                  selected: i == selectedIndex,
                  onTap: () => onSelectIndex(i),
                ),
            ],
          ),
        ],
      ],
    );
  }

  AppBadgeVariant _matchLevelVariant(String level) {
    switch (level.toLowerCase()) {
      case 'strong':
      case 'high':
        return AppBadgeVariant.success;
      case 'moderate':
      case 'medium':
        return AppBadgeVariant.info;
      case 'low':
      case 'weak':
        return AppBadgeVariant.warning;
      default:
        return AppBadgeVariant.neutral;
    }
  }
}

class _PriorityCallout extends StatelessWidget {
  const _PriorityCallout({required this.skills});

  final List<String> skills;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.flag_outlined, size: 16, color: AppColors.amber),
              SizedBox(width: 6),
              Text('Ưu tiên tiếp theo', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.amber)),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: skills.take(5).map((s) => AppBadge(label: s, variant: AppBadgeVariant.warning)).toList(),
          ),
        ],
      ),
    );
  }
}

class RoleMatchSkillSection extends StatelessWidget {
  const RoleMatchSkillSection({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.skills,
    required this.variant,
  });

  final IconData icon;
  final Color color;
  final String title;
  final List<String> skills;
  final AppBadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: skills.map((s) => AppBadge(label: s, variant: variant)).toList(),
        ),
      ],
    );
  }
}

class OtherRoleChip extends StatelessWidget {
  const OtherRoleChip({
    super.key,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final RoleMatchItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.12) : context.appBubbleAiBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppColors.primary : context.appBorderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item.role, style: context.appLabelStyle.copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(width: 6),
            Text(
              '${item.matchScore.toStringAsFixed(0)}%',
              style: context.appLabelStyle.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
