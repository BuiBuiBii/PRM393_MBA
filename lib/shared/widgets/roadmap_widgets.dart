import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/app_models.dart';
import 'app_widgets.dart';

String previewPayload(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  try {
    return const JsonEncoder.withIndent('  ').convert(value);
  } catch (_) {
    return value.toString();
  }
}

class RoadmapTreeWidget extends StatelessWidget {
  const RoadmapTreeWidget({
    super.key,
    required this.roadmap,
    this.onStatusChange,
    this.onBookmarkToggle,
    this.isBookmarked,
    this.onOpenLearning,
    this.loadingLearningItemId,
    this.generatingLearningItemId,
  });

  final RoadmapModel roadmap;
  final void Function(String nodeId, String status)? onStatusChange;
  final void Function(String nodeId)? onBookmarkToggle;
  final bool Function(String nodeId)? isBookmarked;
  final void Function(LearningNodeModel node)? onOpenLearning;
  final String? loadingLearningItemId;
  final String? generatingLearningItemId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < roadmap.modules.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.cyan]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${i + 1}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(roadmap.modules[i].title,
                          style: context.appSectionTitleStyle),
                      if (roadmap.modules[i].description.isNotEmpty)
                        Text(roadmap.modules[i].description,
                            style: context.appCaptionStyle),
                      const SizedBox(height: 8),
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.only(left: 12),
                        decoration: BoxDecoration(
                          border: Border(
                              left: BorderSide(
                                  color: context.appBorderColor,
                                  width: 2,
                                  style: BorderStyle.solid)),
                        ),
                        child: Column(
                          children: [
                            for (final node in roadmap.modules[i].nodes)
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: context.appBorderColor),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                            child: Text(node.title,
                                                style: context
                                                    .appSectionTitleStyle
                                                    .copyWith(fontSize: 14))),
                                        AppBadge(label: node.status),
                                        if (onBookmarkToggle != null)
                                          IconButton(
                                            visualDensity:
                                                VisualDensity.compact,
                                            icon: Icon(
                                              (isBookmarked?.call(node.id) ??
                                                      node.bookmarked)
                                                  ? Icons.bookmark
                                                  : Icons.bookmark_border,
                                              size: 18,
                                            ),
                                            onPressed: () =>
                                                onBookmarkToggle!(node.id),
                                          ),
                                      ],
                                    ),
                                    if (node.description.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(node.description,
                                            style: context.appCaptionStyle),
                                      ),
                                    if (node.canonicalSkillName != null ||
                                        node.skillName != null ||
                                        node.category != null ||
                                        node.priority != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: [
                                            if (node.canonicalSkillName !=
                                                    null ||
                                                node.skillName != null)
                                              AppBadge(
                                                label:
                                                    node.canonicalSkillName ??
                                                        node.skillName!,
                                                variant:
                                                    AppBadgeVariant.success,
                                              ),
                                            if (node.category != null)
                                              AppBadge(
                                                label: node.category!,
                                                variant: AppBadgeVariant.info,
                                              ),
                                            if (node.priority != null)
                                              AppBadge(
                                                label: 'P${node.priority}',
                                                variant:
                                                    AppBadgeVariant.warning,
                                              ),
                                          ],
                                        ),
                                      ),
                                    if (onStatusChange != null &&
                                        node.status != 'completed')
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: PrimaryButton(
                                          label: 'Hoàn thành',
                                          outlined: true,
                                          onPressed: () => onStatusChange!(
                                              node.id, 'completed'),
                                        ),
                                      ),
                                    if (onOpenLearning != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: PrimaryButton(
                                          label: generatingLearningItemId ==
                                                  node.id
                                              ? 'Đang tạo nội dung học...'
                                              : 'Mở bài học',
                                          outlined: true,
                                          loading: loadingLearningItemId ==
                                                  node.id ||
                                              generatingLearningItemId ==
                                                  node.id,
                                          onPressed: node.id.isEmpty ||
                                                  loadingLearningItemId ==
                                                      node.id ||
                                                  generatingLearningItemId ==
                                                      node.id
                                              ? null
                                              : () => onOpenLearning!(node),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class LearningContentSheet extends StatelessWidget {
  const LearningContentSheet({super.key, required this.learning});

  final LearningContentModel learning;

  @override
  Widget build(BuildContext context) {
    final sections = <(String, List<String>)>[
      ('Ứng dụng', learning.useCases),
      ('Cách áp dụng', learning.howToApply),
      ('Ví dụ', learning.examples),
      ('Checklist', learning.checklist),
      ('Bài tập', learning.exercises),
      ('Lỗi thường gặp', learning.commonMistakes),
      ('Kỹ năng tiếp theo', learning.nextSkills),
    ];
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(learning.title, style: context.appHeadingStyle),
          if (learning.overview.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(learning.overview, style: context.appBodyStyle),
          ],
          if (learning.whyLearn.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Vì sao nên học', style: context.appSectionTitleStyle),
            const SizedBox(height: 6),
            Text(learning.whyLearn, style: context.appBodyStyle),
          ],
          for (final section in sections)
            if (section.$2.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(section.$1, style: context.appSectionTitleStyle),
              const SizedBox(height: 6),
              ...section.$2.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('• $item', style: context.appBodyStyle),
                  )),
            ],
          const SizedBox(height: 16),
          Text('Video và tài nguyên', style: context.appSectionTitleStyle),
          const SizedBox(height: 8),
          if (learning.resources.isEmpty)
            Text(
              'Chưa có video/tài nguyên phù hợp cho kỹ năng này.',
              style: context.appCaptionStyle,
            )
          else
            ...learning.resources.map(
              (resource) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                    resource.title.isEmpty ? resource.url : resource.title),
                subtitle: resource.channelTitle == null
                    ? null
                    : Text(resource.channelTitle!),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => launchUrl(
                  Uri.parse(resource.url),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class LearningTimelineWidget extends StatelessWidget {
  const LearningTimelineWidget({super.key, required this.roadmap});

  final RoadmapModel roadmap;

  @override
  Widget build(BuildContext context) {
    final milestones = <({
      String title,
      String description,
      int week,
      int xp,
      bool completed
    })>[];
    var week = 1;
    for (final module in roadmap.modules) {
      for (final node in module.nodes) {
        milestones.add((
          title: node.title,
          description: node.description,
          week: week,
          xp: node.xp,
          completed: node.status == 'completed',
        ));
        week++;
      }
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dòng thời gian học tập', style: context.appSectionTitleStyle),
          Text('Cột mốc đồng bộ với tiến độ roadmap',
              style: context.appCaptionStyle),
          const SizedBox(height: 12),
          ...milestones.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    m.completed
                        ? Icons.check_circle
                        : Icons.radio_button_checked,
                    color: m.completed ? AppColors.emerald : AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                                child: Text(m.title,
                                    style: context.appBodyStyle.copyWith(
                                        fontWeight: FontWeight.w500))),
                            AppBadge(
                                label: 'Tuần ${m.week} • ${m.xp} XP',
                                variant: AppBadgeVariant.neutral),
                          ],
                        ),
                        if (m.description.isNotEmpty)
                          Text(m.description, style: context.appCaptionStyle),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RoadmapProgressBar extends StatelessWidget {
  const RoadmapProgressBar({
    super.key,
    required this.percent,
    this.height = 20,
    this.showCaption = true,
    this.caption,
  });

  final int percent;
  final double height;
  final bool showCaption;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final clamped = percent.clamp(0, 100);
    final value = clamped / 100.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(
                    color: context.isDarkMode
                        ? AppTheme.darkBorder
                        : const Color(0xFFE2E8F0)),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value,
                  child: const ColoredBox(color: AppColors.primary),
                ),
                Center(
                  child: Text(
                    '$clamped%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color:
                          clamped >= 45 ? Colors.white : context.appTextPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showCaption && caption != null) ...[
          const SizedBox(height: 4),
          Text(caption!, style: context.appCaptionStyle),
        ],
      ],
    );
  }
}

