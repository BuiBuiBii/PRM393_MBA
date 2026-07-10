import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../feature_providers.dart';
import '../../../shared/models/app_models.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../models/roadmap_generate_params.dart';
import '../utils/roadmap_generate_helper.dart';
import 'role_match_suggestion_tile.dart';

typedef OnGenerateRoadmap = Future<void> Function(RoadmapGenerateParams params);

/// Cấu hình sheet tạo roadmap — sheet tự watch provider & load role match.
class CreateRoadmapSheetConfig {
  const CreateRoadmapSheetConfig({
    this.sourceMode = 'all_analyzed_repos',
    this.repoId,
    this.repoIds,
    this.onGenerate,
  });

  final String sourceMode;
  final String? repoId;
  final List<String>? repoIds;
  final OnGenerateRoadmap? onGenerate;
}

Future<void> showCreateRoadmapSheet(
  BuildContext context, {
  required CreateRoadmapSheetConfig config,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _CreateRoadmapSheetHost(config: config),
  );
}

class _CreateRoadmapSheetHost extends ConsumerStatefulWidget {
  const _CreateRoadmapSheetHost({required this.config});

  final CreateRoadmapSheetConfig config;

  @override
  ConsumerState<_CreateRoadmapSheetHost> createState() => _CreateRoadmapSheetHostState();
}

class _CreateRoadmapSheetHostState extends ConsumerState<_CreateRoadmapSheetHost> {
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    Future.microtask(_ensureRoleMatches);
  }

  String get _cacheKey {
    final cfg = widget.config;
    if (cfg.sourceMode == 'single_repo' && cfg.repoId != null && cfg.repoId!.isNotEmpty) {
      return cfg.repoId!;
    }
    if (cfg.sourceMode == 'all_analyzed_repos') return RepositoryNotifier.roleMatchAllKey;
    if (cfg.repoIds != null && cfg.repoIds!.isNotEmpty) return '__selected__${cfg.repoIds!.join('_')}';
    return cfg.sourceMode;
  }

  Future<void> _ensureRoleMatches({bool forceRefresh = false}) async {
    final analyses = ref.read(repositoryProvider).analyses;
    if (widget.config.sourceMode == 'all_analyzed_repos' && analyses.isEmpty) return;

    await ref.read(repositoryProvider.notifier).calculateRoleMatches(
          sourceMode: widget.config.sourceMode,
          repoId: widget.config.repoId,
          repoIds: widget.config.repoIds,
          forceRefresh: forceRefresh,
        );
  }

  Future<void> _onGenerate(RoadmapGenerateParams params) async {
    final onGenerate = widget.config.onGenerate;
    if (onGenerate != null) {
      await onGenerate(params);
      return;
    }
    await generateAndOpenRoadmap(context, ref, params);
  }

  @override
  Widget build(BuildContext context) {
    final repoState = ref.watch(repositoryProvider);
    final roadmapState = ref.watch(roadmapProvider);
    final notifier = ref.read(repositoryProvider.notifier);
    final roleMatch = notifier.roleMatchForKey(_cacheKey);
    final isLoadingRoleMatch = repoState.isLoadingRoleMatch(_cacheKey);
    final roleMatchError = isLoadingRoleMatch ? null : notifier.roleMatchErrorForKey(_cacheKey);
    final matches = roleMatch?.matches ?? const <RoleMatchItem>[];
    final visibleMatches = matches.take(3).toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.paddingOf(context).bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Tạo roadmap mới', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              'Chọn vai trò từ kết quả Dev2Vec (tối đa 3 gợi ý).',
              style: context.appCaptionStyle,
            ),
            const SizedBox(height: 16),
            if (isLoadingRoleMatch)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (roleMatchError != null) ...[
              BannerMessage(message: roleMatchError, isError: true),
              const SizedBox(height: 8),
              PrimaryButton(
                label: 'Thử lại',
                icon: Icons.refresh,
                outlined: true,
                onPressed: () => _ensureRoleMatches(forceRefresh: true),
              ),
            ] else if (visibleMatches.isEmpty)
              _EmptyRoleMatchState(
                onGoRepositories: () {
                  Navigator.pop(context);
                  context.go('/repositories');
                },
              )
            else ...[
              const Text(
                'Gợi ý từ Role Match',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < visibleMatches.length; i++) ...[
                _RoleMatchTileWrapper(
                  match: visibleMatches[i],
                  index: i,
                  selected: _selectedIndex == i,
                  loading: roadmapState.isGenerating && _selectedIndex == i,
                  onTap: roadmapState.isGenerating
                      ? null
                      : () async {
                          setState(() => _selectedIndex = i);
                          final match = visibleMatches[i];
                          final roleId = match.roleId.trim().isNotEmpty ? match.roleId.trim() : match.role.trim();
                          await _onGenerate(
                            RoadmapGenerateParams(
                              roleId: roleId,
                              targetRole: match.role,
                              sourceMode: widget.config.sourceMode,
                              repoId: widget.config.repoId,
                              repoIds: widget.config.repoIds,
                            ),
                          );
                          if (context.mounted) Navigator.pop(context);
                        },
                ),
                const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _RoleMatchTileWrapper extends StatelessWidget {
  const _RoleMatchTileWrapper({
    required this.match,
    required this.index,
    required this.selected,
    required this.loading,
    required this.onTap,
  });

  final RoleMatchItem match;
  final int index;
  final bool selected;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return RoleMatchSuggestionTile(
      badge: index == 0 ? 'Role phù hợp nhất' : 'Role phù hợp',
      title: match.role,
      subtitle: match.description,
      matchScore: match.matchScore,
      matchLevelLabel: match.matchLevelLabel,
      matchedSkills: match.matchedSkills,
      missingSkills: match.missingSkills,
      loading: loading,
      selected: selected,
      onTap: onTap,
    );
  }
}

class _EmptyRoleMatchState extends StatelessWidget {
  const _EmptyRoleMatchState({required this.onGoRepositories});

  final VoidCallback onGoRepositories;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          const Icon(Icons.analytics_outlined, size: 40, color: AppColors.primary),
          const SizedBox(height: 12),
          const Text(
            'Chưa có gợi ý role',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy phân tích ít nhất một repository trước khi tạo roadmap Dev2Vec.',
            textAlign: TextAlign.center,
            style: context.appCaptionStyle,
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Đến Repositories',
            icon: Icons.folder_outlined,
            expand: true,
            onPressed: onGoRepositories,
          ),
        ],
      ),
    );
  }
}
