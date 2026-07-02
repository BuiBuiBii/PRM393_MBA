Map<String, dynamic> _mapOf(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, value) => MapEntry(key.toString(), value));
  return {};
}

List<Map<String, dynamic>> _mapListOf(dynamic value) {
  if (value is! List) return const [];
  return value.whereType<Map>().map((e) => _mapOf(e)).toList();
}

List<String> _stringListOf(dynamic value) {
  if (value is! List) return const [];
  return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
}

int _intOf(dynamic value, [int fallback = 0]) => int.tryParse(value?.toString() ?? '') ?? fallback;

double _doubleOf(dynamic value, [double fallback = 0]) => double.tryParse(value?.toString() ?? '') ?? fallback;

class RepositoryModel {
  const RepositoryModel({
    required this.id,
    required this.name,
    required this.fullName,
    required this.language,
    required this.stars,
    required this.forks,
    required this.updatedAt,
    required this.hasReadme,
    required this.analyzed,
    required this.url,
    required this.private,
    this.description,
    this.analysisId,
  });

  final String id;
  final String name;
  final String fullName;
  final String? description;
  final String language;
  final int stars;
  final int forks;
  final String updatedAt;
  final bool hasReadme;
  final bool analyzed;
  final String? analysisId;
  final String url;
  final bool private;

  factory RepositoryModel.fromJson(Map<String, dynamic> json) {
    return RepositoryModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      fullName: (json['fullName'] ?? json['full_name'] ?? json['name'] ?? '').toString(),
      description: json['description']?.toString(),
      language: (json['language'] ?? 'Unknown').toString(),
      stars: int.tryParse(json['stars']?.toString() ?? '') ?? 0,
      forks: int.tryParse(json['forks']?.toString() ?? '') ?? 0,
      updatedAt: (json['updatedAt'] ?? json['updated_at'] ?? '').toString(),
      hasReadme: json['hasReadme'] == true || json['has_readme'] == true,
      analyzed: json['analyzed'] == true,
      analysisId: json['analysisId']?.toString(),
      url: (json['url'] ?? json['html_url'] ?? '').toString(),
      private: json['private'] == true,
    );
  }
}

class AnalysisScores {
  const AnalysisScores({
    required this.architecture,
    required this.completeness,
    required this.commitQuality,
    required this.documentation,
    required this.codeConvention,
    required this.overall,
  });

  final int architecture;
  final int completeness;
  final int commitQuality;
  final int documentation;
  final int codeConvention;
  final int overall;

  factory AnalysisScores.fromJson(Map<String, dynamic>? json) {
    json ??= {};
    int pick(List<String> keys) {
      for (final key in keys) {
        final v = json![key];
        if (v != null) return int.tryParse(v.toString()) ?? 0;
      }
      return 0;
    }

    return AnalysisScores(
      architecture: pick(['architecture', 'architectureScore']),
      completeness: pick(['completeness', 'completenessScore']),
      commitQuality: pick(['commitQuality', 'commitQualityScore']),
      documentation: pick(['documentation', 'documentationScore']),
      codeConvention: pick(['codeConvention', 'codeConventionScore']),
      overall: pick(['overall', 'overallScore']),
    );
  }
}

class AnalysisModel {
  const AnalysisModel({
    required this.id,
    required this.repositoryId,
    required this.repositoryName,
    required this.createdAt,
    required this.projectType,
    required this.techStack,
    required this.scores,
    required this.strengths,
    required this.weaknesses,
    required this.recommendations,
    this.careerDirection,
    this.analysisId,
    this.snapshotId,
    this.repository,
    this.analysisScope,
    this.summary,
    this.topSkillItems = const [],
    this.missingSkillItems = const [],
    this.analyzedAt,
  });

  final String id;
  final String repositoryId;
  final String repositoryName;
  final String createdAt;
  final String projectType;
  final List<String> techStack;
  final AnalysisScores scores;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> recommendations;
  final String? careerDirection;
  final String? analysisId;
  final String? snapshotId;
  final AnalysisRepositoryInfo? repository;
  final AnalysisScopeInfo? analysisScope;
  final AnalysisSummaryInfo? summary;
  final List<AnalysisSkillModel> topSkillItems;
  final List<AnalysisSkillModel> missingSkillItems;
  final String? analyzedAt;