class XPCardWidget extends StatelessWidget {
  const XPCardWidget({super.key, required this.stats});

  final LearningStatsModel stats;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('XP & Level', style: context.appSectionTitleStyle),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _metric(context, 'Level', '${stats.level}')),
              Expanded(child: _metric(context, 'XP', '${stats.totalXp}')),
              Expanded(
                  child: _metric(
                      context, 'Streak', '${stats.currentStreak} ngày')),
            ],
          ),
          const SizedBox(height: 12),
          RoadmapProgressBar(
            percent: stats.totalNodes == 0
                ? 0
                : ((stats.completedNodes / stats.totalNodes) * 100).round(),
            showCaption: true,
            caption:
                '${stats.completedNodes}/${stats.totalNodes} node hoàn thành',
          ),
        ],
      ),
    );
  }

  Widget _metric(BuildContext context, String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.appLabelStyle),
          Text(value, style: context.appHeadingStyle.copyWith(fontSize: 18)),
        ],
      );
}

class SkillRadarChartWidget extends StatelessWidget {
  const SkillRadarChartWidget({super.key, required this.skills});

  final List<SkillProgressModel> skills;

  @override
  Widget build(BuildContext context) {
    if (skills.isEmpty) {
      return const AppCard(child: Text('Chưa có dữ liệu kỹ năng.'));
    }

    final entries = skills.take(6).toList();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Radar kỹ năng', style: context.appSectionTitleStyle),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.polygon,
                tickCount: 4,
                ticksTextStyle: context.appLabelStyle.copyWith(fontSize: 10),
                getTitle: (index, angle) {
                  if (index >= entries.length) return RadarChartTitle(text: '');
                  final label = entries[index].skill;
                  return RadarChartTitle(
                      text: label.length > 10
                          ? '${label.substring(0, 10)}…'
                          : label);
                },
                dataSets: [
                  RadarDataSet(
                    fillColor: AppColors.primary.withValues(alpha: 0.2),
                    borderColor: AppColors.primary,
                    dataEntries: [
                      for (final skill in entries)
                        RadarEntry(
                            value: (skill.current / skill.target * 100)
                                .clamp(0, 100)
                                .toDouble()),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AiFeedbackPanel extends StatelessWidget {
  const AiFeedbackPanel({
    super.key,
    required this.feedback,
    required this.isGenerating,
    required this.onGenerate,
    required this.onRefresh,
  });

  final AiFeedbackModel? feedback;
  final bool isGenerating;
  final VoidCallback onGenerate;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child:
                      Text('AI Feedback', style: context.appSectionTitleStyle)),
              PrimaryButton(
                  label: 'Tải lại', outlined: true, onPressed: onRefresh),
              const SizedBox(width: 8),
              PrimaryButton(
                label: feedback == null ? 'Tạo feedback' : 'Tạo lại',
                loading: isGenerating,
                onPressed: isGenerating ? null : onGenerate,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (feedback == null)
            Text('Chưa có feedback. Cần phân tích repository trước.',
                style: context.appCaptionStyle)
          else ...[
            if (feedback!.isStale) ...[
              const BannerMessage(
                message:
                    'Feedback đã cũ so với analysis hoặc tiến độ roadmap. Hãy tạo lại để cập nhật.',
                isWarning: true,
              ),
              const SizedBox(height: 12),
            ],
            if (feedback!.summary.isNotEmpty)
              Text(feedback!.summary, style: context.appBodyStyle),
            if (feedback!.strengthFeedback.isNotEmpty) ...[
              const SizedBox(height: 12),
              _section(
                  'Điểm mạnh', feedback!.strengthFeedback, AppColors.emerald),
            ],
            if (feedback!.weaknessFeedback.isNotEmpty) ...[
              const SizedBox(height: 12),
              _section('Điểm yếu', feedback!.weaknessFeedback, AppColors.amber),
            ],
            if (feedback!.learningAdvice.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Gợi ý học tập',
                  style: context.appSectionTitleStyle
                      .copyWith(color: AppColors.primary)),
              Text(feedback!.learningAdvice, style: context.appCaptionStyle),
            ],
            if (feedback!.nextSteps.isNotEmpty) ...[
              const SizedBox(height: 12),
              _section(
                  'Bước tiếp theo', feedback!.nextSteps, AppColors.primary),
            ],
            if (feedback!.recommendedTopics.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: feedback!.recommendedTopics
                    .map((t) => AppBadge(label: t))
                    .toList(),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _section(String title, List<String> items, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(fontWeight: FontWeight.w600, color: color)),
          ...items.map((e) => Text('• $e')),
        ],
      );
}
