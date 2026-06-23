import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

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
  });

  final RoadmapModel roadmap;
  final void Function(String nodeId, String status)? onStatusChange;
  final void Function(String nodeId)? onBookmarkToggle;
  final bool Function(String nodeId)? isBookmarked;

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
                    gradient: const LinearGradient(colors: [AppColors.primary, AppColors.cyan]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(roadmap.modules[i].title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      if (roadmap.modules[i].description.isNotEmpty)
                        Text(roadmap.modules[i].description, style: const TextStyle(color: AppColors.slate500, fontSize: 13)),
                      const SizedBox(height: 8),
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.only(left: 12),
                        decoration: BoxDecoration(
                          border: Border(left: BorderSide(color: Colors.grey.shade300, width: 2, style: BorderStyle.solid)),
                        ),
                        child: Column(
                          children: [
                            for (final node in roadmap.modules[i].nodes)
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade200),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(child: Text(node.title, style: const TextStyle(fontWeight: FontWeight.w600))),
                                        AppBadge(label: node.status),
                                        if (onBookmarkToggle != null)
                                          IconButton(
                                            visualDensity: VisualDensity.compact,
                                            icon: Icon(
                                              (isBookmarked?.call(node.id) ?? node.bookmarked) ? Icons.bookmark : Icons.bookmark_border,
                                              size: 18,
                                            ),
                                            onPressed: () => onBookmarkToggle!(node.id),
                                          ),
                                      ],
                                    ),
                                    if (node.description.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(node.description, style: const TextStyle(fontSize: 13, color: AppColors.slate500)),
                                      ),
                                    if (node.canonicalSkillName != null || node.skillName != null || node.category != null || node.priority != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: [
                                            if (node.canonicalSkillName != null || node.skillName != null)
                                              AppBadge(
                                                label: node.canonicalSkillName ?? node.skillName!,
                                                variant: AppBadgeVariant.success,
                                              ),
                                            if (node.category != null)
                                              AppBadge(
                                                label: node.category!,
                                                variant: AppBadgeVariant.info,
                                              ),
                                            if (node.priority != null)
                                              AppBadge(
                                                label: 'P${node.priority}',
                                                variant: AppBadgeVariant.warning,
                                              ),
                                          ],
                                        ),
                                      ),
                                    if (onStatusChange != null && node.status != 'completed')
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: PrimaryButton(
                                          label: 'Hoàn thành',
                                          outlined: true,
                                          onPressed: () => onStatusChange!(node.id, 'completed'),
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

class LearningTimelineWidget extends StatelessWidget {
  const LearningTimelineWidget({super.key, required this.roadmap});

  final RoadmapModel roadmap;

  @override
  Widget build(BuildContext context) {
    final milestones = <({String title, String description, int week, int xp, bool completed})>[];
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
          const Text('Dòng thời gian học tập', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const Text('Cột mốc đồng bộ với tiến độ roadmap', style: TextStyle(color: AppColors.slate500, fontSize: 13)),
          const SizedBox(height: 12),
          ...milestones.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    m.completed ? Icons.check_circle : Icons.radio_button_checked,
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
                            Expanded(child: Text(m.title, style: const TextStyle(fontWeight: FontWeight.w500))),
                            AppBadge(label: 'Tuần ${m.week} • ${m.xp} XP', variant: AppBadgeVariant.neutral),
                          ],
                        ),
                        if (m.description.isNotEmpty)
                          Text(m.description, style: const TextStyle(color: AppColors.slate500, fontSize: 13)),
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

class XPCardWidget extends StatelessWidget {
  const XPCardWidget({super.key, required this.stats});

  final LearningStatsModel stats;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('XP & Level', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _metric('Level', '${stats.level}')),
              Expanded(child: _metric('XP', '${stats.totalXp}')),
              Expanded(child: _metric('Streak', '${stats.currentStreak} ngày')),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: stats.totalNodes == 0 ? 0 : stats.completedNodes / stats.totalNodes,
            color: AppColors.primary,
          ),
          const SizedBox(height: 6),
          Text('${stats.completedNodes}/${stats.totalNodes} node hoàn thành'),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.slate500, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
          const Text('Radar kỹ năng', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.polygon,
                tickCount: 4,
                ticksTextStyle: const TextStyle(fontSize: 10, color: AppColors.slate500),
                getTitle: (index, angle) {
                  if (index >= entries.length) return RadarChartTitle(text: '');
                  final label = entries[index].skill;
                  return RadarChartTitle(text: label.length > 10 ? '${label.substring(0, 10)}…' : label);
                },
                dataSets: [
                  RadarDataSet(
                    fillColor: AppColors.primary.withValues(alpha: 0.2),
                    borderColor: AppColors.primary,
                    dataEntries: [
                      for (final skill in entries)
                        RadarEntry(value: (skill.current / skill.target * 100).clamp(0, 100).toDouble()),
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
              const Expanded(child: Text('AI Feedback', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
              PrimaryButton(label: 'Tải lại', outlined: true, onPressed: onRefresh),
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
            const Text('Chưa có feedback. Cần phân tích repository trước.', style: TextStyle(color: AppColors.slate500))
          else ...[
            if (feedback!.summary.isNotEmpty) Text(feedback!.summary),
            if (feedback!.strengthFeedback.isNotEmpty) ...[
              const SizedBox(height: 12),
              _section('Điểm mạnh', feedback!.strengthFeedback, AppColors.emerald),
            ],
            if (feedback!.weaknessFeedback.isNotEmpty) ...[
              const SizedBox(height: 12),
              _section('Điểm yếu', feedback!.weaknessFeedback, AppColors.amber),
            ],
            if (feedback!.learningAdvice.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Gợi ý học tập', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
              Text(feedback!.learningAdvice, style: const TextStyle(color: AppColors.slate500)),
            ],
            if (feedback!.nextSteps.isNotEmpty) ...[
              const SizedBox(height: 12),
              _section('Bước tiếp theo', feedback!.nextSteps, AppColors.primary),
            ],
            if (feedback!.recommendedTopics.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: feedback!.recommendedTopics.map((t) => AppBadge(label: t)).toList(),
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
          Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
          ...items.map((e) => Text('• $e')),
        ],
      );
}
