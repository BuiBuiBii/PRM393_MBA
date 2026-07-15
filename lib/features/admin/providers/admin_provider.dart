import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_utils.dart';
import '../../../core/network/dio_client.dart';
import '../data/admin_api.dart';
import '../models/admin_models.dart';

final adminApiProvider =
    Provider<AdminApi>((ref) => AdminApi(ref.watch(dioProvider)));

class AdminDashboardState {
  const AdminDashboardState({this.stats, this.isLoading = false, this.error});

  final AdminDashboardStats? stats;
  final bool isLoading;
  final String? error;
}

class AdminDashboardNotifier extends Notifier<AdminDashboardState> {
  late AdminApi _api;

  @override
  AdminDashboardState build() {
    _api = ref.read(adminApiProvider);
    return const AdminDashboardState();
  }

  Future<void> load() async {
    state = const AdminDashboardState(isLoading: true);
    try {
      final stats = await safeRequest(_api.getDashboard);
      state = AdminDashboardState(stats: stats);
    } catch (e) {
      state = AdminDashboardState(error: getApiErrorMessage(e));
    }
  }
}

final adminDashboardProvider =
    NotifierProvider<AdminDashboardNotifier, AdminDashboardState>(
        AdminDashboardNotifier.new);

class AdminListState<T> {
  const AdminListState({
    this.items = const [],
    this.pagination =
        const AdminPagination(page: 1, limit: 20, total: 0, totalPages: 0),
    this.isLoading = false,
    this.error,
    this.search = '',
    this.filter,
    this.secondaryFilter,
  });

  final List<T> items;
  final AdminPagination pagination;
  final bool isLoading;
  final String? error;
  final String search;
  final String? filter;
  final String? secondaryFilter;
}

mixin AdminPagedListMixin<T> on Notifier<AdminListState<T>> {
  AdminApi get adminApi;
  static const limit = 20;

  Future<void> loadPaged({
    required int page,
    required Future<AdminPage<T>> Function() fetch,
    String? search,
    String? filter,
    String? secondaryFilter,
  }) async {
    state = AdminListState<T>(
      items: state.items,
      pagination: state.pagination,
      isLoading: true,
      search: search ?? state.search,
      filter: filter ?? state.filter,
      secondaryFilter: secondaryFilter ?? state.secondaryFilter,
    );
    try {
      final pageData = await safeRequest(fetch);
      state = AdminListState(
        items: pageData.items,
        pagination: pageData.pagination,
        search: search ?? state.search,
        filter: filter ?? state.filter,
        secondaryFilter: secondaryFilter ?? state.secondaryFilter,
      );
    } catch (e) {
      state = AdminListState(
        items: state.items,
        pagination: state.pagination,
        isLoading: false,
        error: getApiErrorMessage(e),
        search: search ?? state.search,
        filter: filter ?? state.filter,
        secondaryFilter: secondaryFilter ?? state.secondaryFilter,
      );
    }
  }
}

class AdminUsersNotifier extends Notifier<AdminListState<AdminUserRecord>>
    with AdminPagedListMixin<AdminUserRecord> {
  @override
  late final AdminApi adminApi;

  @override
  AdminListState<AdminUserRecord> build() {
    adminApi = ref.read(adminApiProvider);
    return const AdminListState();
  }

  Future<void> load(
          {int page = 1, String? search, String? role, String? status}) =>
      loadPaged(
        page: page,
        search: search,
        filter: role,
        secondaryFilter: status,
        fetch: () => adminApi.getUsers(
          page: page,
          limit: AdminPagedListMixin.limit,
          search: search,
          role: role,
          status: status,
        ),
      );

  Future<void> nextPage() {
    if (!state.pagination.hasNext) return Future.value();
    return load(
      page: state.pagination.page + 1,
      search: state.search,
      role: state.filter,
      status: state.secondaryFilter,
    );
  }

  Future<void> prevPage() {
    if (!state.pagination.hasPrev) return Future.value();
    return load(
      page: state.pagination.page - 1,
      search: state.search,
      role: state.filter,
      status: state.secondaryFilter,
    );
  }
}

