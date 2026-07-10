/// Tham số tạo roadmap — tách khỏi UI (tiêu chí tách logic).
class RoadmapGenerateParams {
  const RoadmapGenerateParams({
    required this.roleId,
    required this.targetRole,
    this.sourceMode = 'single_repo',
    this.repoId,
    this.repoIds,
    this.level = 'beginner',
    this.durationWeeks = 6,
    this.language = 'vi',
    this.forceRegenerate = false,
  });

  final String roleId;
  final String targetRole;
  final String sourceMode;
  final String? repoId;
  final List<String>? repoIds;
  final String level;
  final int durationWeeks;
  final String language;
  final bool forceRegenerate;

  Map<String, dynamic> toJson() => {
        'roleId': roleId,
        'targetRole': targetRole,
        'sourceMode': sourceMode,
        if (repoId != null && repoId!.isNotEmpty) 'repoId': repoId,
        if (repoIds != null && repoIds!.isNotEmpty) 'repoIds': repoIds,
        'level': level,
        'durationWeeks': durationWeeks,
        'language': language,
        'useRoleMatching': true,
        'forceRegenerate': forceRegenerate,
      };
}