  factory AnalysisModel.fromJson(Map<String, dynamic> json) {
    final repository = AnalysisRepositoryInfo.fromJson(_mapOf(json['repository']));
    final scope = AnalysisScopeInfo.fromJson(_mapOf(json['analysisScope']));
    final summary = AnalysisSummaryInfo.fromJson(_mapOf(json['summary']));
    final scoresJson = json['scores'] is Map ? _mapOf(json['scores']) : {
      ...json,
      'overallScore': summary.overallScore ?? summary.userReadinessScore,
    };
    final topSkills = _mapListOf(json['topSkills'] ?? json['topSkillItems'])
        .map(AnalysisSkillModel.fromJson)
        .toList();
    final missingSkills = _mapListOf(json['missingSkills'] ?? json['missingSkillItems'])
        .map(AnalysisSkillModel.fromJson)
        .toList();
    return AnalysisModel(
      id: (json['analysisId'] ?? json['id'] ?? json['_id'] ?? '').toString(),
      repositoryId: (repository.repositoryId ?? json['repositoryId'] ?? json['repoId'] ?? '').toString(),
      repositoryName: (repository.repoName ?? repository.fullName ?? json['repositoryName'] ?? json['repoName'] ?? json['fullName'] ?? 'Repository').toString(),
      createdAt: (json['createdAt'] ?? DateTime.now().toIso8601String()).toString(),
      projectType: (summary.projectType ?? json['projectType'] ?? 'Unknown').toString(),
      techStack: (json['techStack'] as List? ?? json['languages'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      scores: AnalysisScores.fromJson(scoresJson),
      strengths: (json['strengths'] as List? ?? []).map((e) => e.toString()).toList(),
      weaknesses: (json['weaknesses'] as List? ?? []).map((e) => e.toString()).toList(),
      recommendations: (json['recommendations'] as List? ?? [])
          .map((e) => e is Map ? (e['title'] ?? e['description'] ?? '').toString() : e.toString())
          .where((e) => e.isNotEmpty)
          .toList(),
      careerDirection: summary.careerDirection ?? (json['careerDirection'] is Map
          ? (json['careerDirection'] as Map)['primary']?.toString()
          : json['careerDirection']?.toString()),
      analysisId: json['analysisId']?.toString(),
      snapshotId: json['snapshotId']?.toString(),
      repository: repository.hasData ? repository : null,
      analysisScope: scope.hasData ? scope : null,
      summary: summary.hasData ? summary : null,
      topSkillItems: topSkills,
      missingSkillItems: missingSkills,
      analyzedAt: json['analyzedAt']?.toString(),
    );
  }
}

class AnalysisRepositoryInfo {
  const AnalysisRepositoryInfo({this.repositoryId, this.githubRepoId, this.repoName, this.fullName});
  final String? repositoryId;
  final String? githubRepoId;
  final String? repoName;
  final String? fullName;
  bool get hasData => [repositoryId, githubRepoId, repoName, fullName].any((e) => e != null && e!.isNotEmpty);
  factory AnalysisRepositoryInfo.fromJson(Map<String, dynamic> json) => AnalysisRepositoryInfo(
        repositoryId: json['repositoryId']?.toString(),
        githubRepoId: json['githubRepoId']?.toString(),
        repoName: json['repoName']?.toString(),
        fullName: json['fullName']?.toString(),
      );
}

class AnalysisScopeInfo {
  const AnalysisScopeInfo({this.type, this.githubUsername, this.totalRepoCommits, this.userCommits, this.activeDays, this.firstCommitDate, this.lastCommitDate});
  final String? type;
  final String? githubUsername;
  final int? totalRepoCommits;
  final int? userCommits;
  final int? activeDays;
  final String? firstCommitDate;
  final String? lastCommitDate;
  bool get hasData => type != null || githubUsername != null || totalRepoCommits != null || userCommits != null || activeDays != null;
  factory AnalysisScopeInfo.fromJson(Map<String, dynamic> json) => AnalysisScopeInfo(
        type: json['type']?.toString(),
        githubUsername: json['githubUsername']?.toString(),
        totalRepoCommits: json.containsKey('totalRepoCommits') ? _intOf(json['totalRepoCommits']) : null,
        userCommits: json.containsKey('userCommits') ? _intOf(json['userCommits']) : null,
        activeDays: json.containsKey('activeDays') ? _intOf(json['activeDays']) : null,
        firstCommitDate: json['firstCommitDate']?.toString(),
        lastCommitDate: json['lastCommitDate']?.toString(),
      );
}

class AnalysisSummaryInfo {
  const AnalysisSummaryInfo({this.careerDirection, this.userLevel, this.userReadinessScore, this.overallScore, this.projectType, this.confidence});
  final String? careerDirection;
  final String? userLevel;
  final double? userReadinessScore;
  final double? overallScore;
  final String? projectType;
  final double? confidence;
  bool get hasData => [careerDirection, userLevel, projectType].any((e) => e != null && e!.isNotEmpty) || userReadinessScore != null || overallScore != null || confidence != null;
  factory AnalysisSummaryInfo.fromJson(Map<String, dynamic> json) => AnalysisSummaryInfo(
        careerDirection: json['careerDirection']?.toString(),
        userLevel: json['userLevel']?.toString(),
        userReadinessScore: json.containsKey('userReadinessScore') ? _doubleOf(json['userReadinessScore']) : null,
        overallScore: json.containsKey('overallScore') ? _doubleOf(json['overallScore']) : null,
        projectType: json['projectType']?.toString(),
        confidence: json.containsKey('confidence') ? _doubleOf(json['confidence']) : null,
      );
}

class AnalysisSkillModel {
  const AnalysisSkillModel({this.skill, this.canonicalSkillName, this.category, this.score, this.level, this.priority});
  final String? skill;
  final String? canonicalSkillName;
  final String? category;
  final double? score;
  final String? level;
  final String? priority;
  String get displayName {
    if ((canonicalSkillName ?? '').isNotEmpty) return canonicalSkillName!;
    if ((skill ?? '').isNotEmpty) return skill!;
    return 'Khong ro ky nang';
  }
  factory AnalysisSkillModel.fromJson(Map<String, dynamic> json) => AnalysisSkillModel(
        skill: json['skill']?.toString(),
        canonicalSkillName: json['canonicalSkillName']?.toString(),
        category: json['category']?.toString(),
        score: json.containsKey('score') ? _doubleOf(json['score']) : null,
        level: json['level']?.toString(),
        priority: json['priority']?.toString(),
      );
}

class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.senderType,
  });

  final String id;
  final String role;
  final String content;
  final String timestamp;
  final String? senderType;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final senderType = json['senderType']?.toString();
    return ChatMessageModel(
      id: (json['id'] ?? json['_id'] ?? DateTime.now().millisecondsSinceEpoch).toString(),
      role: (json['role'] ?? (senderType == 'USER' ? 'user' : 'assistant')).toString(),
      content: (json['content'] ?? json['message'] ?? '').toString(),
      timestamp: (json['timestamp'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()).toString(),
      senderType: senderType,
    );
  }
}

class ChatSessionModel {
  const ChatSessionModel({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.messages,
    this.repositoryContext,
    this.mode,
    this.effectiveMode,
    this.modeSource,
    this.status,
  });

  final String id;
  final String title;
  final String createdAt;
  final List<ChatMessageModel> messages;
  final String? repositoryContext;
  final String? mode;
  final String? effectiveMode;
  final String? modeSource;
  final String? status;

  bool get isWaitingAdmin => status == 'waiting_admin' || effectiveMode == 'MANUAL';

  ChatSessionModel copyWith({
    List<ChatMessageModel>? messages,
    String? mode,
    String? effectiveMode,
    String? modeSource,
    String? status,
  }) {
    return ChatSessionModel(
      id: id,
      title: title,
      createdAt: createdAt,
      messages: messages ?? this.messages,
      repositoryContext: repositoryContext,
      mode: mode ?? this.mode,
      effectiveMode: effectiveMode ?? this.effectiveMode,
      modeSource: modeSource ?? this.modeSource,
      status: status ?? this.status,
    );
  }

