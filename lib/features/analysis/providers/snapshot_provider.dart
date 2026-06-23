import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_utils.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/app_api.dart';
import '../../../shared/models/app_models.dart';
import '../../auth/providers/auth_provider.dart';

class SnapshotState {
  const SnapshotState({
    this.snapshotsByRepoId = const {},
    this.loadingSnapshotsFor,
    this.comparingSnapshots = false,
    this.progressComparisonByRepoId = const {},
    this.error,
  });

  final Map<String, List<RepoAnalysisSnapshotModel>> snapshotsByRepoId;
  final String? loadingSnapshotsFor;
  final bool comparingSnapshots;
  final Map<String, SnapshotCompareResultModel> progressComparisonByRepoId;
  final String? error;

  bool isLoadingSnapshots(String repoId) => loadingSnapshotsFor == repoId;
  List<RepoAnalysisSnapshotModel> getSnapshots(String repoId) => snapshotsByRepoId[repoId] ?? [];
  SnapshotCompareResultModel? getProgressComparison(String repoId) => progressComparisonByRepoId[repoId];

  SnapshotState copyWith({
    Map<String, List<RepoAnalysisSnapshotModel>>? snapshotsByRepoId,
    String? loadingSnapshotsFor,
    bool clearLoadingSnapshotsFor = false,
    bool? comparingSnapshots,
    Map<String, SnapshotCompareResultModel>? progressComparisonByRepoId,
    String? error,
    bool clearError = false,
  }) {
    return SnapshotState(
      snapshotsByRepoId: snapshotsByRepoId ?? this.snapshotsByRepoId,
      loadingSnapshotsFor: clearLoadingSnapshotsFor ? null : (loadingSnapshotsFor ?? this.loadingSnapshotsFor),
      comparingSnapshots: comparingSnapshots ?? this.comparingSnapshots,
      progressComparisonByRepoId: progressComparisonByRepoId ?? this.progressComparisonByRepoId,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class SnapshotNotifier extends StateNotifier<SnapshotState> {
  SnapshotNotifier(this._api) : super(const SnapshotState());

  final AppApi _api;

  Future<void> fetchSnapshots(String repoId) async {
    if (state.isLoadingSnapshots(repoId)) return;
    state = state.copyWith(loadingSnapshotsFor: repoId, clearError: true);

    try {
      final snapshots = await safeRequest(() => _api.getSnapshots(repoId));
      if (!mounted) return;
      state = state.copyWith(
        snapshotsByRepoId: {
          ...state.snapshotsByRepoId,
          repoId: snapshots,
        },
        clearLoadingSnapshotsFor: true,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        error: getApiErrorMessage(e),
        clearLoadingSnapshotsFor: true,
      );
    }
  }

  Future<SnapshotCompareResultModel?> fetchProgressComparison(String repoId) async {
    state = state.copyWith(comparingSnapshots: true, clearError: true);
    try {
      final comparison = await safeRequest(() => _api.getProgressComparison(repoId));
      if (!mounted) return null;
      state = state.copyWith(
        progressComparisonByRepoId: {
          ...state.progressComparisonByRepoId,
          repoId: comparison,
        },
        comparingSnapshots: false,
      );
      return comparison;
    } catch (e) {
      if (!mounted) return null;
      state = state.copyWith(
        error: getApiErrorMessage(e),
        comparingSnapshots: false,
      );
    }
    return null;
  }
}

final snapshotProvider = StateNotifierProvider<SnapshotNotifier, SnapshotState>((ref) {
  final api = ref.watch(appApiProvider);
  return SnapshotNotifier(api);
});
