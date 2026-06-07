import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../roadmaps/data/roadmap_mock_data.dart';
import '../../../shared/widgets/app_widgets.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roadmap = ref.watch(roadmapProvider);
    final stats = roadmap.learningStats ?? mockLearningStats;
    final skills = roadmap.skillProgress.isNotEmpty ? roadmap.skillProgress : mockSkillProgress;
    final compact = isCompactPhone(context);

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
          children: const [
            StatCard(
              label: 'Tăng trưởng',
              value: '+27%',
              icon: Icons.trending_up,
              iconColor: AppColors.emerald,
              iconBg: Color(0xFFD1FAE5),
              subtitle: 'So với tháng trước',
            ),
            StatCard(
              label: 'Mục tiêu',
              value: '12/15',
              icon: Icons.flag,
              iconColor: AppColors.primary,
              iconBg: Color(0xFFE0E7FF),
              subtitle: 'Tỷ lệ 80%',
            ),
            StatCard(
              label: 'Kỹ năng cải thiện',
              value: '8',
              icon: Icons.emoji_events,
              iconColor: AppColors.purple,
              iconBg: Color(0xFFEDE9FE),
              subtitle: 'Trong quý này',
            ),
            StatCard(
              label: 'Giờ học',
              value: '124',
              icon: Icons.menu_book,
              iconColor: AppColors.cyan,
              iconBg: Color(0xFFCFFAFE),
              subtitle: '30 ngày gần nhất',
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tổng quan học tập', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _row('Level', '${stats.level}'),
              _row('XP', '${stats.totalXp}'),
              _row('Chuỗi ngày', '${stats.currentStreak}'),
              _row('Node hoàn thành', '${stats.completedNodes}/${stats.totalNodes}'),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: stats.weeklyHoursCompleted / stats.weeklyGoalHours,
                color: AppColors.primary,
              ),
              Text('Mục tiêu tuần: ${stats.weeklyHoursCompleted}/${stats.weeklyGoalHours} giờ'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Radar kỹ năng', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ...skills.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [Text(s.skill), Text('${s.current}/${s.target}')],
                      ),
                      LinearProgressIndicator(value: s.current / s.target, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(k), Text(v, style: const TextStyle(fontWeight: FontWeight.w600))],
        ),
      );
}
