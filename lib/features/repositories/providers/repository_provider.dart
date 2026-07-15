import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/demo/demo_service.dart';
import '../../../core/network/api_utils.dart';
import '../../../core/network/dio_client.dart';
import '../data/repository_repository.dart';
import '../../../shared/models/app_models.dart';

class RepositoryState {
  const RepositoryState({
    this.repositories = const [],
    this.analyses = const [],
    this.aiFeedbacks = const {},
    this.roleMatchByRepoId = const {},
    this.roleMatchErrors = const {},
    this.packagesByRepoId = const {},
    this.commitsByRepoId = const {},
    this.selected,
    this.isLoading = false,
    this.isSyncing = false,
    this.loadingDetailFor,
    this.loadingAnalysisFor,
    this.analyzingRepoId,
    this.generatingFeedbackRepoId,
    this.loadingPackagesFor,
    this.loadingCommitsFor,
    this.loadingRoleMatchFor,
    this.isLoadingMyFeedbacks = false,
    this.error,
  });

  final List<RepositoryModel> repositories;
  final List<AnalysisModel> analyses;
  final Map<String, AiFeedbackModel> aiFeedbacks;
  final Map<String, RoleMatchModel> roleMatchByRepoId;
  final Map<String, String> roleMatchErrors;
  final Map<String, List<dynamic>> packagesByRepoId;
  final Map<String, List<dynamic>> commitsByRepoId;
  final RepositoryModel? selected;
  final bool isLoading;
  final bool isSyncing;
  final String? loadingDetailFor;
  final String? loadingAnalysisFor;
  final String? analyzingRepoId;
  final String? generatingFeedbackRepoId;
  final String? loadingPackagesFor;
  final String? loadingCommitsFor;
  final String? loadingRoleMatchFor;
  final bool isLoadingMyFeedbacks;
  final String? error;

  bool isAnalyzingRepo(String id) => analyzingRepoId == id;

  bool isGeneratingFeedback(String id) => generatingFeedbackRepoId == id;

  bool isLoadingRoleMatch(String id) => loadingRoleMatchFor == id;

  bool get isAnalyzing => analyzingRepoId != null;

  AiFeedbackModel? feedbackFor(String repoId) => aiFeedbacks[repoId];

  RoleMatchModel? roleMatchFor(String repoId) => roleMatchByRepoId[repoId];

  List<dynamic> packagesFor(String repoId) =>
      packagesByRepoId[repoId] ?? const [];

  List<dynamic> commitsFor(String repoId) =>
      commitsByRepoId[repoId] ?? const [];

