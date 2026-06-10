import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../roadmaps/data/roadmap_mock_data.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/roadmap_widgets.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(roadmapProvider.notifier).loadRoadmaps());
  }

  @override
  Widget build(BuildContext context) {
    final roadmap = ref.watch(roadmapProvider);
    final stats = roadmap.learningStats ?? mockLearningStats;
    final skills = roadmap.skillProgress.isNotEmpty ? roadmap.skillProgress : mockSkillProgress;
    final compact = isCompactPhone(context);
    final growth = stats.totalNodes == 0 ? 0 : ((stats.completedNodes / stats.totalNodes) * 100).round();

    return ListView(
      padding: appScreenPadding(context),
      children: [
        const PageHeader(
          title: 'Tiến độ & Insight',
          subtitle: 'Theo dõi hành trình phát triển kỹ năng theo thời gian',
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: compact ? 1.1 : 1.25,
          children: [
            StatCard(
              label: 'Hoàn thành',
              value: '$growth%',
              icon: Icons.trending_up,
              iconColor: AppColors.emerald,
              iconBg: const Color(0xFFD1FAE5),
              subtitle: 'Tiến độ roadmap',
            ),
            StatCard(
              label: 'Mục tiêu',
              value: '${stats.completedNodes}/${stats.totalNodes}',
              icon: Icons.flag,
              iconColor: AppColors.primary,
              iconBg: const Color(0xFFE0E7FF),
              subtitle: 'Node hoàn thành',
            ),
            StatCard(
              label: 'Roadmap active',
              value: '${stats.activeRoadmapIds.length}',
              icon: Icons.emoji_events,
              iconColor: AppColors.purple,
              iconBg: const Color(0xFFEDE9FE),
              subtitle: 'Lộ trình đang học',
            ),
            StatCard(
              label: 'Giờ học tuần',
              value: '${stats.weeklyHoursCompleted}',
              icon: Icons.menu_book,
              iconColor: AppColors.cyan,
              iconBg: const Color(0xFFCFFAFE),
              subtitle: 'Mục tiêu ${stats.weeklyGoalHours}h',
            ),
          ],
        ),
        const SizedBox(height: 16),
        XPCardWidget(stats: stats),
        const SizedBox(height: 16),
        SkillRadarChartWidget(skills: skills),
        const SizedBox(height: 16),
        AppCard(
          child: SizedBox(
            height: compact ? 200 : 220,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= mockProgressChartData.length) return const SizedBox.shrink();
                        return Text(mockProgressChartData[i]['date'] as String, style: const TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < mockProgressChartData.length; i++)
                        FlSpot(i.toDouble(), (mockProgressChartData[i]['overall'] as int).toDouble()),
                    ],
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
