import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/dev2vec_roles.dart';
import '../../../core/network/app_api_provider.dart';

/// Catalog role Dev2Vec từ API — không fallback hard-code.
final roleCatalogProvider = FutureProvider<List<Dev2VecRole>>((ref) async {
  if (AppConfig.demoMode) return Dev2VecRole.catalog;

  final roles = await ref.read(appApiProvider).getRoleCatalog();
  if (roles.isEmpty) {
    throw StateError('API /roles/catalog trả về rỗng');
  }
  return roles;
});

/// Resolve roleId từ catalog API (nếu đã load).
String resolveDev2VecRoleId({
  required String? roleId,
  required String roleName,
  List<Dev2VecRole>? catalog,
}) {
  final trimmedId = roleId?.trim() ?? '';
  if (trimmedId.isNotEmpty) return trimmedId;

  final fromCatalog = catalog?.findByName(roleName)?.id;
  if (fromCatalog != null && fromCatalog.isNotEmpty) return fromCatalog;

  return roleName.trim();
}

extension Dev2VecRoleListLookup on List<Dev2VecRole> {
  Dev2VecRole? findById(String? roleId) {
    if (roleId == null || roleId.isEmpty) return null;
    for (final role in this) {
      if (role.id == roleId) return role;
    }
    return null;
  }

  Dev2VecRole? findByName(String? name) {
    if (name == null || name.isEmpty) return null;
    for (final role in this) {
      if (role.name == name) return role;
    }
    return null;
  }
}
