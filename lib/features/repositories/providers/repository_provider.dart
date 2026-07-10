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
    this.packagesByRepoId = const {},
    this.commitsByRepoId = const {},
    this.selected,
    this.isLoading = false,
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
  final Map<String, List<dynamic>> packagesByRepoId;
  final Map<String, List<dynamic>> commitsByRepoId;
  final RepositoryModel? selected;
  final bool isLoading;
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

  List<dynamic> packagesFor(String repoId) => packagesByRepoId[repoId] ?? const [];

  List<dynamic> commitsFor(String repoId) => commitsByRepoId[repoId] ?? const [];

  List<AiFeedbackModel> get myFeedbacks {
    final items = aiFeedbacks.values.toList();
    items.sort((a, b) {
      final ad = DateTime.tryParse(a.generatedAt ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = DateTime.tryParse(b.generatedAt ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });
    return items;
  }

  RepositoryState copyWith({
    List<RepositoryModel>? repositories,
    List<AnalysisModel>? analyses,
    Map<String, AiFeedbackModel>? aiFeedbacks,
    Map<String, RoleMatchModel>? roleMatchByRepoId,
    Map<String, List<dynamic>>? packagesByRepoId,
    Map<String, List<dynamic>>? commitsByRepoId,
    RepositoryModel? selected,
    bool? isLoading,
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
      packagesByRepoId: packagesByRepoId ?? this.packagesByRepoId,
      commitsByRepoId: commitsByRepoId ?? this.commitsByRepoId,
      selected: selected ?? this.selected,
      isLoading: isLoading ?? this.isLoading,
      analyzingRepoId: clearAnalyzingRepoId ? null : (analyzingRepoId ?? this.analyzingRepoId),
      generatingFeedbackRepoId:
          clearGeneratingFeedbackRepoId ? null : (generatingFeedbackRepoId ?? this.generatingFeedbackRepoId),
      loadingPackagesFor: clearLoadingPackagesFor ? null : (loadingPackagesFor ?? this.loadingPackagesFor),
      loadingCommitsFor: clearLoadingCommitsFor ? null : (loadingCommitsFor ?? this.loadingCommitsFor),
      loadingRoleMatchFor: clearLoadingRoleMatchFor ? null : (loadingRoleMatchFor ?? this.loadingRoleMatchFor),
      isLoadingMyFeedbacks: isLoadingMyFeedbacks ?? this.isLoadingMyFeedbacks,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class RepositoryNotifier extends Notifier<RepositoryState> {
  late RepositoryRepository _repository;

  @override
  RepositoryState build() {
    _repository = ref.read(repositoryRepositoryProvider);
    return const RepositoryState();
  }

  Future<void> fetchRepositories({bool sync = false}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repos = AppConfig.demoMode
          ? await (sync ? DemoService.instance.syncRepositories() : DemoService.instance.getRepositories())
          : await safeRequest(() => sync ? _repository.syncRepositories() : _repository.getCachedRepositories());
      state = state.copyWith(repositories: repos, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getApiErrorMessage(e));
    }
  }

  Future<void> fetchMyAnalyses() async {
    try {
      final analyses = AppConfig.demoMode
          ? await DemoService.instance.getMyAnalyses()
          : await safeRequest(_repository.getMyAnalyses);
      state = state.copyWith(analyses: analyses);
    } catch (_) {
      state = state.copyWith(analyses: []);
    }
  }

  Future<RepositoryModel?> fetchRepository(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = AppConfig.demoMode
          ? await DemoService.instance.getRepository(id)
          : await safeRequest(() => _repository.getRepository(id));
      state = state.copyWith(selected: repo, isLoading: false);
      return repo;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getApiErrorMessage(e));
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
        analyses: [result, ...state.analyses.where((a) => a.repositoryId != id)],
        repositories: state.repositories
            .map((r) => r.id == id ? RepositoryModel(
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
                ) : r)
            .toList(),
      );
      return result;
    } catch (e) {
      state = state.copyWith(clearAnalyzingRepoId: true, error: getApiErrorMessage(e));
      rethrow;
    }
  }

  Future<RoleMatchModel?> fetchRoleMatches(String repoId) async {
    // avoid refetch if already cached
    if (state.roleMatchByRepoId.containsKey(repoId)) {
      return state.roleMatchByRepoId[repoId];
    }
    state = state.copyWith(loadingRoleMatchFor: repoId);
    try {
      if (AppConfig.demoMode) {
        await Future<void>.delayed(const Duration(milliseconds: 600));
        state = state.copyWith(clearLoadingRoleMatchFor: true);
        return null;
      }
      final result = await safeRequest(() => _repository.getRoleMatches(repoId, limit: 3, includeDetails: true));
      if (result == null) {
        state = state.copyWith(clearLoadingRoleMatchFor: true);
        return null;
      }
      state = state.copyWith(
        clearLoadingRoleMatchFor: true,
        roleMatchByRepoId: {...state.roleMatchByRepoId, repoId: result},
      );
      return result;
    } catch (_) {
      state = state.copyWith(clearLoadingRoleMatchFor: true);
      return null;
    }
  }

  Future<AnalysisModel?> fetchAnalysis(String id) async {
    try {
      final result = AppConfig.demoMode
          ? await DemoService.instance.getAnalysis(id)
          : await safeRequest(() => _repository.getAnalysis(id));
      if (result == null) return null;
      state = state.copyWith(
        analyses: [result, ...state.analyses.where((a) => a.repositoryId != id && a.id != result.id)],
      );
      return result;
    } catch (_) {
      return null;
    }
  }

  AnalysisModel? getAnalysisById(String id) {
    for (final a in state.analyses) {
      if (a.id == id || a.repositoryId == id) return a;
    }
    return null;
  }

  Future<AiFeedbackModel?> fetchAiFeedback(String repoId) async {
    try {
      if (AppConfig.demoMode) return null;
      final feedback = await safeRequest(() => _repository.getAiFeedback(repoId));
      if (feedback == null) return null;
      state = state.copyWith(aiFeedbacks: {...state.aiFeedbacks, repoId: feedback});
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
            summary: 'Repository ${repo.name} có cấu trúc ổn nhưng cần bổ sung test và CI.',
            strengthFeedback: const ['Cấu trúc project rõ ràng', 'README đầy đủ'],
            weaknessFeedback: const ['Thiếu unit test', 'Chưa có pipeline CI'],
            learningAdvice: 'Ưu tiên viết test cho module core và thiết lập GitHub Actions.',
            nextSteps: const ['Thêm Jest/pytest', 'Cấu hình CI', 'Bổ sung badge README'],
            recommendedTopics: const ['Testing', 'DevOps'],
            careerSuggestion: 'Full-Stack Developer',
            generatedAt: DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
          );
        }).toList();
      } else {
        feedbacks = await safeRequest(_repository.getMyAiFeedback);
      }

      final merged = <String, AiFeedbackModel>{...state.aiFeedbacks};
      for (final feedback in feedbacks) {
        final repoId = feedback.repositoryId.isNotEmpty ? feedback.repositoryId : feedback.id;
        if (repoId.isEmpty) continue;
        merged[repoId] = feedback.copyWithRepositoryId(repoId);
      }
      state = state.copyWith(isLoadingMyFeedbacks: false, aiFeedbacks: merged);
    } catch (e) {
      state = state.copyWith(isLoadingMyFeedbacks: false, error: getApiErrorMessage(e));
    }
  }

  Future<AiFeedbackModel> generateAiFeedback(String repoId) async {
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
          : await safeRequest(() => _repository.generateAiFeedback(repoId));
      state = state.copyWith(
        clearGeneratingFeedbackRepoId: true,
        aiFeedbacks: {...state.aiFeedbacks, repoId: feedback},
      );
      return feedback;
    } catch (e) {
      state = state.copyWith(clearGeneratingFeedbackRepoId: true, error: getApiErrorMessage(e));
      rethrow;
    }
  }

  Future<void> fetchPackages(String id, {bool sync = false}) async {
    state = state.copyWith(loadingPackagesFor: id, clearError: true);
    try {
      final items = AppConfig.demoMode
          ? const [
              {'fileName': 'package.json', 'content': '{"name":"demo-app","dependencies":{"express":"^4"}}'},
            ]
          : await safeRequest(() => sync ? _repository.syncPackages(id) : _repository.getCachedPackages(id));
      state = state.copyWith(
        clearLoadingPackagesFor: true,
        packagesByRepoId: {...state.packagesByRepoId, id: items},
      );
    } catch (e) {
      state = state.copyWith(clearLoadingPackagesFor: true, error: getApiErrorMessage(e));
    }
  }

  Future<void> fetchCommits(String id, {bool sync = false}) async {
    state = state.copyWith(loadingCommitsFor: id, clearError: true);
    try {
      final items = AppConfig.demoMode
          ? const [
              {'message': 'feat: initial commit', 'author': 'demo', 'date': '2026-01-01'},
            ]
          : await safeRequest(() => sync ? _repository.syncCommits(id) : _repository.getCachedCommits(id));
      state = state.copyWith(
        clearLoadingCommitsFor: true,
        commitsByRepoId: {...state.commitsByRepoId, id: items},
      );
    } catch (e) {
      state = state.copyWith(clearLoadingCommitsFor: true, error: getApiErrorMessage(e));
    }
  }
}

final repositoryProvider = NotifierProvider<RepositoryNotifier, RepositoryState>(RepositoryNotifier.new);