final adminUsersProvider =
    NotifierProvider<AdminUsersNotifier, AdminListState<AdminUserRecord>>(
        AdminUsersNotifier.new);

class AdminReportsNotifier extends Notifier<AdminListState<AdminReportRecord>>
    with AdminPagedListMixin<AdminReportRecord> {
  @override
  late final AdminApi adminApi;

  @override
  AdminListState<AdminReportRecord> build() {
    adminApi = ref.read(adminApiProvider);
    return const AdminListState();
  }

  Future<void> load({int page = 1, String? status, String? targetType}) =>
      loadPaged(
        page: page,
        filter: status,
        fetch: () => adminApi.getReports(
          page: page,
          limit: AdminPagedListMixin.limit,
          status: status,
          targetType: targetType,
        ),
      );

  Future<void> nextPage() {
    if (!state.pagination.hasNext) return Future.value();
    return load(page: state.pagination.page + 1, status: state.filter);
  }

  Future<void> prevPage() {
    if (!state.pagination.hasPrev) return Future.value();
    return load(page: state.pagination.page - 1, status: state.filter);
  }
}

final adminReportsProvider =
    NotifierProvider<AdminReportsNotifier, AdminListState<AdminReportRecord>>(
        AdminReportsNotifier.new);

class AdminReposNotifier extends Notifier<AdminListState<AdminRepoRecord>>
    with AdminPagedListMixin<AdminRepoRecord> {
  @override
  late final AdminApi adminApi;

  @override
  AdminListState<AdminRepoRecord> build() {
    adminApi = ref.read(adminApiProvider);
    return const AdminListState();
  }

  Future<void> load({int page = 1, String? search}) => loadPaged(
        page: page,
        search: search,
        fetch: () => adminApi.getRepositories(
            page: page, limit: AdminPagedListMixin.limit, search: search),
      );

  Future<void> nextPage() {
    if (!state.pagination.hasNext) return Future.value();
    return load(page: state.pagination.page + 1, search: state.search);
  }

  Future<void> prevPage() {
    if (!state.pagination.hasPrev) return Future.value();
    return load(page: state.pagination.page - 1, search: state.search);
  }
}

final adminReposProvider =
    NotifierProvider<AdminReposNotifier, AdminListState<AdminRepoRecord>>(
        AdminReposNotifier.new);

class AdminAnalysisNotifier
    extends Notifier<AdminListState<AdminAnalysisRecord>>
    with AdminPagedListMixin<AdminAnalysisRecord> {
  @override
  late final AdminApi adminApi;

  @override
  AdminListState<AdminAnalysisRecord> build() {
    adminApi = ref.read(adminApiProvider);
    return const AdminListState();
  }

  Future<void> load({int page = 1, String? search}) => loadPaged(
        page: page,
        search: search,
        fetch: () => adminApi.getAnalyses(
            page: page, limit: AdminPagedListMixin.limit, search: search),
      );

  Future<void> nextPage() {
    if (!state.pagination.hasNext) return Future.value();
    return load(page: state.pagination.page + 1, search: state.search);
  }

  Future<void> prevPage() {
    if (!state.pagination.hasPrev) return Future.value();
    return load(page: state.pagination.page - 1, search: state.search);
  }
}

final adminAnalysisProvider = NotifierProvider<AdminAnalysisNotifier,
    AdminListState<AdminAnalysisRecord>>(AdminAnalysisNotifier.new);

