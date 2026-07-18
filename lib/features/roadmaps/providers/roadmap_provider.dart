import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../data/roadmap_repository.dart';
import '../models/roadmap_generate_params.dart';
import '../../../core/network/api_utils.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/normalizers.dart';
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

  RoadmapFilters copyWith(
      {String? search,
      String? category,
      String? difficulty,
      String? duration}) {
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
    this.deletingRoadmapId,
    this.error,
    this.selectedTargetRole = '',
    this.learningByItemId = const {},
    this.openingLearningItemId,
    this.generatingLearningItemId,
    this.learningError,
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
  final String? deletingRoadmapId;
  final String? error;
  final String selectedTargetRole;
  final Map<String, LearningContentModel> learningByItemId;
  final String? openingLearningItemId;
  final String? generatingLearningItemId;
  final String? learningError;

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
    String? deletingRoadmapId,
    bool clearDeletingRoadmapId = false,
    String? error,
    bool clearError = false,
    String? selectedTargetRole,
    Map<String, LearningContentModel>? learningByItemId,
    String? openingLearningItemId,
    bool clearOpeningLearningItemId = false,
    String? generatingLearningItemId,
    bool clearGeneratingLearningItemId = false,
    String? learningError,
    bool clearLearningError = false,
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
      deletingRoadmapId: clearDeletingRoadmapId
          ? null
          : (deletingRoadmapId ?? this.deletingRoadmapId),
      error: clearError ? null : (error ?? this.error),
      selectedTargetRole: selectedTargetRole ?? this.selectedTargetRole,
      learningByItemId: learningByItemId ?? this.learningByItemId,
      openingLearningItemId: clearOpeningLearningItemId
          ? null
          : (openingLearningItemId ?? this.openingLearningItemId),
      generatingLearningItemId: clearGeneratingLearningItemId
          ? null
          : (generatingLearningItemId ?? this.generatingLearningItemId),
      learningError:
          clearLearningError ? null : (learningError ?? this.learningError),
    );
  }
}

class RoadmapNotifier extends Notifier<RoadmapState> {
  late RoadmapRepository _repository;
  RoadmapProgressStorage? _progressStorage;
  Future<void>? _loadInFlight;
  String? _loadInFlightStatus;

  Future<RoadmapProgressStorage> _storage() async {
    return _progressStorage ??= await RoadmapProgressStorage.create();
  }

  Future<String> _userScope() async {
    final user = await ref.read(tokenStorageProvider).getUser();
    return (user?['id'] ?? user?['_id'] ?? 'guest').toString();
  }

  Future<void> _persistRoadmapsState(List<RoadmapModel> roadmaps,
      {Set<String>? bookmarks}) async {
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
    return const RoadmapState();
  }

  void setFilters(RoadmapFilters filters) =>
      state = state.copyWith(filters: filters);

  void setTargetRole(String role) =>
      state = state.copyWith(selectedTargetRole: role);

  Future<void> setStatusFilter(String status) async {
    if (status == state.statusFilter) return;
    state = state.copyWith(
      statusFilter: status,
      roadmaps: const [],
      isLoading: true,
      clearError: true,
    );
    await loadRoadmaps(status: status);
  }

  Future<void> loadRoadmaps({String? status}) async {
    final effectiveStatus = status ?? state.statusFilter;
    if (_loadInFlight != null && _loadInFlightStatus == effectiveStatus) {
      return _loadInFlight!;
    }

    final showLoading = state.roadmaps.isEmpty;
    state = state.copyWith(
      isLoading: showLoading,
      clearError: true,
      statusFilter: effectiveStatus,
    );

    _loadInFlightStatus = effectiveStatus;
    _loadInFlight =
        _loadRoadmapsTask(effectiveStatus, showLoading: showLoading);
    try {
      await _loadInFlight;
    } finally {
      _loadInFlight = null;
      _loadInFlightStatus = null;
    }
  }

