import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../data/roadmap_repository.dart';
import '../../../core/network/api_utils.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/normalizers.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/storage/roadmap_progress_storage.dart';
import '../../../shared/models/app_models.dart';
import '../data/roadmap_mock_data.dart';
import '../utils/roadmap_progress_utils.dart';
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
  late RoadmapRepository _repository;
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
    _repository = ref.read(roadmapRepositoryProvider);
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
        await safeRequest(() => _repository.getMyRoadmaps(status: effectiveStatus)),
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
        () => _repository.generateRoadmap(
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
        () => _repository.getMyRoadmaps(status: 'active', targetRole: targetRole),
      );
      if (roadmaps.isEmpty) {
        roadmaps = await safeRequest(() => _repository.getMyRoadmaps(status: 'active'));
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
      final roadmap = await safeRequest(() => _repository.getRoadmap(id));
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
        final archived = await safeRequest(() => _repository.archiveRoadmap(id));
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
