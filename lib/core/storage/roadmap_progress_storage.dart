import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Lưu tiến độ node roadmap cục bộ (BE chưa có API cập nhật task status).
class RoadmapProgressStorage {
  RoadmapProgressStorage._(this._prefs);

  final SharedPreferences _prefs;

  static Future<RoadmapProgressStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return RoadmapProgressStorage._(prefs);
  }

  String _payloadKey(String userScope) => 'roadmap_local_progress_$userScope';

  Future<Map<String, dynamic>> _readPayload(String userScope) async {
    final raw = _prefs.getString(_payloadKey(userScope));
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v));
      }
    } catch (_) {}
    return {};
  }

  Future<void> _writePayload(String userScope, Map<String, dynamic> payload) async {
    await _prefs.setString(_payloadKey(userScope), jsonEncode(payload));
  }

  Future<Map<String, Map<String, String>>> loadNodeStatuses(String userScope) async {
    final payload = await _readPayload(userScope);
    final nodes = payload['nodes'];
    if (nodes is! Map) return {};

    final result = <String, Map<String, String>>{};
    nodes.forEach((roadmapId, nodeMap) {
      if (nodeMap is! Map) return;
      result[roadmapId.toString()] = nodeMap.map(
        (nodeId, status) => MapEntry(nodeId.toString(), status.toString()),
      );
    });
    return result;
  }

  Future<void> saveNodeStatus(
    String userScope,
    String roadmapId,
    String nodeId,
    String status,
  ) async {
    final payload = await _readPayload(userScope);
    final nodes = Map<String, dynamic>.from(payload['nodes'] is Map ? payload['nodes'] as Map : {});
    final roadmapNodes = Map<String, dynamic>.from(
      nodes[roadmapId] is Map ? nodes[roadmapId] as Map : {},
    );
    roadmapNodes[nodeId] = status;
    nodes[roadmapId] = roadmapNodes;
    payload['nodes'] = nodes;
    await _writePayload(userScope, payload);
  }

  Future<Set<String>> loadBookmarks(String userScope) async {
    final payload = await _readPayload(userScope);
    final raw = payload['bookmarks'];
    if (raw is! List) return {};
    return raw.map((e) => e.toString()).toSet();
  }

  Future<void> saveBookmarks(String userScope, Set<String> bookmarkIds) async {
    final payload = await _readPayload(userScope);
    payload['bookmarks'] = bookmarkIds.toList();
    await _writePayload(userScope, payload);
  }
}