class AdminFeedbackNotifier
    extends Notifier<AdminListState<AdminFeedbackRecord>>
    with AdminPagedListMixin<AdminFeedbackRecord> {
  @override
  late final AdminApi adminApi;

  @override
  AdminListState<AdminFeedbackRecord> build() {
    adminApi = ref.read(adminApiProvider);
    return const AdminListState();
  }

  Future<void> load({int page = 1, String? search}) => loadPaged(
        page: page,
        search: search,
        fetch: () => adminApi.getAiFeedback(
            page: page, limit: AdminPagedListMixin.limit, search: search),
      );

  Future<void> nextPage() {
    if (!state.pagination.hasNext) return Future.value();
    return load(page: state.pagination.page + 1, search: state.search);
  }

  Future<void> prevPage() {
    if (!state.pagination.hasPrev) return Future.value();
    return load(page: state.pagination.page - 1, search: state.search);
  }
}

final adminFeedbackProvider = NotifierProvider<AdminFeedbackNotifier,
    AdminListState<AdminFeedbackRecord>>(AdminFeedbackNotifier.new);

class AdminRoadmapsNotifier extends Notifier<AdminListState<AdminRoadmapRecord>>
    with AdminPagedListMixin<AdminRoadmapRecord> {
  @override
  late final AdminApi adminApi;

  @override
  AdminListState<AdminRoadmapRecord> build() {
    adminApi = ref.read(adminApiProvider);
    return const AdminListState();
  }

  Future<void> load({int page = 1, String? search, String? status}) =>
      loadPaged(
        page: page,
        search: search,
        filter: status,
        fetch: () => adminApi.getRoadmaps(
            page: page,
            limit: AdminPagedListMixin.limit,
            search: search,
            status: status),
      );

  Future<void> nextPage() {
    if (!state.pagination.hasNext) return Future.value();
    return load(
        page: state.pagination.page + 1,
        search: state.search,
        status: state.filter);
  }

  Future<void> prevPage() {
    if (!state.pagination.hasPrev) return Future.value();
    return load(
        page: state.pagination.page - 1,
        search: state.search,
        status: state.filter);
  }
}

final adminRoadmapsProvider =
    NotifierProvider<AdminRoadmapsNotifier, AdminListState<AdminRoadmapRecord>>(
        AdminRoadmapsNotifier.new);

class AdminRoadmapDetailState {
  const AdminRoadmapDetailState(
      {this.roadmap,
      this.isLoading = false,
      this.error,
      this.isSaving = false});

  final AdminRoadmapRecord? roadmap;
  final bool isLoading;
  final String? error;
  final bool isSaving;
}

class AdminRoadmapDetailNotifier extends Notifier<AdminRoadmapDetailState> {
  late AdminApi _api;

  @override
  AdminRoadmapDetailState build() {
    _api = ref.read(adminApiProvider);
    return const AdminRoadmapDetailState();
  }

  Future<void> load(String roadmapId) async {
    state = const AdminRoadmapDetailState(isLoading: true);
    try {
      final roadmap = await safeRequest(() => _api.getRoadmap(roadmapId));
      state = AdminRoadmapDetailState(roadmap: roadmap);
    } catch (e) {
      state = AdminRoadmapDetailState(error: getApiErrorMessage(e));
    }
  }

  Future<void> updateStatus(String roadmapId, String status) async {
    state = AdminRoadmapDetailState(roadmap: state.roadmap, isSaving: true);
    try {
      final roadmap =
          await safeRequest(() => _api.updateRoadmapStatus(roadmapId, status));
      state = AdminRoadmapDetailState(roadmap: roadmap);
    } catch (e) {
      state = AdminRoadmapDetailState(
          roadmap: state.roadmap, error: getApiErrorMessage(e));
    }
  }
}

final adminRoadmapDetailProvider =
    NotifierProvider<AdminRoadmapDetailNotifier, AdminRoadmapDetailState>(
        AdminRoadmapDetailNotifier.new);

class AdminAnalysisDetailState {
  const AdminAnalysisDetailState(
      {this.analysis, this.isLoading = false, this.error});

  final AdminAnalysisRecord? analysis;
  final bool isLoading;
  final String? error;
}

class AdminAnalysisDetailNotifier extends Notifier<AdminAnalysisDetailState> {
  late AdminApi _api;

