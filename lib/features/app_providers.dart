import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/demo/demo_service.dart';
import '../core/storage/roadmap_progress_storage.dart';
import '../core/network/api_utils.dart';
import '../core/network/app_api.dart';
import '../core/network/dio_client.dart';
import 'auth/providers/auth_provider.dart';
import '../shared/models/app_models.dart';
import '../core/network/normalizers.dart';
import 'roadmaps/data/roadmap_mock_data.dart';
import 'roadmaps/utils/roadmap_progress_utils.dart';

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
  late AppApi _api;

  @override
  RepositoryState build() {
    _api = ref.read(appApiProvider);
    return const RepositoryState();
  }

  Future<void> fetchRepositories({bool sync = false}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repos = AppConfig.demoMode
          ? await (sync ? DemoService.instance.syncRepositories() : DemoService.instance.getRepositories())
          : await safeRequest(() => sync ? _api.syncRepositories() : _api.getCachedRepositories());
      state = state.copyWith(repositories: repos, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getApiErrorMessage(e));
    }
  }

  Future<void> fetchMyAnalyses() async {
    try {
      final analyses = AppConfig.demoMode
          ? await DemoService.instance.getMyAnalyses()
          : await safeRequest(_api.getMyAnalyses);
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
          : await safeRequest(() => _api.getRepository(id));
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
          : await safeRequest(() => _api.analyzeRepository(id));
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
      final result = await safeRequest(() => _api.getRoleMatches(repoId, limit: 3, includeDetails: true));
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
          : await safeRequest(() => _api.getAnalysis(id));
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
      final feedback = await safeRequest(() => _api.getAiFeedback(repoId));
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
        feedbacks = await safeRequest(_api.getMyAiFeedback);
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
          : await safeRequest(() => _api.generateAiFeedback(repoId));
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
          : await safeRequest(() => sync ? _api.syncPackages(id) : _api.getCachedPackages(id));
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
          : await safeRequest(() => sync ? _api.syncCommits(id) : _api.getCachedCommits(id));
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

class ChatState {
  const ChatState({
    this.sessions = const [],
    this.current,
    this.isLoading = false,
    this.error,
  });

  final List<ChatSessionModel> sessions;
  final ChatSessionModel? current;
  final bool isLoading;
  final String? error;

  ChatState copyWith({
    List<ChatSessionModel>? sessions,
    ChatSessionModel? current,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ChatState(
      sessions: sessions ?? this.sessions,
      current: current ?? this.current,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ChatNotifier extends Notifier<ChatState> {
  late AppApi _api;

  @override
  ChatState build() {
    _api = ref.read(appApiProvider);
    return const ChatState();
  }

  Future<void> fetchSessions() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final sessions = AppConfig.demoMode
          ? await DemoService.instance.getChatSessions()
          : await safeRequest(_api.getChatSessions);

      var current = state.current;
      final synced = current != null ? sessions.where((s) => s.id == current!.id).firstOrNull ?? current : null;
      current = synced ?? (sessions.isNotEmpty ? sessions.first : null);

      if (current != null && current.id.isNotEmpty && !AppConfig.demoMode) {
        try {
          current = await safeRequest(() => _api.getChatSession(current!.id));
        } catch (_) {}
      } else if (current != null && current.id.isNotEmpty && AppConfig.demoMode) {
        try {
          current = await DemoService.instance.getChatSession(current.id);
        } catch (_) {}
      }

      state = state.copyWith(sessions: sessions, current: current, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getApiErrorMessage(e));
    }
  }

  Future<void> createSession(String title) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final sessionTitle = title.trim().isEmpty ? 'Cuộc trò chuyện mới' : title.trim();
      final session = AppConfig.demoMode
          ? await DemoService.instance.createChatSession(sessionTitle)
          : await safeRequest(() => _api.createChatSession(sessionTitle));
      if (session.id.isEmpty) {
        throw ApiException('Backend không trả session id');
      }
      state = state.copyWith(
        sessions: [session, ...state.sessions.where((s) => s.id != session.id)],
        current: session,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getApiErrorMessage(e));
      rethrow;
    }
  }

  Future<void> selectSession(String id) async {
    final cached = state.sessions.where((s) => s.id == id).firstOrNull;
    if (cached != null) state = state.copyWith(current: cached, clearError: true);
    try {
      final session = AppConfig.demoMode
          ? await DemoService.instance.getChatSession(id)
          : await safeRequest(() => _api.getChatSession(id));
      state = state.copyWith(
        current: session,
        sessions: state.sessions.map((s) => s.id == id ? session : s).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: getApiErrorMessage(e));
    }
  }

  Future<void> sendMessage(String content) async {
    var session = state.current;
    if (session == null) {
      await createSession('Tư vấn GitHub của tôi');
      session = state.current;
    }
    if (session == null || session.id.isEmpty) {
      state = state.copyWith(error: 'Chat session không có id. Hãy tạo session mới.');
      return;
    }

    final optimistic = ChatMessageModel(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      content: content,
      timestamp: DateTime.now().toIso8601String(),
    );
    final updated = session.copyWith(messages: [...session.messages, optimistic]);
    state = state.copyWith(current: updated, isLoading: true, clearError: true);

    try {
      ChatSessionModel nextSession;
      if (AppConfig.demoMode) {
        nextSession = await DemoService.instance.sendChatMessage(session.id, content);
      } else {
        final payload = await safeRequest(() => _api.sendChatMessage(session!.id, content));
        final record = toRecord(unwrapResponse<dynamic>(payload));
        final hasMessages = record['messages'] is List;
        final responseSession = hasMessages ? normalizeChatSessionDetail(payload) : null;
        final assistant = responseSession == null ? pickAssistantMessage(payload) : null;

        if (responseSession != null) {
          nextSession = mergeChatSession(updated, responseSession);
        } else if (assistant != null) {
          nextSession = updated.copyWith(messages: [...updated.messages, assistant]);
        } else {
          nextSession = updated;
        }

        try {
          final detail = await safeRequest(() => _api.getChatSession(session!.id));
          if (detail.messages.length >= nextSession.messages.length) {
            nextSession = detail;
          }
        } catch (_) {}
      }

      state = state.copyWith(
        current: nextSession,
        sessions: state.sessions.any((s) => s.id == session!.id)
            ? state.sessions.map((s) => s.id == session!.id ? nextSession : s).toList()
            : [nextSession, ...state.sessions],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getApiErrorMessage(e));
      rethrow;
    }
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);

class RoadmapFilters {
  const RoadmapFilters({
    this.search = '',
    this.category = 'All',
    this.difficulty = 'All',
    this.duration = 'All',
  });

  final String search;
  final String category;
  final String difficulty;
  final String duration;

  RoadmapFilters copyWith({String? search, String? category, String? difficulty, String? duration}) {
    return RoadmapFilters(
      search: search ?? this.search,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      duration: duration ?? this.duration,
    );
  }
}

class RoadmapState {
  const RoadmapState({
    this.roadmaps = const [],
    this.aiRecommendation,
    this.skillProgress = const [],
    this.learningStats,
    this.bookmarkedNodeIds = const {},
    this.filters = const RoadmapFilters(),
    this.statusFilter = 'active',
    this.isLoading = false,
    this.isGenerating = false,
    this.isArchiving = false,
    this.error,
    this.selectedTargetRole = 'Backend Developer',
  });

  final List<RoadmapModel> roadmaps;
  final AIRecommendationModel? aiRecommendation;
  final List<SkillProgressModel> skillProgress;
  final LearningStatsModel? learningStats;
  final Set<String> bookmarkedNodeIds;
  final RoadmapFilters filters;
  final String statusFilter;
  final bool isLoading;
  final bool isGenerating;
  final bool isArchiving;
  final String? error;
  final String selectedTargetRole;

  RoadmapState copyWith({
    List<RoadmapModel>? roadmaps,
    AIRecommendationModel? aiRecommendation,
    List<SkillProgressModel>? skillProgress,
    LearningStatsModel? learningStats,
    Set<String>? bookmarkedNodeIds,
    RoadmapFilters? filters,
    String? statusFilter,
    bool? isLoading,
    bool? isGenerating,
    bool? isArchiving,
    String? error,
    bool clearError = false,
    String? selectedTargetRole,
  }) {
    return RoadmapState(
      roadmaps: roadmaps ?? this.roadmaps,
      aiRecommendation: aiRecommendation ?? this.aiRecommendation,
      skillProgress: skillProgress ?? this.skillProgress,
      learningStats: learningStats ?? this.learningStats,
      bookmarkedNodeIds: bookmarkedNodeIds ?? this.bookmarkedNodeIds,
      filters: filters ?? this.filters,
      statusFilter: statusFilter ?? this.statusFilter,
      isLoading: isLoading ?? this.isLoading,
      isGenerating: isGenerating ?? this.isGenerating,
      isArchiving: isArchiving ?? this.isArchiving,
      error: clearError ? null : (error ?? this.error),
      selectedTargetRole: selectedTargetRole ?? this.selectedTargetRole,
    );
  }
}

class RoadmapNotifier extends Notifier<RoadmapState> {
  late AppApi _api;
  RoadmapProgressStorage? _progressStorage;

  Future<RoadmapProgressStorage> _storage() async {
    return _progressStorage ??= await RoadmapProgressStorage.create();
  }

  Future<String> _userScope() async {
    final user = await ref.read(tokenStorageProvider).getUser();
    return (user?['id'] ?? user?['_id'] ?? 'guest').toString();
  }

  Future<List<RoadmapModel>> _mergeLocalProgress(List<RoadmapModel> roadmaps) async {
    if (AppConfig.demoMode) return roadmaps;
    final storage = await _storage();
    final scope = await _userScope();
    final statuses = await storage.loadNodeStatuses(scope);
    final bookmarks = await storage.loadBookmarks(scope);
    return applyStoredNodeProgress(roadmaps, statuses, bookmarkIds: bookmarks);
  }

  Future<void> _persistRoadmapsState(List<RoadmapModel> roadmaps, {Set<String>? bookmarks}) async {
    final bookmarkIds = bookmarks ?? state.bookmarkedNodeIds;
    final stats = computeLearningStats(roadmaps);
    state = state.copyWith(
      roadmaps: roadmaps,
      learningStats: stats.copyWith(bookmarkedNodeIds: bookmarkIds.toList()),
      skillProgress: computeSkillProgress(roadmaps),
      bookmarkedNodeIds: bookmarkIds,
    );
  }

  @override
  RoadmapState build() {
    _api = ref.read(appApiProvider);
    if (AppConfig.demoMode) {
      return RoadmapState(
        roadmaps: mockRoadmaps,
        aiRecommendation: mockAIRecommendation,
        skillProgress: mockSkillProgress,
        learningStats: mockLearningStats,
      );
    }
    Future.microtask(loadRoadmaps);
    return const RoadmapState();
  }

  void setFilters(RoadmapFilters filters) => state = state.copyWith(filters: filters);

  void setTargetRole(String role) => state = state.copyWith(selectedTargetRole: role);

  Future<void> setStatusFilter(String status) async {
    if (status == state.statusFilter) return;
    state = state.copyWith(statusFilter: status, clearError: true);
    await loadRoadmaps(status: status);
  }

  Future<void> loadRoadmaps({String? status}) async {
    final effectiveStatus = status ?? state.statusFilter;
    state = state.copyWith(isLoading: true, clearError: true, statusFilter: effectiveStatus);
    try {
      if (AppConfig.demoMode) {
        final items = effectiveStatus == 'archived'
            ? mockRoadmaps.where((r) => r.isArchived).toList()
            : mockRoadmaps.where((r) => !r.isArchived).toList();
        state = state.copyWith(
          roadmaps: items,
          aiRecommendation: mockAIRecommendation,
          skillProgress: mockSkillProgress,
          learningStats: mockLearningStats,
          isLoading: false,
        );
        return;
      }
      final roadmaps = await _mergeLocalProgress(
        await safeRequest(() => _api.getMyRoadmaps(status: effectiveStatus)),
      );
      final storage = await _storage();
      final scope = await _userScope();
      final bookmarks = await storage.loadBookmarks(scope);
      final stats = computeLearningStats(roadmaps);
      state = state.copyWith(
        roadmaps: roadmaps,
        learningStats: stats.copyWith(bookmarkedNodeIds: bookmarks.toList()),
        skillProgress: computeSkillProgress(roadmaps),
        bookmarkedNodeIds: bookmarks,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getApiErrorMessage(e));
    }
  }

  Future<RoadmapModel?> generateAI({
    String? targetRole,
    String? repoId,
    String level = 'beginner',
    int durationWeeks = 6,
    String language = 'vi',
    bool forceRegenerate = false,
  }) async {
    final role = targetRole ?? state.selectedTargetRole;
    state = state.copyWith(isGenerating: true, clearError: true, selectedTargetRole: role);
    try {
      if (AppConfig.demoMode) {
        await Future<void>.delayed(const Duration(milliseconds: 800));
        state = state.copyWith(isGenerating: false);
        return mockRoadmaps.first;
      }
      final roadmap = await safeRequest(
        () => _api.generateRoadmap(
          targetRole: role,
          repoId: repoId,
          level: level,
          durationWeeks: durationWeeks,
          language: language,
          forceRegenerate: forceRegenerate,
        ),
      );
      _applyGeneratedRoadmap(roadmap);
      return roadmap;
    } catch (e) {
      final message = getApiErrorMessage(e);
      // BE có thể đã lưu roadmap nhưng lỗi khi gọi createAutomaticNotification (chưa deploy).
      if (_isRoadmapNotificationBackendBug(message)) {
        final recovered = await _recoverAfterGenerateFailure(role);
        if (recovered != null) {
          _applyGeneratedRoadmap(recovered);
          return recovered;
        }
      }
      state = state.copyWith(isGenerating: false, error: message);
      rethrow;
    }
  }

  void _applyGeneratedRoadmap(RoadmapModel roadmap) {
    final roadmaps = [
      roadmap,
      ...state.roadmaps.where((r) => r.id != roadmap.id),
    ];
    final stats = computeLearningStats(roadmaps);
    state = state.copyWith(
      roadmaps: roadmaps,
      aiRecommendation: normalizeAiRecommendation(roadmap),
      learningStats: stats.copyWith(bookmarkedNodeIds: state.bookmarkedNodeIds.toList()),
      skillProgress: computeSkillProgress(roadmaps),
      isGenerating: false,
    );
  }

  bool _isRoadmapNotificationBackendBug(String message) {
    final m = message.toLowerCase();
    return m.contains('createautomaticnotification') ||
        (m.contains('automaticnotification') && m.contains('not defined'));
  }

  Future<RoadmapModel?> _recoverAfterGenerateFailure(String targetRole) async {
    try {
      var roadmaps = await safeRequest(
        () => _api.getMyRoadmaps(status: 'active', targetRole: targetRole),
      );
      if (roadmaps.isEmpty) {
        roadmaps = await safeRequest(() => _api.getMyRoadmaps(status: 'active'));
      }
      for (final r in roadmaps) {
        if (r.careerOutcome == targetRole || r.tags.contains(targetRole)) {
          return r;
        }
      }
      return roadmaps.isNotEmpty ? roadmaps.first : null;
    } catch (_) {
      return null;
    }
  }

  Future<RoadmapModel?> fetchRoadmap(String id) async {
    final cached = getById(id);
    if (cached != null) return cached;
    if (AppConfig.demoMode) return null;
    try {
      final roadmap = await safeRequest(() => _api.getRoadmap(id));
      final merged = await _mergeLocalProgress([roadmap]);
      final withProgress = merged.first;
      await _persistRoadmapsState([
        withProgress,
        ...state.roadmaps.where((r) => r.id != withProgress.id),
      ]);
      return withProgress;
    } catch (_) {
      return null;
    }
  }

  RoadmapModel? getById(String id) {
    for (final r in state.roadmaps) {
      if (r.id == id || r.slug == id) return r;
    }
    return null;
  }

  ({int completed, int total, int hoursRemaining}) progressFor(RoadmapModel? roadmap) {
    if (roadmap == null) return (completed: 0, total: 0, hoursRemaining: 0);
    var completed = 0;
    var total = 0;
    var hoursRemaining = 0;
    for (final module in roadmap.modules) {
      for (final node in module.nodes) {
        total++;
        if (node.status == 'completed') {
          completed++;
        } else {
          hoursRemaining += node.estimatedHours;
        }
      }
    }
    return (completed: completed, total: total, hoursRemaining: hoursRemaining);
  }

  Future<void> archiveRoadmap(String id) async {
    state = state.copyWith(isArchiving: true, clearError: true);
    try {
      if (!AppConfig.demoMode) {
        final archived = await safeRequest(() => _api.archiveRoadmap(id));
        state = state.copyWith(
          roadmaps: state.roadmaps.map((r) => r.id == id ? archived : r).toList(),
        );
      } else {
        state = state.copyWith(
          roadmaps: state.roadmaps.where((r) => r.id != id).toList(),
        );
      }
      state = state.copyWith(isArchiving: false);
    } catch (e) {
      state = state.copyWith(isArchiving: false, error: getApiErrorMessage(e));
      rethrow;
    }
  }

  void toggleBookmark(String nodeId) {
    final next = Set<String>.from(state.bookmarkedNodeIds);
    if (next.contains(nodeId)) {
      next.remove(nodeId);
    } else {
      next.add(nodeId);
    }
    state = state.copyWith(bookmarkedNodeIds: next);
    if (!AppConfig.demoMode) {
      Future.microtask(() async {
        final storage = await _storage();
        await storage.saveBookmarks(await _userScope(), next);
      });
    }
  }

  bool isBookmarked(String nodeId) => state.bookmarkedNodeIds.contains(nodeId);

  Future<void> updateNodeStatus(String roadmapId, String nodeId, String status) async {
    final roadmaps = state.roadmaps.map((roadmap) {
      if (roadmap.id != roadmapId && roadmap.slug != roadmapId) return roadmap;

      final modules = roadmap.modules.map((module) {
        final nodes = module.nodes.map((node) {
          if (node.id != nodeId) return node;
          return node.copyWith(status: status);
        }).toList();
        return RoadmapModuleModel(
          id: module.id,
          title: module.title,
          description: module.description,
          nodes: nodes,
        );
      }).toList();

      return roadmap.copyWith(
        modules: modules,
        progress: roadmapProgressPercent(roadmap.copyWith(modules: modules)),
      );
    }).toList();

    await _persistRoadmapsState(roadmaps);

    if (!AppConfig.demoMode) {
      final storage = await _storage();
      await storage.saveNodeStatus(await _userScope(), roadmapId, nodeId, status);
    }
  }
}

final roadmapProvider = NotifierProvider<RoadmapNotifier, RoadmapState>(RoadmapNotifier.new);

class DashboardState {
  const DashboardState({this.payload, this.isLoading = false, this.error});
  final Map<String, dynamic>? payload;
  final bool isLoading;
  final String? error;
}

class DashboardNotifier extends Notifier<DashboardState> {
  late AppApi _api;

  @override
  DashboardState build() {
    _api = ref.read(appApiProvider);
    return const DashboardState();
  }

  Future<void> load() async {
    state = const DashboardState(isLoading: true);
    try {
      final payload = AppConfig.demoMode
          ? await DemoService.instance.dashboardMe()
          : await safeRequest(_api.dashboardMe);
      state = DashboardState(payload: payload);
    } catch (e) {
      state = DashboardState(error: getApiErrorMessage(e));
    }
  }
}

final dashboardProvider = NotifierProvider<DashboardNotifier, DashboardState>(DashboardNotifier.new);

class NotificationState {
  const NotificationState({this.items = const [], this.isLoading = false, this.error});
  final List<NotificationModel> items;
  final bool isLoading;
  final String? error;
}

class NotificationNotifier extends Notifier<NotificationState> {
  late AppApi _api;

  @override
  NotificationState build() {
    _api = ref.read(appApiProvider);
    return const NotificationState();
  }

  Future<void> load({bool unreadOnly = false, String? type}) async {
    state = const NotificationState(isLoading: true);
    try {
      final items = AppConfig.demoMode
          ? await DemoService.instance.getNotifications(unreadOnly: unreadOnly, type: type)
          : await safeRequest(() => _api.getNotifications(unreadOnly: unreadOnly, type: type));
      state = NotificationState(items: items);
    } catch (e) {
      state = NotificationState(error: getApiErrorMessage(e));
    }
  }

  Future<void> create(String title, String message, String type) async {
    if (AppConfig.demoMode) {
      await DemoService.instance.createNotification(title: title, message: message, type: type);
    } else {
      await safeRequest(() => _api.createNotification(title: title, message: message, type: type));
    }
    await load();
  }

  Future<void> markRead(String id) async {
    if (AppConfig.demoMode) {
      await DemoService.instance.markNotificationRead(id);
    } else {
      await safeRequest(() => _api.markNotificationRead(id));
    }
    await load();
  }

  Future<void> remove(String id) async {
    if (AppConfig.demoMode) {
      await DemoService.instance.deleteNotification(id);
    } else {
      await safeRequest(() => _api.deleteNotification(id));
    }
    await load();
  }
}

final notificationProvider = NotifierProvider<NotificationNotifier, NotificationState>(NotificationNotifier.new);
