import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../feature_providers.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/scroll_list_hints.dart';
import '../../../shared/widgets/skeleton_loading.dart';
import '../widgets/dashboard_widgets.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_refresh);
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(dashboardProvider.notifier).load(),
      ref.read(repositoryProvider.notifier).fetchRepositories(),
      ref.read(repositoryProvider.notifier).fetchMyAnalyses(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final dashboard = ref.watch(dashboardProvider);
    final repoState = ref.watch(repositoryProvider);
    final payload = dashboard.payload;
    final hasDashboard = payload != null;
    final isInitialLoading = dashboard.isLoading && !hasDashboard && repoState.repositories.isEmpty;

    final totalRepos = hasDashboard ? (payload['totalRepositories'] ?? 0) : repoState.repositories.length;
    final analyzed = hasDashboard ? (payload['analyzedRepositories'] ?? 0) : repoState.analyses.length;
    final githubConnected = hasDashboard
        ? payload['githubConnected'] == true
        : user?.githubConnected == true;
    final overallRaw = hasDashboard
        ? payload['overallScore']
        : (repoState.analyses.isNotEmpty ? repoState.analyses.first.scores.overall : 0);
    final overallScore = overallRaw is int ? overallRaw : int.tryParse('$overallRaw') ?? 0;
    final strongSkills = hasDashboard
        ? (payload['strongSkills'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[]
        : const <String>[];
    final missingSkills = hasDashboard
        ? (payload['missingSkills'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[]
        : const <String>[];
    final suggestedCareer = hasDashboard ? payload['suggestedCareerPath']?.toString() : null;

    if (isInitialLoading) {
      return ListView(
        padding: appScreenPadding(context),
        children: const [
          SkeletonCard(),
          SizedBox(height: 16),
          SkeletonCard(),
          SizedBox(height: 16),
          SkeletonCard(),
        ],
      );
    }

    return ScrollListHints(
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: appScreenPadding(context),
          children: [
            DashboardHeroCard(
              userName: user?.name ?? 'bạn',
              avatarUrl: user?.avatar,
              overallScore: overallScore,
              githubConnected: githubConnected,
              totalRepos: totalRepos is int ? totalRepos : int.tryParse('$totalRepos') ?? 0,
              analyzedCount: analyzed is int ? analyzed : int.tryParse('$analyzed') ?? 0,
              onTapProfile: () => context.push('/profile'),
            ),
            if (dashboard.error != null) ...[
              const SizedBox(height: 12),
              BannerMessage(message: dashboard.error!, isWarning: true),
            ],
            if (suggestedCareer != null && suggestedCareer.isNotEmpty) ...[
              const SizedBox(height: 20),
              DashboardCareerCard(careerPath: suggestedCareer),
            ],
            if (strongSkills.isNotEmpty || missingSkills.isNotEmpty) ...[
              const SizedBox(height: 20),
              DashboardSkillsCard(strongSkills: strongSkills, missingSkills: missingSkills),
            ],
            const SizedBox(height: 20),
            DashboardRecentAnalysesCard(analyses: repoState.analyses),
            const SizedBox(height: 20),
            const DashboardQuickActionsGrid(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
