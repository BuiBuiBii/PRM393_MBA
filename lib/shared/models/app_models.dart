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

  factory AnalysisModel.fromJson(Map<String, dynamic> json) {
    final scoresJson = json['scores'] is Map
        ? Map<String, dynamic>.from(json['scores'] as Map)
        : json;
    return AnalysisModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      repositoryId: (json['repositoryId'] ?? json['repoId'] ?? '').toString(),
      repositoryName: (json['repositoryName'] ?? json['repoName'] ?? json['fullName'] ?? 'Repository').toString(),
      createdAt: (json['createdAt'] ?? DateTime.now().toIso8601String()).toString(),
      projectType: (json['projectType'] ?? 'Unknown').toString(),
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
      careerDirection: json['careerDirection'] is Map
          ? (json['careerDirection'] as Map)['primary']?.toString()
          : json['careerDirection']?.toString(),
    );
  }
}

class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
  });

  final String id;
  final String role;
  final String content;
  final String timestamp;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: (json['id'] ?? json['_id'] ?? DateTime.now().millisecondsSinceEpoch).toString(),
      role: (json['role'] ?? 'assistant').toString(),
      content: (json['content'] ?? json['message'] ?? '').toString(),
      timestamp: (json['timestamp'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()).toString(),
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
  });

  final String id;
  final String title;
  final String createdAt;
  final List<ChatMessageModel> messages;
  final String? repositoryContext;

  ChatSessionModel copyWith({List<ChatMessageModel>? messages}) {
    return ChatSessionModel(
      id: id,
      title: title,
      createdAt: createdAt,
      messages: messages ?? this.messages,
      repositoryContext: repositoryContext,
    );
  }

  factory ChatSessionModel.fromJson(Map<String, dynamic> json) {
    return ChatSessionModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? json['name'] ?? 'Cuộc trò chuyện mới').toString(),
      createdAt: (json['createdAt'] ?? DateTime.now().toIso8601String()).toString(),
      repositoryContext: json['repositoryContext']?.toString(),
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
  final int? priority;
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
    this.roleMatchInfo,
    this.skillGapSummary,
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
  final Map<String, dynamic>? roleMatchInfo;
  final Map<String, dynamic>? skillGapSummary;

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
      roleMatchInfo: roleMatchInfo,
      skillGapSummary: skillGapSummary,
    );
  }
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
  });

  final String role;
  final String description;
  final String category;
  final double matchScore;
  final String matchLevel;
  final String matchLevelLabel;
  final List<String> matchedSkills;
  final List<String> missingSkills;
  final List<String> recommendedNextSkills;

  factory RoleMatchItem.fromJson(Map<String, dynamic> json) {
    List<String> strList(dynamic v) =>
        (v as List? ?? []).map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    return RoleMatchItem(
      role: (json['roleName'] ?? json['role'] ?? json['targetRole'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      matchScore: double.tryParse(json['matchScore']?.toString() ?? '') ?? 0.0,
      matchLevel: (json['matchLevel'] ?? '').toString(),
      matchLevelLabel: (json['matchLevelLabel'] ?? json['matchLevel'] ?? '').toString(),
      matchedSkills: strList(json['matchedSkills'] ?? json['topMatchedSkills']),
      missingSkills: strList(json['missingSkills'] ?? json['topMissingSkills']),
      recommendedNextSkills: strList(json['recommendedNextSkills']),
    );
  }
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
      summary: (json['summary'] ?? '').toString(),
    );
  }
}
