import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/demo/demo_service.dart';
import '../core/network/api_utils.dart';
import '../core/network/app_api.dart';
import '../core/network/dio_client.dart';
import 'auth/providers/auth_provider.dart';
import '../shared/models/app_models.dart';
import '../core/network/normalizers.dart';
import 'roadmaps/data/roadmap_mock_data.dart';

class RepositoryState {
  const RepositoryState({
    this.repositories = const [],
    this.analyses = const [],
    this.aiFeedbacks = const {},
    this.selected,
    this.isLoading = false,
    this.analyzingRepoId,
    this.generatingFeedbackRepoId,
    this.error,
  });

  final List<RepositoryModel> repositories;
  final List<AnalysisModel> analyses;
  final Map<String, AiFeedbackModel> aiFeedbacks;
  final RepositoryModel? selected;
  final bool isLoading;
  final String? analyzingRepoId;
  final String? generatingFeedbackRepoId;
  final String? error;

  bool isAnalyzingRepo(String id) => analyzingRepoId == id;

  bool isGeneratingFeedback(String id) => generatingFeedbackRepoId == id;

  bool get isAnalyzing => analyzingRepoId != null;

  AiFeedbackModel? feedbackFor(String repoId) => aiFeedbacks[repoId];

  RepositoryState copyWith({
    List<RepositoryModel>? repositories,
    List<AnalysisModel>? analyses,
    Map<String, AiFeedbackModel>? aiFeedbacks,
    RepositoryModel? selected,
    bool? isLoading,
    String? analyzingRepoId,
    bool clearAnalyzingRepoId = false,
    String? generatingFeedbackRepoId,
    bool clearGeneratingFeedbackRepoId = false,
    String? error,
    bool clearError = false,
  }) {
    return RepositoryState(
      repositories: repositories ?? this.repositories,
      analyses: analyses ?? this.analyses,
      aiFeedbacks: aiFeedbacks ?? this.aiFeedbacks,
      selected: selected ?? this.selected,
      isLoading: isLoading ?? this.isLoading,
      analyzingRepoId: clearAnalyzingRepoId ? null : (analyzingRepoId ?? this.analyzingRepoId),
      generatingFeedbackRepoId:
          clearGeneratingFeedbackRepoId ? null : (generatingFeedbackRepoId ?? this.generatingFeedbackRepoId),
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
      state = state.copyWith(sessions: sessions, current: state.current ?? (sessions.isNotEmpty ? sessions.first : null), isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getApiErrorMessage(e));
    }
  }

  Future<void> createSession(String title) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final session = AppConfig.demoMode
          ? await DemoService.instance.createChatSession(title)
          : await safeRequest(() => _api.createChatSession(title));
      state = state.copyWith(sessions: [session, ...state.sessions], current: session, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getApiErrorMessage(e));
      rethrow;
    }
  }

  Future<void> selectSession(String id) async {
    final cached = state.sessions.where((s) => s.id == id).firstOrNull;
    if (cached != null) state = state.copyWith(current: cached);
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
    if (session == null || session.id.isEmpty) return;

    final optimistic = ChatMessageModel(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      content: content,
      timestamp: DateTime.now().toIso8601String(),
    );
    final updated = session.copyWith(messages: [...session.messages, optimistic]);
    state = state.copyWith(current: updated, isLoading: true, clearError: true);

    try {
      ChatSessionModel? nextSession;
      if (AppConfig.demoMode) {
        nextSession = await DemoService.instance.sendChatMessage(session!.id, content);
      } else {
        final payload = await safeRequest(() => _api.sendChatMessage(session!.id, content));
        if (payload is Map && payload.containsKey('messages')) {
          nextSession = ChatSessionModel.fromJson(Map<String, dynamic>.from(payload));
        } else {
          final reply = extractApiResource<dynamic>(payload, ['assistantMessage', 'message', 'reply', 'response']);
          if (reply != null) {
            nextSession = updated.copyWith(messages: [...updated.messages, normalizeChatMessage(reply)]);
          }
        }
      }
      nextSession ??= updated;
      state = state.copyWith(
        current: nextSession,
        sessions: state.sessions.map((s) => s.id == session!.id ? nextSession! : s).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getApiErrorMessage(e));
      rethrow;
    }
  }
}