  factory ChatSessionModel.fromJson(Map<String, dynamic> json) {
    return ChatSessionModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? json['name'] ?? 'Cuộc trò chuyện mới').toString(),
      createdAt: (json['createdAt'] ?? DateTime.now().toIso8601String()).toString(),
      repositoryContext: json['repositoryContext']?.toString(),
      mode: json['mode']?.toString(),
      effectiveMode: json['effectiveMode']?.toString(),
      modeSource: json['modeSource']?.toString(),
      status: json['status']?.toString(),
      messages: (json['messages'] as List? ?? [])
          .whereType<Map>()
          .map((e) => ChatMessageModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.read,
    this.createdAt,
  });

  final String id;
  final String title;
  final String message;
  final String type;
  final bool read;
  final String? createdAt;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      type: (json['type'] ?? 'SYSTEM').toString(),
      read: json['read'] == true || json['isRead'] == true,
      createdAt: json['createdAt']?.toString(),
    );
  }
}

class AiFeedbackModel {
  const AiFeedbackModel({
    required this.id,
    required this.repositoryId,
    required this.repositoryName,
    required this.summary,
    required this.strengthFeedback,
    required this.weaknessFeedback,
    required this.learningAdvice,
    required this.nextSteps,
    required this.recommendedTopics,
    this.careerSuggestion,
    this.portfolioAdvice,
    this.generatedAt,
  });

  final String id;
  final String repositoryId;
  final String repositoryName;
  final String summary;
  final List<String> strengthFeedback;
  final List<String> weaknessFeedback;
  final String learningAdvice;
  final List<String> nextSteps;
  final List<String> recommendedTopics;
  final String? careerSuggestion;
  final String? portfolioAdvice;
  final String? generatedAt;

  factory AiFeedbackModel.fromJson(Map<String, dynamic> json) {
    List<String> listOf(dynamic value) {
      if (value is List) return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      return [];
    }

    return AiFeedbackModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      repositoryId: _refId(json['repositoryId']),
      repositoryName: (json['repoName'] ??
              json['fullName'] ??
              json['repositoryName'] ??
              _refName(json['repositoryId']) ??
              'Repository')
          .toString(),
      summary: (json['summary'] ?? '').toString(),
      strengthFeedback: listOf(json['strengthFeedback']),
      weaknessFeedback: listOf(json['weaknessFeedback']),
      learningAdvice: (json['learningAdvice'] ?? '').toString(),
      nextSteps: listOf(json['nextSteps']),
      recommendedTopics: listOf(json['recommendedTopics']),
      careerSuggestion: json['careerSuggestion']?.toString(),
      portfolioAdvice: json['portfolioAdvice']?.toString(),
      generatedAt: (json['generatedAt'] ?? json['createdAt'])?.toString(),
    );
  }

  AiFeedbackModel copyWithRepositoryId(String repositoryId) {
    return AiFeedbackModel(
      id: id,
      repositoryId: repositoryId,
      repositoryName: repositoryName,
      summary: summary,
      strengthFeedback: strengthFeedback,
      weaknessFeedback: weaknessFeedback,
      learningAdvice: learningAdvice,
      nextSteps: nextSteps,
      recommendedTopics: recommendedTopics,
      careerSuggestion: careerSuggestion,
      portfolioAdvice: portfolioAdvice,
      generatedAt: generatedAt,
    );
  }

  static String _refId(dynamic value) {
    if (value is Map) return (value['_id'] ?? value['id'] ?? '').toString();
    return (value ?? '').toString();
  }

  static String? _refName(dynamic value) {
    if (value is! Map) return null;
    return (value['fullName'] ?? value['name'] ?? value['repoName'])?.toString();
  }
}

class ProfileModel {
  const ProfileModel({
    required this.fullName,
    required this.university,
    required this.major,
    required this.year,
    required this.targetCareer,
    required this.currentSkills,
    this.githubUsername,
  });

  final String fullName;
  final String university;
  final String major;
  final int year;
  final String targetCareer;
  final List<String> currentSkills;
  final String? githubUsername;

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      fullName: (json['fullName'] ?? json['name'] ?? '').toString(),
      university: (json['university'] ?? '').toString(),
      major: (json['major'] ?? '').toString(),
      year: int.tryParse(json['year']?.toString() ?? '') ?? 1,
      targetCareer: (json['targetCareer'] ?? '').toString(),
      currentSkills: (json['currentSkills'] as List? ?? []).map((e) => e.toString()).toList(),
      githubUsername: json['githubUsername']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'university': university,
        'major': major,
        'year': year,
        'targetCareer': targetCareer,
        'currentSkills': currentSkills,
        if (githubUsername != null) 'githubUsername': githubUsername,
      };
}

class LearningNodeModel {
  const LearningNodeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.estimatedHours,
    required this.difficulty,
    required this.status,
    required this.skills,
    required this.xp,
    this.bookmarked = false,
    this.skillName,
    this.canonicalSkillName,
    this.targetRole,
    this.category,
    this.priority,
    this.itemId,
    this.week,
    this.resources = const [],
  });

  final String id;
  final String title;
  final String description;
  final int estimatedHours;
  final String difficulty;
  final String status;
  final List<String> skills;
  final int xp;
  final bool bookmarked;
  // New fields from role-matching roadmap
  final String? skillName;
  final String? canonicalSkillName;
  final String? targetRole;
  final String? category;
  final dynamic priority;
  final String? itemId;
  final int? week;
  final List<dynamic> resources;

  LearningNodeModel copyWith({String? status, bool? bookmarked}) {
    return LearningNodeModel(
      id: id,
      title: title,
      description: description,
      estimatedHours: estimatedHours,
      difficulty: difficulty,
      status: status ?? this.status,
      skills: skills,
      xp: xp,
      bookmarked: bookmarked ?? this.bookmarked,
      skillName: skillName,
      canonicalSkillName: canonicalSkillName,
      targetRole: targetRole,
      category: category,
      priority: priority,
      itemId: itemId,
      week: week,
      resources: resources,
    );
  }
}

class RoadmapModuleModel {
  const RoadmapModuleModel({
    required this.id,
    required this.title,
    required this.description,
    required this.nodes,
  });

  final String id;
  final String title;
  final String description;
  final List<LearningNodeModel> nodes;
}

class SupportingPathModel {
  const SupportingPathModel({
    required this.id,
    required this.title,
    required this.reason,
    required this.skills,
    required this.suggestedTasks,
  });

  final String id;
  final String title;
  final String reason;
  final List<String> skills;
  final List<String> suggestedTasks;