  Future<void> _loadRoadmapsTask(String effectiveStatus,
      {required bool showLoading}) async {
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
      final roadmaps = await safeRequest(
          () => _repository.getMyRoadmaps(status: effectiveStatus));
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
    required RoadmapGenerateParams params,
  }) async {
    final role = params.targetRole;
    state = state.copyWith(
        isGenerating: true, clearError: true, selectedTargetRole: role);
    try {
      if (AppConfig.demoMode) {
        await Future<void>.delayed(const Duration(milliseconds: 800));
        state = state.copyWith(isGenerating: false);
        return mockRoadmaps.first;
      }
      final roadmap =
          await safeRequest(() => _repository.generateRoadmap(params));
      _applyGeneratedRoadmap(roadmap);
      return roadmap;
    } catch (e) {
      final message = getApiErrorMessage(e);
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
      learningStats:
          stats.copyWith(bookmarkedNodeIds: state.bookmarkedNodeIds.toList()),
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
        () =>
            _repository.getMyRoadmaps(status: 'active', targetRole: targetRole),
      );
      if (roadmaps.isEmpty) {
        roadmaps = await safeRequest(
            () => _repository.getMyRoadmaps(status: 'active'));
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
    if (AppConfig.demoMode) return getById(id);
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final roadmap = await safeRequest(() => _repository.getRoadmap(id));
      final progress =
          await safeRequest(() => _repository.getProgress(roadmap.id));
      final withProgress = mergeRoadmapProgress(roadmap, progress);
      await _persistRoadmapsState([
        withProgress,
        ...state.roadmaps.where((r) => r.id != withProgress.id),
      ]);
      state = state.copyWith(isLoading: false);
      return withProgress;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is ApiException && e.statusCode == 404
            ? 'Roadmap không tồn tại hoặc đã bị xóa.'
            : getApiErrorMessage(e),
      );
      return null;
    }
  }

  RoadmapModel? getById(String id) {
    for (final r in state.roadmaps) {
      if (r.id == id || r.slug == id) return r;
    }
    return null;
  }

  ({int completed, int total, int hoursRemaining}) progressFor(
      RoadmapModel? roadmap) {
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
        final archived =
            await safeRequest(() => _repository.archiveRoadmap(id));
        state = state.copyWith(
          roadmaps:
              state.roadmaps.map((r) => r.id == id ? archived : r).toList(),
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

  Future<void> deleteRoadmap(String id) async {
    state = state.copyWith(deletingRoadmapId: id, clearError: true);
    try {
      if (!AppConfig.demoMode) {
        await safeRequest(() => _repository.deleteRoadmap(id));
      }
    } catch (e) {
      if (e is! ApiException || e.statusCode != 404) {
        state = state.copyWith(
          clearDeletingRoadmapId: true,
          error: getApiErrorMessage(e),
        );
        rethrow;
      }
    }

    final remaining =
        state.roadmaps.where((roadmap) => roadmap.id != id).toList();
    state = state.copyWith(
      roadmaps: remaining,
      clearDeletingRoadmapId: true,
      learningByItemId: const {},
      clearOpeningLearningItemId: true,
      clearGeneratingLearningItemId: true,
      clearLearningError: true,
    );
    await _persistRoadmapsState(remaining);
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

  Future<void> updateNodeStatus(
      String roadmapId, String nodeId, String status) async {
    if (nodeId.isEmpty) {
      state = state.copyWith(
          error: 'Roadmap task không có itemId hợp lệ. Hãy tải lại roadmap.');
      return;
    }

    if (!AppConfig.demoMode) {
      try {
        final payload = await safeRequest(
            () => _repository.updateProgress(roadmapId, nodeId, status));
        await _applyAuthoritativeProgress(roadmapId, payload);
        return;
      } catch (e) {
        state = state.copyWith(error: getApiErrorMessage(e));
        rethrow;
      }
    }

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
  }

  Future<void> _applyAuthoritativeProgress(
      String roadmapId, Map<String, dynamic> payload) {
    final roadmaps = state.roadmaps.map((roadmap) {
      if (roadmap.id != roadmapId && roadmap.slug != roadmapId) return roadmap;
      return mergeRoadmapProgress(roadmap, payload);
    }).toList();
    return _persistRoadmapsState(roadmaps);
  }

  Future<LearningContentModel> openLearning(
      String roadmapId, String itemId) async {
    if (itemId.isEmpty) {
      throw ApiException('Task không có itemId hợp lệ. Hãy tải lại roadmap.');
    }
    final cached = state.learningByItemId[itemId];
    if (cached != null) return cached;

    state = state.copyWith(
      openingLearningItemId: itemId,
      clearGeneratingLearningItemId: true,
      clearLearningError: true,
    );
    try {
      final availability = await safeRequest(
          () => _repository.getLearningAvailability(roadmapId));
      final learningStatus = availability[itemId];
      if (learningStatus == null) {
        throw ApiException(
            'Không tìm thấy itemId trong danh sách learning của roadmap.');
      }

      final LearningContentModel learning;
      if (learningStatus == 'available') {
        learning =
            await safeRequest(() => _repository.getLearning(roadmapId, itemId));
      } else {
        state = state.copyWith(
          generatingLearningItemId: itemId,
          clearOpeningLearningItemId: true,
        );
        learning = await safeRequest(
            () => _repository.generateLearning(roadmapId, itemId));
      }
      state = state.copyWith(
        learningByItemId: {...state.learningByItemId, itemId: learning},
        clearOpeningLearningItemId: true,
        clearGeneratingLearningItemId: true,
        clearLearningError: true,
      );
      return learning;
    } catch (e) {
      final message = getApiErrorMessage(e);
      state = state.copyWith(
        clearOpeningLearningItemId: true,
        clearGeneratingLearningItemId: true,
        learningError: message,
      );
      rethrow;
    }
  }
}

final roadmapProvider =
    NotifierProvider<RoadmapNotifier, RoadmapState>(RoadmapNotifier.new);
