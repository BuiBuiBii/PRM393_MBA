import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_utils.dart';
import '../../../core/network/dio_client.dart';
import '../data/admin_api.dart';
import '../models/admin_models.dart';

final adminApiProvider = Provider<AdminApi>((ref) => AdminApi(ref.watch(dioProvider)));

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

final adminDashboardProvider = NotifierProvider<AdminDashboardNotifier, AdminDashboardState>(AdminDashboardNotifier.new);

class AdminListState<T> {
  const AdminListState({
    this.items = const [],
    this.pagination = const AdminPagination(page: 1, limit: 20, total: 0, totalPages: 0),
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

class AdminUsersNotifier extends Notifier<AdminListState<AdminUserRecord>> with AdminPagedListMixin<AdminUserRecord> {
  @override
  late final AdminApi adminApi;

  @override
  AdminListState<AdminUserRecord> build() {
    adminApi = ref.read(adminApiProvider);
    return const AdminListState();
  }

  Future<void> load({int page = 1, String? search, String? role, String? status}) => loadPaged(
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

final adminUsersProvider = NotifierProvider<AdminUsersNotifier, AdminListState<AdminUserRecord>>(AdminUsersNotifier.new);

class AdminReportsNotifier extends Notifier<AdminListState<AdminReportRecord>> with AdminPagedListMixin<AdminReportRecord> {
  @override
  late final AdminApi adminApi;

  @override
  AdminListState<AdminReportRecord> build() {
    adminApi = ref.read(adminApiProvider);
    return const AdminListState();
  }

  Future<void> load({int page = 1, String? status, String? targetType}) => loadPaged(
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

final adminReportsProvider = NotifierProvider<AdminReportsNotifier, AdminListState<AdminReportRecord>>(AdminReportsNotifier.new);

class AdminReposNotifier extends Notifier<AdminListState<AdminRepoRecord>> with AdminPagedListMixin<AdminRepoRecord> {
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
        fetch: () => adminApi.getRepositories(page: page, limit: AdminPagedListMixin.limit, search: search),
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

final adminReposProvider = NotifierProvider<AdminReposNotifier, AdminListState<AdminRepoRecord>>(AdminReposNotifier.new);

class AdminAnalysisNotifier extends Notifier<AdminListState<AdminAnalysisRecord>> with AdminPagedListMixin<AdminAnalysisRecord> {
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
        fetch: () => adminApi.getAnalyses(page: page, limit: AdminPagedListMixin.limit, search: search),
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

final adminAnalysisProvider =
    NotifierProvider<AdminAnalysisNotifier, AdminListState<AdminAnalysisRecord>>(AdminAnalysisNotifier.new);

class AdminFeedbackNotifier extends Notifier<AdminListState<AdminFeedbackRecord>> with AdminPagedListMixin<AdminFeedbackRecord> {
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
        fetch: () => adminApi.getAiFeedback(page: page, limit: AdminPagedListMixin.limit, search: search),
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

final adminFeedbackProvider =
    NotifierProvider<AdminFeedbackNotifier, AdminListState<AdminFeedbackRecord>>(AdminFeedbackNotifier.new);

class AdminRoadmapsNotifier extends Notifier<AdminListState<AdminRoadmapRecord>> with AdminPagedListMixin<AdminRoadmapRecord> {
  @override
  late final AdminApi adminApi;

  @override
  AdminListState<AdminRoadmapRecord> build() {
    adminApi = ref.read(adminApiProvider);
    return const AdminListState();
  }

  Future<void> load({int page = 1, String? search, String? status}) => loadPaged(
        page: page,
        search: search,
        filter: status,
        fetch: () => adminApi.getRoadmaps(page: page, limit: AdminPagedListMixin.limit, search: search, status: status),
      );

  Future<void> nextPage() {
    if (!state.pagination.hasNext) return Future.value();
    return load(page: state.pagination.page + 1, search: state.search, status: state.filter);
  }

  Future<void> prevPage() {
    if (!state.pagination.hasPrev) return Future.value();
    return load(page: state.pagination.page - 1, search: state.search, status: state.filter);
  }
}

final adminRoadmapsProvider =
    NotifierProvider<AdminRoadmapsNotifier, AdminListState<AdminRoadmapRecord>>(AdminRoadmapsNotifier.new);

class AdminRoadmapDetailState {
  const AdminRoadmapDetailState({this.roadmap, this.isLoading = false, this.error, this.isSaving = false});

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
      final roadmap = await safeRequest(() => _api.updateRoadmapStatus(roadmapId, status));
      state = AdminRoadmapDetailState(roadmap: roadmap);
    } catch (e) {
      state = AdminRoadmapDetailState(roadmap: state.roadmap, error: getApiErrorMessage(e));
    }
  }
}

final adminRoadmapDetailProvider =
    NotifierProvider<AdminRoadmapDetailNotifier, AdminRoadmapDetailState>(AdminRoadmapDetailNotifier.new);

class AdminAnalysisDetailState {
  const AdminAnalysisDetailState({this.analysis, this.isLoading = false, this.error});

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
    NotifierProvider<AdminAnalysisDetailNotifier, AdminAnalysisDetailState>(AdminAnalysisDetailNotifier.new);

class AdminFeedbackDetailState {
  const AdminFeedbackDetailState({this.feedback, this.isLoading = false, this.error});

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
      final feedback = await safeRequest(() => _api.getAiFeedbackDetail(feedbackId));
      state = AdminFeedbackDetailState(feedback: feedback);
    } catch (e) {
      state = AdminFeedbackDetailState(error: getApiErrorMessage(e));
    }
  }
}

final adminFeedbackDetailProvider =
    NotifierProvider<AdminFeedbackDetailNotifier, AdminFeedbackDetailState>(AdminFeedbackDetailNotifier.new);

class AdminRepoDetailState {
  const AdminRepoDetailState({this.repository, this.isLoading = false, this.error});

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
      final repository = await safeRequest(() => _api.getRepository(repositoryId));
      state = AdminRepoDetailState(repository: repository);
    } catch (e) {
      state = AdminRepoDetailState(error: getApiErrorMessage(e));
    }
  }
}

final adminRepoDetailProvider =
    NotifierProvider<AdminRepoDetailNotifier, AdminRepoDetailState>(AdminRepoDetailNotifier.new);

class AdminUserDetailState {
  const AdminUserDetailState({this.user, this.isLoading = false, this.error, this.isSaving = false});

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
      final user = await safeRequest(() => _api.updateUserStatus(userId, status));
      state = AdminUserDetailState(user: user);
    } catch (e) {
      state = AdminUserDetailState(user: state.user, error: getApiErrorMessage(e));
    }
  }

  Future<void> updateRole(String userId, String role) async {
    state = AdminUserDetailState(user: state.user, isSaving: true);
    try {
      final user = await safeRequest(() => _api.updateUserRole(userId, role));
      state = AdminUserDetailState(user: user);
    } catch (e) {
      state = AdminUserDetailState(user: state.user, error: getApiErrorMessage(e));
    }
  }
}

final adminUserDetailProvider = NotifierProvider<AdminUserDetailNotifier, AdminUserDetailState>(AdminUserDetailNotifier.new);

class AdminReportDetailState {
  const AdminReportDetailState({this.report, this.isLoading = false, this.error, this.isSaving = false});

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

  Future<void> updateStatus(String reportId, String status, {String? adminNote}) async {
    state = AdminReportDetailState(report: state.report, isSaving: true);
    try {
      final report = await safeRequest(() => _api.updateReportStatus(reportId, status: status, adminNote: adminNote));
      state = AdminReportDetailState(report: report);
    } catch (e) {
      state = AdminReportDetailState(report: state.report, error: getApiErrorMessage(e));
    }
  }
}

final adminReportDetailProvider =
    NotifierProvider<AdminReportDetailNotifier, AdminReportDetailState>(AdminReportDetailNotifier.new);
