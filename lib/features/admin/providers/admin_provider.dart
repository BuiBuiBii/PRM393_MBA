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
  });

  final List<T> items;
  final AdminPagination pagination;
  final bool isLoading;
  final String? error;
  final String search;
  final String? filter;
}

mixin AdminPagedListMixin<T> on Notifier<AdminListState<T>> {
  AdminApi get adminApi;
  static const limit = 20;

  Future<void> loadPaged({
    required int page,
    required Future<AdminPage<T>> Function() fetch,
    String? search,
    String? filter,
  }) async {
    state = AdminListState<T>(
      items: state.items,
      pagination: state.pagination,
      isLoading: true,
      search: search ?? state.search,
      filter: filter ?? state.filter,
    );
    try {
      final pageData = await safeRequest(fetch);
      state = AdminListState(
        items: pageData.items,
        pagination: pageData.pagination,
        search: search ?? state.search,
        filter: filter ?? state.filter,
      );
    } catch (e) {
      state = AdminListState(
        items: state.items,
        pagination: state.pagination,
        isLoading: false,
        error: getApiErrorMessage(e),
        search: search ?? state.search,
        filter: filter ?? state.filter,
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

  Future<void> load({int page = 1, String? search, String? role}) => loadPaged(
        page: page,
        search: search,
        filter: role,
        fetch: () => adminApi.getUsers(page: page, limit: AdminPagedListMixin.limit, search: search, role: role),
      );

  Future<void> nextPage() {
    if (!state.pagination.hasNext) return Future.value();
    return load(page: state.pagination.page + 1, search: state.search, role: state.filter);
  }

  Future<void> prevPage() {
    if (!state.pagination.hasPrev) return Future.value();
    return load(page: state.pagination.page - 1, search: state.search, role: state.filter);
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