  factory SupportingPathModel.fromJson(Map<String, dynamic> json) {
    return SupportingPathModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      reason: (json['reason'] ?? '').toString(),
      skills: (json['skills'] as List? ?? []).map((e) => e.toString()).toList(),
      suggestedTasks: (json['suggestedTasks'] as List? ?? []).map((e) => e.toString()).toList(),
    );
  }
}

class RoadmapModel {
  const RoadmapModel({
    required this.id,
    required this.slug,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.estimatedWeeks,
    required this.estimatedHours,
    required this.tags,
    required this.isFeatured,
    required this.isAIRecommended,
    required this.progress,
    required this.modules,
    required this.careerOutcome,
    this.status = 'active',
    this.detectedSkills,
    this.repositoriesCount = 0,
    this.objectives = const [],
    this.requiredSkills = const [],
    this.missingSkills = const [],
    this.supportingPaths = const [],
    this.sourceRepositoriesCount = 0,
    // New metadata fields
    this.roadmapSource,
    this.roadmapSourceInfo,
    this.roleMatchInfo,
    this.skillGapSummary,
    this.roadmapId,
    this.roleId,
    this.requestedLevel,
    this.effectiveLevel,
    this.language,
    this.mainRoadmap,
    this.alternativeRoadmaps = const [],
    this.progressSummary,
  });

  final String id;
  final String slug;
  final String title;
  final String subtitle;
  final String description;
  final String category;
  final String difficulty;
  final int estimatedWeeks;
  final int estimatedHours;
  final List<String> tags;
  final bool isFeatured;
  final bool isAIRecommended;
  final int progress;
  final List<RoadmapModuleModel> modules;
  final String careerOutcome;
  final String status;
  final List<String>? detectedSkills;
  final int repositoriesCount;
  final List<String> objectives;
  final List<String> requiredSkills;
  final List<String> missingSkills;
  final List<SupportingPathModel> supportingPaths;
  final int sourceRepositoriesCount;
  // New metadata
  final String? roadmapSource;
  final RoadmapSourceInfo? roadmapSourceInfo;
  final Map<String, dynamic>? roleMatchInfo;
  final Map<String, dynamic>? skillGapSummary;
  final String? roadmapId;
  final String? roleId;
  final String? requestedLevel;
  final String? effectiveLevel;
  final String? language;
  final RoadmapPathModel? mainRoadmap;
  final List<RoadmapPathModel> alternativeRoadmaps;
  final RoadmapProgressSummary? progressSummary;

  bool get isArchived => status == 'archived';

  /// Convenience: recommended next skills from skillGapSummary
  List<String> get recommendedNextSkills {
    final raw = skillGapSummary?['recommendedNextSkills'];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return const [];
  }

  /// Convenience: priority skills from skillGapSummary
  List<String> get prioritySkills {
    final raw = skillGapSummary?['prioritySkills'];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return const [];
  }

  RoadmapModel copyWith({
    List<RoadmapModuleModel>? modules,
    int? progress,
    String? status,
  }) {
    return RoadmapModel(
      id: id,
      slug: slug,
      title: title,
      subtitle: subtitle,
      description: description,
      category: category,
      difficulty: difficulty,
      estimatedWeeks: estimatedWeeks,
      estimatedHours: estimatedHours,
      tags: tags,
      isFeatured: isFeatured,
      isAIRecommended: isAIRecommended,
      progress: progress ?? this.progress,
      modules: modules ?? this.modules,
      careerOutcome: careerOutcome,
      status: status ?? this.status,
      detectedSkills: detectedSkills,
      repositoriesCount: repositoriesCount,
      objectives: objectives,
      requiredSkills: requiredSkills,
      missingSkills: missingSkills,
      supportingPaths: supportingPaths,
      sourceRepositoriesCount: sourceRepositoriesCount,
      roadmapSource: roadmapSource,
      roadmapSourceInfo: roadmapSourceInfo,
      roleMatchInfo: roleMatchInfo,
      skillGapSummary: skillGapSummary,
      roadmapId: roadmapId,
      roleId: roleId,
      requestedLevel: requestedLevel,
      effectiveLevel: effectiveLevel,
      language: language,
      mainRoadmap: mainRoadmap,
      alternativeRoadmaps: alternativeRoadmaps,
      progressSummary: progressSummary,
    );
  }
}

class RoadmapPathModel {
  const RoadmapPathModel({this.title, this.targetRole, this.reason, this.phases = const []});
  final String? title;
  final String? targetRole;
  final String? reason;
  final List<Map<String, dynamic>> phases;
  factory RoadmapPathModel.fromJson(Map<String, dynamic> json) => RoadmapPathModel(
        title: json['title']?.toString(),
        targetRole: json['targetRole']?.toString(),
        reason: json['reason']?.toString(),
        phases: _mapListOf(json['phases']),
      );
}

class RoadmapSourceInfo {
  const RoadmapSourceInfo({
    this.type,
    this.sourceMode,
    this.analysisId,
    this.snapshotId,
    this.repositoryId,
    this.repoName,
    this.fullName,
    this.githubUsername,
    this.totalRepoCommits,
    this.userCommits,
    this.totalUserCommits,
    this.activeDays,
    this.userLevel,
    this.userReadinessScore,
    this.careerDirection,
    this.projectType,
    this.repositories = const [],
    this.analysisIds = const [],
    this.repositoryIds = const [],
  });
  final String? type;
  final String? sourceMode;
  final String? analysisId;
  final String? snapshotId;
  final String? repositoryId;
  final String? repoName;
  final String? fullName;
  final String? githubUsername;
  final int? totalRepoCommits;
  final int? userCommits;
  final int? totalUserCommits;
  final int? activeDays;
  final String? userLevel;
  final double? userReadinessScore;
  final String? careerDirection;
  final String? projectType;
  final List<Map<String, dynamic>> repositories;
  final List<String> analysisIds;
  final List<String> repositoryIds;
  factory RoadmapSourceInfo.fromJson(Map<String, dynamic> json) => RoadmapSourceInfo(
        type: json['type']?.toString(),
        sourceMode: json['sourceMode']?.toString(),
        analysisId: json['analysisId']?.toString(),
        snapshotId: json['snapshotId']?.toString(),
        repositoryId: json['repositoryId']?.toString(),
        repoName: json['repoName']?.toString(),
        fullName: json['fullName']?.toString(),
        githubUsername: json['githubUsername']?.toString(),
        totalRepoCommits: json.containsKey('totalRepoCommits') ? _intOf(json['totalRepoCommits']) : null,
        userCommits: json.containsKey('userCommits') ? _intOf(json['userCommits']) : null,
        totalUserCommits: json.containsKey('totalUserCommits') ? _intOf(json['totalUserCommits']) : null,
        activeDays: json.containsKey('activeDays') ? _intOf(json['activeDays']) : null,
        userLevel: json['userLevel']?.toString(),
        userReadinessScore: json.containsKey('userReadinessScore') ? _doubleOf(json['userReadinessScore']) : null,
        careerDirection: json['careerDirection']?.toString(),
        projectType: json['projectType']?.toString(),
        repositories: _mapListOf(json['repositories']),
        analysisIds: _stringListOf(json['analysisIds']),
        repositoryIds: _stringListOf(json['repositoryIds']),
      );
}

