import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_api.dart';
import '../../../core/network/app_api_provider.dart';
import '../../../shared/models/app_models.dart';

/// Tầng data — tách API khỏi UI/Notifier (tiêu chí tách logic).
class RepositoryRepository {
  RepositoryRepository(this._api);

  final AppApi _api;

  Future<List<RepositoryModel>> syncRepositories() => _api.syncRepositories();

  Future<List<RepositoryModel>> getCachedRepositories() => _api.getCachedRepositories();

  Future<List<AnalysisModel>> getMyAnalyses() => _api.getMyAnalyses();

  Future<RepositoryModel> getRepository(String id) => _api.getRepository(id);

  Future<AnalysisModel> analyzeRepository(String id) => _api.analyzeRepository(id);

  Future<AnalysisModel?> getAnalysis(String id) => _api.getAnalysis(id);

  Future<RoleMatchModel?> calculateRoleMatches({
    required String sourceMode,
    String? repoId,
    List<String>? repoIds,
    int limit = 3,
  }) =>
      _api.calculateRoleMatches(
        sourceMode: sourceMode,
        repoId: repoId,
        repoIds: repoIds,
        limit: limit,
      );

  Future<RoleMatchModel?> getRoleMatches(
    String repoId, {
    int limit = 3,
    bool includeDetails = true,
  }) =>
      _api.getRoleMatches(repoId, limit: limit, includeDetails: includeDetails);

  Future<AiFeedbackModel?> getAiFeedback(String repoId) => _api.getAiFeedback(repoId);

  Future<List<AiFeedbackModel>> getMyAiFeedback() => _api.getMyAiFeedback();

  Future<AiFeedbackModel> generateAiFeedback(String repoId) => _api.generateAiFeedback(repoId);

  Future<List<dynamic>> syncPackages(String id) => _api.syncPackages(id);

  Future<List<dynamic>> getCachedPackages(String id) => _api.getCachedPackages(id);

  Future<List<dynamic>> syncCommits(String id) => _api.syncCommits(id);

  Future<List<dynamic>> getCachedCommits(String id) => _api.getCachedCommits(id);
}

final repositoryRepositoryProvider = Provider<RepositoryRepository>(
  (ref) => RepositoryRepository(ref.read(appApiProvider)),
);