  @override
  AdminAnalysisDetailState build() {
    _api = ref.read(adminApiProvider);
    return const AdminAnalysisDetailState();
  }

  Future<void> load(String analysisId) async {
    state = const AdminAnalysisDetailState(isLoading: true);
    try {
      final analysis = await safeRequest(() => _api.getAnalysis(analysisId));
      state = AdminAnalysisDetailState(analysis: analysis);
    } catch (e) {
      state = AdminAnalysisDetailState(error: getApiErrorMessage(e));
    }
  }
}

final adminAnalysisDetailProvider =
    NotifierProvider<AdminAnalysisDetailNotifier, AdminAnalysisDetailState>(
        AdminAnalysisDetailNotifier.new);

class AdminFeedbackDetailState {
  const AdminFeedbackDetailState(
      {this.feedback, this.isLoading = false, this.error});

  final AdminFeedbackRecord? feedback;
  final bool isLoading;
  final String? error;
}

class AdminFeedbackDetailNotifier extends Notifier<AdminFeedbackDetailState> {
  late AdminApi _api;

  @override
  AdminFeedbackDetailState build() {
    _api = ref.read(adminApiProvider);
    return const AdminFeedbackDetailState();
  }

  Future<void> load(String feedbackId) async {
    state = const AdminFeedbackDetailState(isLoading: true);
    try {
      final feedback =
          await safeRequest(() => _api.getAiFeedbackDetail(feedbackId));
      state = AdminFeedbackDetailState(feedback: feedback);
    } catch (e) {
      state = AdminFeedbackDetailState(error: getApiErrorMessage(e));
    }
  }
}

final adminFeedbackDetailProvider =
    NotifierProvider<AdminFeedbackDetailNotifier, AdminFeedbackDetailState>(
        AdminFeedbackDetailNotifier.new);

class AdminRepoDetailState {
  const AdminRepoDetailState(
      {this.repository, this.isLoading = false, this.error});

  final AdminRepoRecord? repository;
  final bool isLoading;
  final String? error;
}

class AdminRepoDetailNotifier extends Notifier<AdminRepoDetailState> {
  late AdminApi _api;

  @override
  AdminRepoDetailState build() {
    _api = ref.read(adminApiProvider);
    return const AdminRepoDetailState();
  }

  Future<void> load(String repositoryId) async {
    state = const AdminRepoDetailState(isLoading: true);
    try {
      final repository =
          await safeRequest(() => _api.getRepository(repositoryId));
      state = AdminRepoDetailState(repository: repository);
    } catch (e) {
      state = AdminRepoDetailState(error: getApiErrorMessage(e));
    }
  }
}

final adminRepoDetailProvider =
    NotifierProvider<AdminRepoDetailNotifier, AdminRepoDetailState>(
        AdminRepoDetailNotifier.new);

class AdminUserDetailState {
  const AdminUserDetailState(
      {this.user, this.isLoading = false, this.error, this.isSaving = false});

  final AdminUserRecord? user;
  final bool isLoading;
  final String? error;
  final bool isSaving;
}

class AdminUserDetailNotifier extends Notifier<AdminUserDetailState> {
  late AdminApi _api;

  @override
  AdminUserDetailState build() {
    _api = ref.read(adminApiProvider);
    return const AdminUserDetailState();
  }

  Future<void> load(String userId) async {
    state = const AdminUserDetailState(isLoading: true);
    try {
      final user = await safeRequest(() => _api.getUser(userId));
      state = AdminUserDetailState(user: user);
    } catch (e) {
      state = AdminUserDetailState(error: getApiErrorMessage(e));
    }
  }

  Future<void> updateStatus(String userId, String status) async {
    state = AdminUserDetailState(user: state.user, isSaving: true);
    try {
      final user =
          await safeRequest(() => _api.updateUserStatus(userId, status));
      state = AdminUserDetailState(user: user);
    } catch (e) {
      state =
          AdminUserDetailState(user: state.user, error: getApiErrorMessage(e));
    }
  }