class SkillProgressModel {
  const SkillProgressModel({
    required this.skill,
    required this.category,
    required this.current,
    required this.target,
  });

  final String skill;
  final String category;
  final int current;
  final int target;
}

class LearningStatsModel {
  const LearningStatsModel({
    required this.activeRoadmapIds,
    required this.completedNodes,
    required this.totalNodes,
    required this.totalXp,
    required this.level,
    required this.currentStreak,
    required this.weeklyGoalHours,
    required this.weeklyHoursCompleted,
    required this.bookmarkedNodeIds,
  });

  final List<String> activeRoadmapIds;
  final int completedNodes;
  final int totalNodes;
  final int totalXp;
  final int level;
  final int currentStreak;
  final int weeklyGoalHours;
  final int weeklyHoursCompleted;
  final List<String> bookmarkedNodeIds;

  LearningStatsModel copyWith({
    int? completedNodes,
    int? totalXp,
    List<String>? bookmarkedNodeIds,
  }) {
    return LearningStatsModel(
      activeRoadmapIds: activeRoadmapIds,
      completedNodes: completedNodes ?? this.completedNodes,
      totalNodes: totalNodes,
      totalXp: totalXp ?? this.totalXp,
      level: level,
      currentStreak: currentStreak,
      weeklyGoalHours: weeklyGoalHours,
      weeklyHoursCompleted: weeklyHoursCompleted,
      bookmarkedNodeIds: bookmarkedNodeIds ?? this.bookmarkedNodeIds,
    );
  }
}

class RoleMatchItem {
  const RoleMatchItem({
    required this.role,
    required this.description,
    required this.category,
    required this.matchScore,
    required this.matchLevel,
    required this.matchLevelLabel,
    required this.matchedSkills,
    required this.missingSkills,
    required this.recommendedNextSkills,
    this.roleId,
    this.roleName,
    this.weakSkillNames = const [],
    this.matchedSkillNames = const [],
    this.missingSkillNames = const [],
    this.weakSkills = const [],
    this.missingRequiredSkills = const [],
    this.missingOptionalSkills = const [],
  });

  final String role;
  final String? roleId;
  final String? roleName;
  final String description;
  final String category;
  final double matchScore;
  final String matchLevel;
  final String matchLevelLabel;
  final List<String> matchedSkills;
  final List<String> missingSkills;
  final List<String> recommendedNextSkills;
  final List<String> weakSkillNames;
  final List<String> matchedSkillNames;
  final List<String> missingSkillNames;
  final List<Map<String, dynamic>> weakSkills;
  final List<Map<String, dynamic>> missingRequiredSkills;
  final List<Map<String, dynamic>> missingOptionalSkills;

  String get displayRoleName {
    if ((roleName ?? '').isNotEmpty) return roleName!;
    if (role.isNotEmpty) return role;
    return 'Khong ro role';
  }