  List<AiFeedbackModel> get myFeedbacks {
    final items = aiFeedbacks.values.toList();
    items.sort((a, b) {
      final ad = DateTime.tryParse(a.generatedAt ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bd = DateTime.tryParse(b.generatedAt ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });
    return items;
  }

  RepositoryState copyWith({
    List<RepositoryModel>? repositories,
    List<AnalysisModel>? analyses,
    Map<String, AiFeedbackModel>? aiFeedbacks,
    Map<String, RoleMatchModel>? roleMatchByRepoId,
    Map<String, String>? roleMatchErrors,
    Map<String, List<dynamic>>? packagesByRepoId,
    Map<String, List<dynamic>>? commitsByRepoId,
    RepositoryModel? selected,
    bool? isLoading,
    bool? isSyncing,
    String? loadingDetailFor,
    bool clearLoadingDetailFor = false,
    String? loadingAnalysisFor,
    bool clearLoadingAnalysisFor = false,
    String? analyzingRepoId,
    bool clearAnalyzingRepoId = false,
    String? generatingFeedbackRepoId,
    bool clearGeneratingFeedbackRepoId = false,
    String? loadingPackagesFor,
    bool clearLoadingPackagesFor = false,
    String? loadingCommitsFor,
    bool clearLoadingCommitsFor = false,
    String? loadingRoleMatchFor,
    bool clearLoadingRoleMatchFor = false,
    bool? isLoadingMyFeedbacks,
    String? error,
    bool clearError = false,
  }) {
    return RepositoryState(
      repositories: repositories ?? this.repositories,
      analyses: analyses ?? this.analyses,
      aiFeedbacks: aiFeedbacks ?? this.aiFeedbacks,
      roleMatchByRepoId: roleMatchByRepoId ?? this.roleMatchByRepoId,
      roleMatchErrors: roleMatchErrors ?? this.roleMatchErrors,
      packagesByRepoId: packagesByRepoId ?? this.packagesByRepoId,
      commitsByRepoId: commitsByRepoId ?? this.commitsByRepoId,
      selected: selected ?? this.selected,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      loadingDetailFor: clearLoadingDetailFor
          ? null
          : (loadingDetailFor ?? this.loadingDetailFor),
      loadingAnalysisFor: clearLoadingAnalysisFor
          ? null
          : (loadingAnalysisFor ?? this.loadingAnalysisFor),
      analyzingRepoId: clearAnalyzingRepoId
          ? null
          : (analyzingRepoId ?? this.analyzingRepoId),
      generatingFeedbackRepoId: clearGeneratingFeedbackRepoId
          ? null
          : (generatingFeedbackRepoId ?? this.generatingFeedbackRepoId),
      loadingPackagesFor: clearLoadingPackagesFor
          ? null
          : (loadingPackagesFor ?? this.loadingPackagesFor),
      loadingCommitsFor: clearLoadingCommitsFor
          ? null
          : (loadingCommitsFor ?? this.loadingCommitsFor),
      loadingRoleMatchFor: clearLoadingRoleMatchFor
          ? null
          : (loadingRoleMatchFor ?? this.loadingRoleMatchFor),
      isLoadingMyFeedbacks: isLoadingMyFeedbacks ?? this.isLoadingMyFeedbacks,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class RepositoryNotifier extends Notifier<RepositoryState> {
  late RepositoryRepository _repository;
  Future<void>? _reposInFlight;
  Future<void>? _analysesInFlight;
  Future<void>? _overviewInFlight;

  @override
  RepositoryState build() {
    _repository = ref.read(repositoryRepositoryProvider);
    return const RepositoryState();
  }

  /// Tải repos + analyses song song — gom request trùng.
  Future<void> refreshOverview({bool syncRepos = false}) async {
    if (_overviewInFlight != null) return _overviewInFlight!;
    _overviewInFlight = Future.wait([
      fetchRepositories(sync: syncRepos),
      fetchMyAnalyses(),
    ]);
    try {
      await _overviewInFlight;
    } finally {
      _overviewInFlight = null;
    }
  }

  Future<void> fetchRepositories({bool sync = false}) async {
    if (sync) {
      if (state.isSyncing) return;
    } else if (_reposInFlight != null) {
      return _reposInFlight!;
    }

    final showListLoading = state.repositories.isEmpty;
    state = state.copyWith(
      isSyncing: sync,
      isLoading: showListLoading,
      clearError: true,
    );

    final task =
        _fetchRepositoriesTask(sync: sync, showListLoading: showListLoading);
    if (!sync) _reposInFlight = task;
    try {
      await task;
    } finally {
      if (!sync) _reposInFlight = null;
    }
  }

  Future<void> _fetchRepositoriesTask(
      {required bool sync, required bool showListLoading}) async {
    try {
      final repos = AppConfig.demoMode
          ? await (sync
              ? DemoService.instance.syncRepositories()
              : DemoService.instance.getRepositories())
          : await safeRequest(() => sync
              ? _repository.syncRepositories()
              : _repository.getCachedRepositories());
      state = state.copyWith(
        repositories: repos,
        isLoading: false,
        isSyncing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isSyncing: false,
        error: getApiErrorMessage(e),
      );
    }
  }

  Future<void> fetchMyAnalyses() async {
    if (_analysesInFlight != null) return _analysesInFlight!;
    _analysesInFlight = _fetchMyAnalysesTask();
    try {
      await _analysesInFlight;
    } finally {
      _analysesInFlight = null;
    }
  }

  Future<void> _fetchMyAnalysesTask() async {
    try {
      final analyses = AppConfig.demoMode
          ? await DemoService.instance.getMyAnalyses()
          : await safeRequest(_repository.getMyAnalyses);
      state = state.copyWith(analyses: analyses, clearError: true);
    } catch (e) {
      state = state.copyWith(error: getApiErrorMessage(e));
    }
  }

  Future<RepositoryModel?> fetchRepository(String id) async {
    if (state.loadingDetailFor == id) return state.selected;
    state = state.copyWith(loadingDetailFor: id, clearError: true);
    try {
      final repo = AppConfig.demoMode
          ? await DemoService.instance.getRepository(id)
          : await safeRequest(() => _repository.getRepository(id));
      state = state.copyWith(selected: repo, clearLoadingDetailFor: true);
      return repo;
    } catch (e) {
      state = state.copyWith(
          clearLoadingDetailFor: true, error: getApiErrorMessage(e));
      return null;
    }
  }

  Future<AnalysisModel> analyzeRepository(String id) async {
    state = state.copyWith(analyzingRepoId: id, clearError: true);
    try {
      final result = AppConfig.demoMode
          ? await DemoService.instance.analyzeRepository(id)
          : await safeRequest(() => _repository.analyzeRepository(id));
      state = state.copyWith(
        clearAnalyzingRepoId: true,
        analyses: [
          result,
          ...state.analyses.where((a) => a.repositoryId != id)
        ],
        repositories: state.repositories
            .map((r) => r.id == id
                ? RepositoryModel(
                    id: r.id,
                    name: r.name,
                    fullName: r.fullName,
                    description: r.description,
                    language: r.language,
                    stars: r.stars,
                    forks: r.forks,
                    updatedAt: r.updatedAt,
                    hasReadme: r.hasReadme,
                    analyzed: true,
                    analysisId: result.id,
                    url: r.url,
                    private: r.private,
                  )
                : r)
            .toList(),
      );
      return result;
    } catch (e) {
      state = state.copyWith(
          clearAnalyzingRepoId: true, error: getApiErrorMessage(e));
      rethrow;
    }
  }

  Future<RoleMatchModel?> fetchRoleMatches(String repoId,
          {bool forceRefresh = false}) =>
      calculateRoleMatches(
        sourceMode: 'single_repo',
        repoId: repoId,
        forceRefresh: forceRefresh,
      );

  Future<RoleMatchModel?> calculateRoleMatches({
    required String sourceMode,
    String? repoId,
    List<String>? repoIds,
    int limit = 3,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _roleMatchCacheKey(sourceMode, repoId, repoIds);
    if (!forceRefresh && state.roleMatchByRepoId.containsKey(cacheKey)) {
      return state.roleMatchByRepoId[cacheKey];
    }
    if (!forceRefresh && state.loadingRoleMatchFor == cacheKey) {
      return state.roleMatchByRepoId[cacheKey];
    }

    state = state.copyWith(loadingRoleMatchFor: cacheKey);
    final clearedErrors = Map<String, String>.from(state.roleMatchErrors)
      ..remove(cacheKey);
    state = state.copyWith(roleMatchErrors: clearedErrors);
    try {
      if (AppConfig.demoMode) {
        await Future<void>.delayed(const Duration(milliseconds: 600));
        state = state.copyWith(clearLoadingRoleMatchFor: true);
        return null;
      }

      RoleMatchModel? result;
      try {
        result = await safeRequest(
          () => _repository.calculateRoleMatches(
            sourceMode: sourceMode,
            repoId: repoId,
            repoIds: repoIds,
            limit: limit,
          ),
        );
      } catch (_) {
        if (sourceMode == 'single_repo' && repoId != null) {
          result = await safeRequest(
            () => _repository.getRoleMatches(repoId,
                limit: limit, includeDetails: true),
          );
        } else {
          rethrow;
        }
      }

      if (result == null) {
        state = state.copyWith(clearLoadingRoleMatchFor: true);
        return null;
      }

      state = state.copyWith(
        clearLoadingRoleMatchFor: true,
        roleMatchByRepoId: {...state.roleMatchByRepoId, cacheKey: result},
        roleMatchErrors: Map<String, String>.from(state.roleMatchErrors)
          ..remove(cacheKey),
      );
      return result;
    } catch (e) {
      final message = getApiErrorMessage(e);
      state = state.copyWith(
        clearLoadingRoleMatchFor: true,
        roleMatchErrors: {...state.roleMatchErrors, cacheKey: message},
      );
      return null;
    }
  }

  String? roleMatchErrorForKey(String key) => state.roleMatchErrors[key];

  String _roleMatchCacheKey(
      String sourceMode, String? repoId, List<String>? repoIds) {
    if (sourceMode == 'single_repo' && repoId != null && repoId.isNotEmpty) {
      return repoId;
    }
    if (sourceMode == 'all_analyzed_repos') return '__all_analyzed__';
    if (repoIds != null && repoIds.isNotEmpty) {
      return '__selected__${repoIds.join('_')}';
    }
    return sourceMode;
  }

  bool isLoadingRoleMatchKey(String key) => state.loadingRoleMatchFor == key;

  RoleMatchModel? roleMatchForKey(String key) => state.roleMatchByRepoId[key];

  static const roleMatchAllKey = '__all_analyzed__';

  Future<AnalysisModel?> fetchAnalysis(String id) async {
    if (state.loadingAnalysisFor == id) return getAnalysisById(id);
    state = state.copyWith(loadingAnalysisFor: id, clearError: true);
    try {
      var cached = getAnalysisById(id);
      if (cached == null) {
        await fetchMyAnalyses();
        cached = getAnalysisById(id);
      }
      final detailId = cached?.id.isNotEmpty == true ? cached!.id : id;
      var result = AppConfig.demoMode
          ? await DemoService.instance.getAnalysis(detailId)
          : await safeRequest(() => _repository.getAnalysis(detailId));
      if (result == null) {
        state = state.copyWith(clearLoadingAnalysisFor: true);
        return null;
      }
      var enrichedResult = result;

      if (!enrichedResult.hasCompleteNarrative && !AppConfig.demoMode) {
        RepoAnalysisSnapshotModel? snapshot;
        final snapshotId = enrichedResult.snapshotId ?? cached?.snapshotId;
        if (snapshotId?.isNotEmpty == true) {
          try {
            snapshot = await safeRequest(
              () => _repository.getSnapshot(snapshotId!),
            );
          } catch (_) {}
        }
        if (snapshot == null) {
          final repositoryId = enrichedResult.repositoryId.isNotEmpty
              ? enrichedResult.repositoryId
              : cached?.repositoryId ?? id;
          if (repositoryId.isNotEmpty) {
            try {
              final snapshots = await safeRequest(
                () => _repository.getSnapshots(repositoryId),
              );
              snapshot =
                  snapshots.where((item) => item.id == snapshotId).firstOrNull;
              final withNarrative = snapshots.where((item) {
                return item.strengths.isNotEmpty ||
                    item.weaknesses.isNotEmpty ||
                    item.recommendations.isNotEmpty;
              }).toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
              snapshot ??= withNarrative.firstOrNull;
            } catch (_) {}
          }
        }
        if (snapshot != null) {
          enrichedResult = enrichedResult.withNarrative(
            strengths: enrichedResult.strengths.isNotEmpty
                ? enrichedResult.strengths
                : snapshot.strengths,
            weaknesses: enrichedResult.weaknesses.isNotEmpty
                ? enrichedResult.weaknesses
                : snapshot.weaknesses,
            recommendations: enrichedResult.recommendations.isNotEmpty
                ? enrichedResult.recommendations
                : snapshot.recommendations,
          );
        }
      }
      state = state.copyWith(
        clearLoadingAnalysisFor: true,
        analyses: [
          enrichedResult,
          ...state.analyses.where(
            (analysis) =>
                analysis.repositoryId != enrichedResult.repositoryId &&
                analysis.id != enrichedResult.id,
          ),
        ],
      );
      return enrichedResult;
    } catch (e) {
      state = state.copyWith(
        clearLoadingAnalysisFor: true,
        error: getApiErrorMessage(e),
      );
      return null;
    }
  }

  AnalysisModel? getAnalysisById(String id) {
    for (final a in state.analyses) {
      if (a.id == id || a.repositoryId == id) return a;
    }
    return null;
  }

  Future<AiFeedbackModel?> fetchAiFeedback(String repoId,
      {String? roadmapId}) async {
    try {
      if (AppConfig.demoMode) return null;
      final feedback = await safeRequest(
          () => _repository.getAiFeedback(repoId, roadmapId: roadmapId));
      if (feedback == null) return null;
      state =
          state.copyWith(aiFeedbacks: {...state.aiFeedbacks, repoId: feedback});
      return feedback;
    } catch (_) {
      return null;
    }
  }

  Future<void> fetchMyAiFeedbacks() async {
    state = state.copyWith(isLoadingMyFeedbacks: true, clearError: true);
    try {
      final List<AiFeedbackModel> feedbacks;
      if (AppConfig.demoMode) {
        await fetchRepositories();
        feedbacks = state.repositories.take(2).map((repo) {
          return AiFeedbackModel(
            id: 'demo-feedback-${repo.id}',
            repositoryId: repo.id,
            repositoryName: repo.fullName,
            summary:
                'Repository ${repo.name} có cấu trúc ổn nhưng cần bổ sung test và CI.',
            strengthFeedback: const [
              'Cấu trúc project rõ ràng',
              'README đầy đủ'
            ],
            weaknessFeedback: const ['Thiếu unit test', 'Chưa có pipeline CI'],
            learningAdvice:
                'Ưu tiên viết test cho module core và thiết lập GitHub Actions.',
            nextSteps: const [
              'Thêm Jest/pytest',
              'Cấu hình CI',
              'Bổ sung badge README'
            ],
            recommendedTopics: const ['Testing', 'DevOps'],
            careerSuggestion: 'Full-Stack Developer',
            generatedAt: DateTime.now()
                .subtract(const Duration(days: 2))
                .toIso8601String(),
          );
        }).toList();
      } else {
        feedbacks = await safeRequest(_repository.getMyAiFeedback);
      }

      final merged = <String, AiFeedbackModel>{...state.aiFeedbacks};
      for (final feedback in feedbacks) {
        final repoId = feedback.repositoryId.isNotEmpty
            ? feedback.repositoryId
            : feedback.id;
        if (repoId.isEmpty) continue;
        merged[repoId] = feedback.copyWithRepositoryId(repoId);
      }
      state = state.copyWith(isLoadingMyFeedbacks: false, aiFeedbacks: merged);
    } catch (e) {
      state = state.copyWith(
          isLoadingMyFeedbacks: false, error: getApiErrorMessage(e));
    }
  }

  Future<AiFeedbackModel> generateAiFeedback(
    String repoId, {
    String? roadmapId,
    String? analysisId,
    String? snapshotId,
  }) async {
    state = state.copyWith(generatingFeedbackRepoId: repoId, clearError: true);
    try {
      final feedback = AppConfig.demoMode
          ? AiFeedbackModel(
              id: 'demo-feedback',
              repositoryId: repoId,
              repositoryName: 'Demo Repository',
              summary: 'Demo AI feedback',
              strengthFeedback: const ['Clean structure'],
              weaknessFeedback: const ['Needs tests'],
              learningAdvice: 'Add unit tests and CI.',
              nextSteps: const ['Write tests', 'Add README'],
              recommendedTopics: const ['Testing'],
              careerSuggestion: 'Backend Developer',
            )
          : await safeRequest(
              () => _repository.generateAiFeedback(
                repoId,
                roadmapId: roadmapId,
                analysisId: analysisId,
                snapshotId: snapshotId,
              ),
            );
      state = state.copyWith(
        clearGeneratingFeedbackRepoId: true,
        aiFeedbacks: {...state.aiFeedbacks, repoId: feedback},
      );
      return feedback;
    } catch (e) {
      state = state.copyWith(
          clearGeneratingFeedbackRepoId: true, error: getApiErrorMessage(e));
      rethrow;
    }
  }

  Future<void> fetchPackages(String id, {bool sync = false}) async {
    state = state.copyWith(loadingPackagesFor: id, clearError: true);
    try {
      final items = AppConfig.demoMode
          ? const [
              {
                'fileName': 'package.json',
                'content': '{"name":"demo-app","dependencies":{"express":"^4"}}'
              },
            ]
          : await safeRequest(() => sync
              ? _repository.syncPackages(id)
              : _repository.getCachedPackages(id));
      state = state.copyWith(
        clearLoadingPackagesFor: true,
        packagesByRepoId: {...state.packagesByRepoId, id: items},
      );
    } catch (e) {
      state = state.copyWith(
          clearLoadingPackagesFor: true, error: getApiErrorMessage(e));
    }
  }

  Future<void> fetchCommits(String id, {bool sync = false}) async {
    state = state.copyWith(loadingCommitsFor: id, clearError: true);
    try {
      final items = AppConfig.demoMode
          ? const [
              {
                'message': 'feat: initial commit',
                'author': 'demo',
                'date': '2026-01-01'
              },
            ]
          : await safeRequest(() => sync
              ? _repository.syncCommits(id)
              : _repository.getCachedCommits(id));
      state = state.copyWith(
        clearLoadingCommitsFor: true,
        commitsByRepoId: {...state.commitsByRepoId, id: items},
      );
    } catch (e) {
      state = state.copyWith(
          clearLoadingCommitsFor: true, error: getApiErrorMessage(e));
    }
  }
}

final repositoryProvider =
    NotifierProvider<RepositoryNotifier, RepositoryState>(
        RepositoryNotifier.new);