ChatMessageModel normalizeChatMessage(dynamic payload) {
  if (payload is Map) return ChatMessageModel.fromJson(Map<String, dynamic>.from(payload));
  return ChatMessageModel(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    role: 'assistant',
    content: payload.toString(),
    timestamp: DateTime.now().toIso8601String(),
  );
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
    this.filters = const RoadmapFilters(),
    this.isLoading = false,
    this.isGenerating = false,
    this.error,
    this.selectedTargetRole = 'Backend Developer',
  });

  final List<RoadmapModel> roadmaps;
  final AIRecommendationModel? aiRecommendation;
  final List<SkillProgressModel> skillProgress;
  final LearningStatsModel? learningStats;
  final RoadmapFilters filters;
  final bool isLoading;
  final bool isGenerating;
  final String? error;
  final String selectedTargetRole;

  RoadmapState copyWith({
    List<RoadmapModel>? roadmaps,
    AIRecommendationModel? aiRecommendation,
    List<SkillProgressModel>? skillProgress,
    LearningStatsModel? learningStats,
    RoadmapFilters? filters,
    bool? isLoading,
    bool? isGenerating,
    String? error,
    bool clearError = false,
    String? selectedTargetRole,
  }) {
    return RoadmapState(
      roadmaps: roadmaps ?? this.roadmaps,
      aiRecommendation: aiRecommendation ?? this.aiRecommendation,
      skillProgress: skillProgress ?? this.skillProgress,
      learningStats: learningStats ?? this.learningStats,
      filters: filters ?? this.filters,
      isLoading: isLoading ?? this.isLoading,
      isGenerating: isGenerating ?? this.isGenerating,
      error: clearError ? null : (error ?? this.error),
      selectedTargetRole: selectedTargetRole ?? this.selectedTargetRole,
    );
  }
}

class RoadmapNotifier extends Notifier<RoadmapState> {
  late AppApi _api;

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

  Future<void> loadRoadmaps() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (AppConfig.demoMode) {
        state = state.copyWith(
          roadmaps: mockRoadmaps,
          aiRecommendation: mockAIRecommendation,
          skillProgress: mockSkillProgress,
          learningStats: mockLearningStats,
          isLoading: false,
        );
        return;
      }
      final roadmaps = await safeRequest(_api.getMyRoadmaps);
      final stats = computeLearningStats(roadmaps);
      final skills = computeSkillProgress(roadmaps);
      final recommendation = roadmaps.isNotEmpty
          ? normalizeAiRecommendation(
              roadmaps.first,
              strengths: roadmaps.first.tags.take(4).toList(),
              missingSkills: roadmaps.first.tags.skip(4).toList(),
            )
          : null;
      state = state.copyWith(
        roadmaps: roadmaps,
        learningStats: stats,
        skillProgress: skills,
        aiRecommendation: recommendation,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getApiErrorMessage(e));
    }
  }

  Future<void> generateAI({bool forceRegenerate = false}) async {
    state = state.copyWith(isGenerating: true, clearError: true);
    try {
      if (AppConfig.demoMode) {
        await Future<void>.delayed(const Duration(milliseconds: 800));
        state = state.copyWith(isGenerating: false);
        return;
      }
      final roadmap = await safeRequest(
        () => _api.generateRoadmap(
          targetRole: state.selectedTargetRole,
          forceRegenerate: forceRegenerate,
        ),
      );
      final recommendation = normalizeAiRecommendation(roadmap);
      final roadmaps = [
        roadmap,
        ...state.roadmaps.where((r) => r.id != roadmap.id),
      ];
      state = state.copyWith(
        roadmaps: roadmaps,
        aiRecommendation: recommendation,
        learningStats: computeLearningStats(roadmaps),
        skillProgress: computeSkillProgress(roadmaps),
        isGenerating: false,
      );
    } catch (e) {
      state = state.copyWith(isGenerating: false, error: getApiErrorMessage(e));
      rethrow;
    }
  }

  Future<RoadmapModel?> fetchRoadmap(String id) async {
    final cached = getById(id);
    if (cached != null) return cached;
    if (AppConfig.demoMode) return null;
    try {
      final roadmap = await safeRequest(() => _api.getRoadmap(id));
      state = state.copyWith(
        roadmaps: [
          roadmap,
          ...state.roadmaps.where((r) => r.id != roadmap.id),
        ],
      );
      return roadmap;
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

  void updateNodeStatus(String roadmapId, String nodeId, String status) {
    final roadmaps = state.roadmaps.map((roadmap) {
      if (roadmap.id != roadmapId && roadmap.slug != roadmapId) return roadmap;
      final modules = roadmap.modules.map((module) {
        final nodes = module.nodes.map((node) {
          if (node.id != nodeId) return node;
          return node.copyWith(status: status);
        }).toList();
        return RoadmapModuleModel(id: module.id, title: module.title, description: module.description, nodes: nodes);
      }).toList();
      return RoadmapModel(
        id: roadmap.id,
        slug: roadmap.slug,
        title: roadmap.title,
        subtitle: roadmap.subtitle,
        description: roadmap.description,
        category: roadmap.category,
        difficulty: roadmap.difficulty,
        estimatedWeeks: roadmap.estimatedWeeks,
        estimatedHours: roadmap.estimatedHours,
        tags: roadmap.tags,
        isFeatured: roadmap.isFeatured,
        isAIRecommended: roadmap.isAIRecommended,
        progress: roadmap.progress,
        modules: modules,
        careerOutcome: roadmap.careerOutcome,
      );
    }).toList();
    final delta = status == 'completed' ? 120 : -120;
    final stats = state.learningStats ?? computeLearningStats(state.roadmaps);
    state = state.copyWith(
      roadmaps: roadmaps,
      learningStats: stats.copyWith(
        completedNodes: status == 'completed' ? stats.completedNodes + 1 : stats.completedNodes,
        totalXp: stats.totalXp + delta,
      ),
    );
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