  factory RoleMatchItem.fromJson(Map<String, dynamic> json) {
    List<String> strList(dynamic v) => _stringListOf(v);
    final roleName = (json['roleName'] ?? json['role'] ?? json['targetRole'] ?? '').toString();
    return RoleMatchItem(
      role: roleName,
      roleId: json['roleId']?.toString(),
      roleName: json['roleName']?.toString(),
      description: (json['description'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      matchScore: double.tryParse(json['matchScore']?.toString() ?? '') ?? 0.0,
      matchLevel: (json['matchLevel'] ?? '').toString(),
      matchLevelLabel: (json['matchLevelLabel'] ?? json['matchLevel'] ?? '').toString(),
      matchedSkills: strList(json['matchedSkillNames'] ?? json['matchedSkills'] ?? json['topMatchedSkills']),
      missingSkills: strList(json['missingSkillNames'] ?? json['missingSkills'] ?? json['topMissingSkills']),
      recommendedNextSkills: strList(json['recommendedNextSkills']),
      matchedSkillNames: strList(json['matchedSkillNames']),
      weakSkillNames: strList(json['weakSkillNames']),
      missingSkillNames: strList(json['missingSkillNames']),
      weakSkills: _mapListOf(json['weakSkills']),
      missingRequiredSkills: _mapListOf(json['missingRequiredSkills']),
      missingOptionalSkills: _mapListOf(json['missingOptionalSkills']),
    );
  }
}

class AnalysisSourceInfo {
  const AnalysisSourceInfo({this.type, this.sourceMode, this.totalRepositories, this.totalUserCommits, this.userLevel, this.userReadinessScore, this.repositoryNames = const []});
  final String? type;
  final String? sourceMode;
  final int? totalRepositories;
  final int? totalUserCommits;
  final String? userLevel;
  final double? userReadinessScore;
  final List<String> repositoryNames;
  factory AnalysisSourceInfo.fromJson(Map<String, dynamic> json) => AnalysisSourceInfo(
        type: json['type']?.toString(),
        sourceMode: json['sourceMode']?.toString(),
        totalRepositories: json.containsKey('totalRepositories') ? _intOf(json['totalRepositories']) : null,
        totalUserCommits: json.containsKey('totalUserCommits') ? _intOf(json['totalUserCommits']) : null,
        userLevel: json['userLevel']?.toString(),
        userReadinessScore: json.containsKey('userReadinessScore') ? _doubleOf(json['userReadinessScore']) : null,
        repositoryNames: _stringListOf(json['repositoryNames']),
      );
}

class RoleMatchResponse {
  const RoleMatchResponse({this.sourceMode, this.analysisSource, this.matches = const []});
  final String? sourceMode;
  final AnalysisSourceInfo? analysisSource;
  final List<RoleMatchItem> matches;
  factory RoleMatchResponse.fromJson(Map<String, dynamic> json) => RoleMatchResponse(
        sourceMode: json['sourceMode']?.toString(),
        analysisSource: json['analysisSource'] is Map ? AnalysisSourceInfo.fromJson(_mapOf(json['analysisSource'])) : null,
        matches: _mapListOf(json['matches']).map(RoleMatchItem.fromJson).toList(),
      );
}

class RoleCatalogItem {
  const RoleCatalogItem({required this.roleId, required this.roleName, this.description, this.category, this.level, this.requiredSkillCount = 0, this.optionalSkillCount = 0});
  final String roleId;
  final String roleName;
  final String? description;
  final String? category;
  final String? level;
  final int requiredSkillCount;
  final int optionalSkillCount;
  factory RoleCatalogItem.fromJson(Map<String, dynamic> json) => RoleCatalogItem(
        roleId: (json['roleId'] ?? '').toString(),
        roleName: (json['roleName'] ?? '').toString(),
        description: json['description']?.toString(),
        category: json['category']?.toString(),
        level: json['level']?.toString(),
        requiredSkillCount: _intOf(json['requiredSkillCount']),
        optionalSkillCount: _intOf(json['optionalSkillCount']),
      );
}

class RoleMatchModel {
  const RoleMatchModel({
    required this.topRole,
    required this.matches,
    required this.recommendedNextSkills,
    required this.topMatchedSkills,
    required this.topMissingSkills,
  });

  final String topRole;
  final List<RoleMatchItem> matches;
  final List<String> recommendedNextSkills;
  final List<String> topMatchedSkills;
  final List<String> topMissingSkills;

  RoleMatchItem? get topMatch => matches.isNotEmpty ? matches.first : null;

  factory RoleMatchModel.fromJson(Map<String, dynamic> json) {
    List<String> strList(dynamic v) =>
        (v as List? ?? []).map((e) => e.toString()).where((e) => e.isNotEmpty).toList();

    // Parse matches array
    final matchesList = (json['matches'] as List? ?? [])
        .whereType<Map>()
        .map((e) => RoleMatchItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    // topRole can be nested or directly a string
    String topRole = '';
    final tr = json['topRole'];
    if (tr is Map) {
      topRole = (tr['roleName'] ?? tr['role'] ?? tr['targetRole'] ?? '').toString();
    } else {
      topRole = (tr ?? '').toString();
    }
    
    if (topRole.isEmpty && matchesList.isNotEmpty) {
      topRole = matchesList.first.role;
    }

    return RoleMatchModel(
      topRole: topRole,
      matches: matchesList,
      recommendedNextSkills: strList(json['recommendedNextSkills']),
      topMatchedSkills: strList(json['topMatchedSkills']),
      topMissingSkills: strList(json['topMissingSkills']),
    );
  }
}

class AIRecommendationModel {
  const AIRecommendationModel({
    required this.summary,
    required this.confidence,
    required this.strengths,
    required this.weaknesses,
    required this.missingSkills,
    required this.careerSuggestion,
    required this.estimatedCompletionWeeks,
    required this.roadmap,
  });

  final String summary;
  final int confidence;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> missingSkills;
  final String careerSuggestion;
  final int estimatedCompletionWeeks;
  final RoadmapModel roadmap;
}

class RepoAnalysisSnapshotModel {
  const RepoAnalysisSnapshotModel({
    required this.id,
    required this.repoId,
    required this.createdAt,
    required this.scores,
    required this.checklist,
    required this.missingSkills,
    required this.strengths,
    required this.weaknesses,
    required this.recommendations,
  });

  final String id;
  final String repoId;
  final String createdAt;
  final AnalysisScores scores;
  final List<String> checklist;
  final List<String> missingSkills;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> recommendations;

  factory RepoAnalysisSnapshotModel.fromJson(Map<String, dynamic> json) {
    List<String> strList(dynamic v) {
      Iterable iterable = [];
      if (v is List) iterable = v;
      else if (v is Map) iterable = v.values;
      
      return iterable.map((e) {
        if (e is Map) {
          return (e['title'] ?? e['description'] ?? e['name'] ?? '').toString();
        }
        return e.toString();
      }).where((e) => e.isNotEmpty).toList();
    }

    return RepoAnalysisSnapshotModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      repoId: (json['repositoryId'] ?? json['repoId'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? DateTime.now().toIso8601String()).toString(),
      scores: AnalysisScores.fromJson(json['scores'] is Map ? Map<String, dynamic>.from(json['scores'] as Map) : {}),
      checklist: strList(json['checklist']),
      missingSkills: strList(json['missingSkills']),
      strengths: strList(json['strengths']),
      weaknesses: strList(json['weaknesses']),
      recommendations: strList(json['recommendations']),
    );
  }
}

class SnapshotCompareResultModel {
  const SnapshotCompareResultModel({
    required this.overallBefore,
    required this.overallAfter,
    required this.overallChange,
    required this.resolvedMissingSkills,
    required this.remainingMissingSkills,
    required this.newMissingSkills,
    required this.summary,
  });

  final double overallBefore;
  final double overallAfter;
  final double overallChange;
  final List<String> resolvedMissingSkills;
  final List<String> remainingMissingSkills;
  final List<String> newMissingSkills;
  final String summary;

  factory SnapshotCompareResultModel.fromJson(Map<String, dynamic> json) {
    List<String> strList(dynamic v) {
      Iterable iterable = [];
      if (v is List) iterable = v;
      else if (v is Map) iterable = v.values;
      
      return iterable.map((e) {
        if (e is Map) {
          return (e['title'] ?? e['description'] ?? e['name'] ?? '').toString();
        }
        return e.toString();
      }).where((e) => e.isNotEmpty).toList();
    }

    return SnapshotCompareResultModel(
      overallBefore: double.tryParse(json['overallBefore']?.toString() ?? '') ?? 0.0,
      overallAfter: double.tryParse(json['overallAfter']?.toString() ?? '') ?? 0.0,
      overallChange: double.tryParse(json['overallChange']?.toString() ?? '') ?? 0.0,
      resolvedMissingSkills: strList(json['resolvedMissingSkills']),
      remainingMissingSkills: strList(json['remainingMissingSkills']),
      newMissingSkills: strList(json['newMissingSkills']),
      summary: json['comparison'] == null && json['enoughData'] == false
          ? 'Not enough snapshots to compare'
          : (json['summary'] ?? '').toString(),
    );
  }
}

class RoadmapProgressSummary {
  const RoadmapProgressSummary({this.totalItems = 0, this.completedItems = 0, this.inProgressItems = 0, this.overallProgress = 0});
  final int totalItems;
  final int completedItems;
  final int inProgressItems;
  final int overallProgress;
  factory RoadmapProgressSummary.fromJson(Map<String, dynamic> json) => RoadmapProgressSummary(
        totalItems: _intOf(json['totalItems']),
        completedItems: _intOf(json['completedItems']),
        inProgressItems: _intOf(json['inProgressItems']),
        overallProgress: _intOf(json['overallProgress']),
      );
}

class RoadmapProgressItem {
  const RoadmapProgressItem({required this.itemId, this.title, this.skillName, this.canonicalSkillName, this.category, this.targetRole, this.level, this.priority, this.status = 'not_started', this.progressPercent = 0, this.startedAt, this.completedAt, this.updatedAt});
  final String itemId;
  final String? title;
  final String? skillName;
  final String? canonicalSkillName;
  final String? category;
  final String? targetRole;
  final String? level;
  final String? priority;
  final String status;
  final int progressPercent;
  final String? startedAt;
  final String? completedAt;
  final String? updatedAt;
  factory RoadmapProgressItem.fromJson(Map<String, dynamic> json) => RoadmapProgressItem(
        itemId: (json['itemId'] ?? '').toString(),
        title: json['title']?.toString(),
        skillName: json['skillName']?.toString(),
        canonicalSkillName: json['canonicalSkillName']?.toString(),
        category: json['category']?.toString(),
        targetRole: json['targetRole']?.toString(),
        level: json['level']?.toString(),
        priority: json['priority']?.toString(),
        status: (json['status'] ?? 'not_started').toString(),
        progressPercent: _intOf(json['progressPercent']),
        startedAt: json['startedAt']?.toString(),
        completedAt: json['completedAt']?.toString(),
        updatedAt: json['updatedAt']?.toString(),
      );
}

class RoadmapProgressResponse {
  const RoadmapProgressResponse({required this.roadmapId, required this.progressSummary, this.items = const []});
  final String roadmapId;
  final RoadmapProgressSummary progressSummary;
  final List<RoadmapProgressItem> items;
  factory RoadmapProgressResponse.fromJson(Map<String, dynamic> json) => RoadmapProgressResponse(
        roadmapId: (json['roadmapId'] ?? '').toString(),
        progressSummary: RoadmapProgressSummary.fromJson(_mapOf(json['progressSummary'])),
        items: _mapListOf(json['items']).map(RoadmapProgressItem.fromJson).toList(),
      );
}

class RoadmapLearningListResponse {
  const RoadmapLearningListResponse({required this.roadmapId, this.sourceMode, this.language, this.items = const []});
  final String roadmapId;
  final String? sourceMode;
  final String? language;
  final List<RoadmapLearningStatusItem> items;
  factory RoadmapLearningListResponse.fromJson(Map<String, dynamic> json) => RoadmapLearningListResponse(
        roadmapId: (json['roadmapId'] ?? '').toString(),
        sourceMode: json['sourceMode']?.toString(),
        language: json['language']?.toString(),
        items: _mapListOf(json['items']).map(RoadmapLearningStatusItem.fromJson).toList(),
      );
}

class RoadmapLearningStatusItem {
  const RoadmapLearningStatusItem({required this.itemId, this.taskTitle, this.canonicalSkillName, this.skillName, this.targetRole, this.level, this.week, this.priority, this.learningStatus = 'missing'});
  final String itemId;
  final String? taskTitle;
  final String? canonicalSkillName;
  final String? skillName;
  final String? targetRole;
  final String? level;
  final int? week;
  final String? priority;
  final String learningStatus;
  factory RoadmapLearningStatusItem.fromJson(Map<String, dynamic> json) => RoadmapLearningStatusItem(
        itemId: (json['itemId'] ?? '').toString(),
        taskTitle: json['taskTitle']?.toString(),
        canonicalSkillName: json['canonicalSkillName']?.toString(),
        skillName: json['skillName']?.toString(),
        targetRole: json['targetRole']?.toString(),
        level: json['level']?.toString(),
        week: json.containsKey('week') ? _intOf(json['week']) : null,
        priority: json['priority']?.toString(),
        learningStatus: (json['learningStatus'] ?? 'missing').toString(),
      );
}

class RoadmapLearningTask {
  const RoadmapLearningTask({this.title, this.description, this.skillName, this.canonicalSkillName, this.category, this.targetRole, this.level, this.week, this.priority, this.estimatedHours});
  final String? title;
  final String? description;
  final String? skillName;
  final String? canonicalSkillName;
  final String? category;
  final String? targetRole;
  final String? level;
  final int? week;
  final String? priority;
  final int? estimatedHours;
  factory RoadmapLearningTask.fromJson(Map<String, dynamic> json) => RoadmapLearningTask(
        title: json['title']?.toString(),
        description: json['description']?.toString(),
        skillName: json['skillName']?.toString(),
        canonicalSkillName: json['canonicalSkillName']?.toString(),
        category: json['category']?.toString(),
        targetRole: json['targetRole']?.toString(),
        level: json['level']?.toString(),
        week: json.containsKey('week') ? _intOf(json['week']) : null,
        priority: json['priority']?.toString(),
        estimatedHours: json.containsKey('estimatedHours') ? _intOf(json['estimatedHours']) : null,
      );
}

class RoadmapLearningContent {
  const RoadmapLearningContent({this.skillName, this.canonicalSkillName, this.targetRole, this.level, this.language, this.title, this.overview, this.whyLearn, this.useCases = const [], this.howToApply, this.examples = const [], this.checklist = const [], this.exercises = const [], this.commonMistakes = const [], this.nextSkills = const [], this.resources = const []});
  final String? skillName;
  final String? canonicalSkillName;
  final String? targetRole;
  final String? level;
  final String? language;
  final String? title;
  final String? overview;
  final String? whyLearn;
  final List<String> useCases;
  final String? howToApply;
  final List<String> examples;
  final List<String> checklist;
  final List<String> exercises;
  final List<String> commonMistakes;
  final List<String> nextSkills;
  final List<LearningResourceItem> resources;
  factory RoadmapLearningContent.fromJson(Map<String, dynamic> json) => RoadmapLearningContent(
        skillName: json['skillName']?.toString(),
        canonicalSkillName: json['canonicalSkillName']?.toString(),
        targetRole: json['targetRole']?.toString(),
        level: json['level']?.toString(),
        language: json['language']?.toString(),
        title: json['title']?.toString(),
        overview: json['overview']?.toString(),
        whyLearn: json['whyLearn']?.toString(),
        useCases: _stringListOf(json['useCases']),
        howToApply: json['howToApply']?.toString(),
        examples: _stringListOf(json['examples']),
        checklist: _stringListOf(json['checklist']),
        exercises: _stringListOf(json['exercises']),
        commonMistakes: _stringListOf(json['commonMistakes']),
        nextSkills: _stringListOf(json['nextSkills']),
        resources: _mapListOf(json['resources']).map(LearningResourceItem.fromJson).toList(),
      );
}

class RoadmapPersonalizedContext {
  const RoadmapPersonalizedContext({this.sourceMode, this.repoName, this.projectType, this.repositoryNames = const [], this.practiceTask, this.roadmapReason});
  final String? sourceMode;
  final String? repoName;
  final String? projectType;
  final List<String> repositoryNames;
  final String? practiceTask;
  final String? roadmapReason;
  factory RoadmapPersonalizedContext.fromJson(Map<String, dynamic> json) => RoadmapPersonalizedContext(
        sourceMode: json['sourceMode']?.toString(),
        repoName: json['repoName']?.toString(),
        projectType: json['projectType']?.toString(),
        repositoryNames: _stringListOf(json['repositoryNames']),
        practiceTask: json['practiceTask']?.toString(),
        roadmapReason: json['roadmapReason']?.toString(),
      );
}

class LearningResourceItem {
  const LearningResourceItem({this.title, this.url, this.type, this.source});
  final String? title;
  final String? url;
  final String? type;
  final String? source;
  factory LearningResourceItem.fromJson(Map<String, dynamic> json) => LearningResourceItem(
        title: json['title']?.toString(),
        url: json['url']?.toString(),
        type: json['type']?.toString(),
        source: json['source']?.toString(),
      );
}

class RoadmapLearningItemResponse {
  const RoadmapLearningItemResponse({required this.roadmapId, required this.itemId, this.task, this.learning, this.personalizedContext, this.progress});
  final String roadmapId;
  final String itemId;
  final RoadmapLearningTask? task;
  final RoadmapLearningContent? learning;
  final RoadmapPersonalizedContext? personalizedContext;
  final RoadmapProgressItem? progress;
  factory RoadmapLearningItemResponse.fromJson(Map<String, dynamic> json) => RoadmapLearningItemResponse(
        roadmapId: (json['roadmapId'] ?? '').toString(),
        itemId: (json['itemId'] ?? '').toString(),
        task: json['task'] is Map ? RoadmapLearningTask.fromJson(_mapOf(json['task'])) : null,
        learning: json['learning'] is Map ? RoadmapLearningContent.fromJson(_mapOf(json['learning'])) : null,
        personalizedContext: json['personalizedContext'] is Map ? RoadmapPersonalizedContext.fromJson(_mapOf(json['personalizedContext'])) : null,
        progress: json['progress'] is Map ? RoadmapProgressItem.fromJson({'itemId': json['itemId'], ..._mapOf(json['progress'])}) : null,
      );
}

class ChatSettingsModel {
  const ChatSettingsModel({required this.mode, this.updatedAt});
  final String mode;
  final String? updatedAt;
  factory ChatSettingsModel.fromJson(Map<String, dynamic> json) => ChatSettingsModel(
        mode: (json['mode'] ?? 'AI_AUTO').toString(),
        updatedAt: json['updatedAt']?.toString(),
      );
}

class AdminChatSessionModel extends ChatSessionModel {
  const AdminChatSessionModel({
    required super.id,
    required super.title,
    required super.createdAt,
    required super.messages,
    super.repositoryContext,
    super.mode,
    super.effectiveMode,
    super.modeSource,
    super.status,
    this.user = const {},
    this.assignedAdminId,
  });
  final Map<String, dynamic> user;
  final String? assignedAdminId;
  factory AdminChatSessionModel.fromJson(Map<String, dynamic> json) => AdminChatSessionModel(
        id: (json['id'] ?? json['_id'] ?? json['sessionId'] ?? '').toString(),
        title: (json['title'] ?? json['name'] ?? 'Chat').toString(),
        createdAt: (json['createdAt'] ?? '').toString(),
        messages: _mapListOf(json['messages']).map(ChatMessageModel.fromJson).toList(),
        repositoryContext: json['repositoryContext']?.toString(),
        mode: json['mode']?.toString(),
        effectiveMode: json['effectiveMode']?.toString(),
        modeSource: json['modeSource']?.toString(),
        status: json['status']?.toString(),
        user: _mapOf(json['user']),
        assignedAdminId: json['assignedAdminId']?.toString(),
      );
}

class AdminChatSessionListResponse {
  const AdminChatSessionListResponse({this.sessions = const [], this.total = 0, this.page = 1, this.limit = 20});
  final List<AdminChatSessionModel> sessions;
  final int total;
  final int page;
  final int limit;
  factory AdminChatSessionListResponse.fromJson(Map<String, dynamic> json) {
    final pagination = _mapOf(json['pagination']);
    return AdminChatSessionListResponse(
      sessions: _mapListOf(json['sessions'] ?? json['items']).map(AdminChatSessionModel.fromJson).toList(),
      total: _intOf(json['total'] ?? pagination['total']),
      page: _intOf(json['page'] ?? pagination['page'], 1),
      limit: _intOf(json['limit'] ?? pagination['limit'], 20),
    );
  }
}

class AdminChatSessionDetailResponse {
  const AdminChatSessionDetailResponse({required this.session, this.messages = const []});
  final AdminChatSessionModel session;
  final List<ChatMessageModel> messages;
  factory AdminChatSessionDetailResponse.fromJson(Map<String, dynamic> json) {
    final session = AdminChatSessionModel.fromJson(_mapOf(json['session'] ?? json));
    final messages = _mapListOf(json['messages']).map(ChatMessageModel.fromJson).toList();
    return AdminChatSessionDetailResponse(session: session, messages: messages);
  }
}