  Future<void> updateRole(String userId, String role) async {
    state = AdminUserDetailState(user: state.user, isSaving: true);
    try {
      final user = await safeRequest(() => _api.updateUserRole(userId, role));
      state = AdminUserDetailState(user: user);
    } catch (e) {
      state =
          AdminUserDetailState(user: state.user, error: getApiErrorMessage(e));
    }
  }
}

final adminUserDetailProvider =
    NotifierProvider<AdminUserDetailNotifier, AdminUserDetailState>(
        AdminUserDetailNotifier.new);

class AdminReportDetailState {
  const AdminReportDetailState(
      {this.report, this.isLoading = false, this.error, this.isSaving = false});

  final AdminReportRecord? report;
  final bool isLoading;
  final String? error;
  final bool isSaving;
}

class AdminReportDetailNotifier extends Notifier<AdminReportDetailState> {
  late AdminApi _api;

  @override
  AdminReportDetailState build() {
    _api = ref.read(adminApiProvider);
    return const AdminReportDetailState();
  }

  Future<void> load(String reportId) async {
    state = const AdminReportDetailState(isLoading: true);
    try {
      final report = await safeRequest(() => _api.getReport(reportId));
      state = AdminReportDetailState(report: report);
    } catch (e) {
      state = AdminReportDetailState(error: getApiErrorMessage(e));
    }
  }

  Future<void> updateStatus(String reportId, String status,
      {String? adminNote}) async {
    state = AdminReportDetailState(report: state.report, isSaving: true);
    try {
      final report = await safeRequest(() => _api.updateReportStatus(reportId,
          status: status, adminNote: adminNote));
      state = AdminReportDetailState(report: report);
    } catch (e) {
      state = AdminReportDetailState(
          report: state.report, error: getApiErrorMessage(e));
    }
  }
}

final adminReportDetailProvider =
    NotifierProvider<AdminReportDetailNotifier, AdminReportDetailState>(
        AdminReportDetailNotifier.new);

class AdminChatState {
  const AdminChatState({
    this.settings,
    this.sessions = const [],
    this.pagination = const AdminPagination(
      page: 1,
      limit: 20,
      total: 0,
      totalPages: 0,
    ),
    this.selected,
    this.statusFilter = 'waiting_admin',
    this.modeFilter,
    this.modeSourceFilter,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  final AdminChatSettings? settings;
  final List<AdminChatSession> sessions;
  final AdminPagination pagination;
  final AdminChatSession? selected;
  final String? statusFilter;
  final String? modeFilter;
  final String? modeSourceFilter;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  AdminChatState copyWith({
    AdminChatSettings? settings,
    List<AdminChatSession>? sessions,
    AdminPagination? pagination,
    AdminChatSession? selected,
    String? statusFilter,
    bool clearStatusFilter = false,
    String? modeFilter,
    bool clearModeFilter = false,
    String? modeSourceFilter,
    bool clearModeSourceFilter = false,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return AdminChatState(
      settings: settings ?? this.settings,
      sessions: sessions ?? this.sessions,
      pagination: pagination ?? this.pagination,
      selected: selected ?? this.selected,
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      modeFilter: clearModeFilter ? null : (modeFilter ?? this.modeFilter),
      modeSourceFilter: clearModeSourceFilter
          ? null
          : (modeSourceFilter ?? this.modeSourceFilter),
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AdminChatNotifier extends Notifier<AdminChatState> {
  late AdminApi _api;

  @override
  AdminChatState build() {
    _api = ref.read(adminApiProvider);
    return const AdminChatState();
  }

  Future<void> load({
    int page = 1,
    String? status,
    bool clearStatus = false,
    String? mode,
    bool clearMode = false,
    String? modeSource,
    bool clearModeSource = false,
  }) async {
    final nextStatus = clearStatus ? null : (status ?? state.statusFilter);
    final nextMode = clearMode ? null : (mode ?? state.modeFilter);
    final nextModeSource =
        clearModeSource ? null : (modeSource ?? state.modeSourceFilter);
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      statusFilter: nextStatus,
      clearStatusFilter: nextStatus == null,
      modeFilter: nextMode,
      clearModeFilter: nextMode == null,
      modeSourceFilter: nextModeSource,
      clearModeSourceFilter: nextModeSource == null,
    );
    try {
      final results = await Future.wait([
        safeRequest(_api.getChatSettings),
        safeRequest(
          () => _api.getChatSessions(
            page: page,
            status: nextStatus,
            mode: nextMode,
            modeSource: nextModeSource,
          ),
        ),
      ]);
      final pageData = results[1] as AdminPage<AdminChatSession>;
      state = state.copyWith(
        settings: results[0] as AdminChatSettings,
        sessions: pageData.items,
        pagination: pageData.pagination,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: getApiErrorMessage(e),
      );
    }
  }

  Future<void> updateGlobalMode(String mode) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final settings = await safeRequest(() => _api.updateChatSettings(mode));
      state = state.copyWith(settings: settings, isSaving: false);
      await load(page: state.pagination.page);
    } catch (e) {
      state = state.copyWith(isSaving: false, error: getApiErrorMessage(e));
    }
  }

  Future<void> selectSession(String sessionId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final session = await safeRequest(() => _api.getChatSession(sessionId));
      state = state.copyWith(selected: session, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getApiErrorMessage(e));
    }
  }

  Future<void> setSessionMode(String sessionId, String mode,
      {String? reason}) async {
    if (state.selected?.status == 'closed') return;
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await safeRequest(
        () => _api.updateChatSessionMode(sessionId, mode, reason: reason),
      );
      state = state.copyWith(isSaving: false);
      await selectSession(sessionId);
    } catch (e) {
      _saveError(e);
    }
  }

  Future<void> useGlobalMode(String sessionId) async {
    if (state.selected?.status == 'closed') return;
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await safeRequest(() => _api.useGlobalChatMode(sessionId));
      state = state.copyWith(isSaving: false);
      await selectSession(sessionId);
    } catch (e) {
      _saveError(e);
    }
  }

  Future<void> sendReply(String sessionId, String content) async {
    if (state.selected?.status == 'closed') {
      throw ApiException(
        'Session đã đóng, admin không thể trả lời.',
        code: 'CHAT_SESSION_CLOSED',
      );
    }
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await safeRequest(() => _api.sendAdminChatMessage(sessionId, content));
      state = state.copyWith(isSaving: false);
      await selectSession(sessionId);
    } catch (e) {
      _saveError(e);
      rethrow;
    }
  }

  Future<void> closeSession(String sessionId, {String? reason}) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await safeRequest(
        () => _api.closeChatSession(sessionId, reason: reason),
      );
      state = state.copyWith(isSaving: false);
      await selectSession(sessionId);
    } catch (e) {
      _saveError(e);
      rethrow;
    }
  }

  void _saveError(Object error) {
    final closed = error is ApiException && error.code == 'CHAT_SESSION_CLOSED';
    final selected = state.selected;
    state = state.copyWith(
      selected: closed && selected != null
          ? AdminChatSession(
              id: selected.id,
              title: selected.title,
              status: 'closed',
              mode: selected.mode,
              modeSource: selected.modeSource,
              effectiveMode: selected.effectiveMode,
              messages: selected.messages,
              user: selected.user,
              assignedAdminId: selected.assignedAdminId,
              unreadByAdmin: selected.unreadByAdmin,
              unreadByUser: selected.unreadByUser,
              lastMessage: selected.lastMessage,
              lastMessageAt: selected.lastMessageAt,
              manualReason: selected.manualReason,
            )
          : selected,
      isSaving: false,
      error: closed
          ? 'Session đã đóng, admin không thể thao tác.'
          : getApiErrorMessage(error),
    );
  }
}

final adminChatProvider =
    NotifierProvider<AdminChatNotifier, AdminChatState>(AdminChatNotifier.new);
