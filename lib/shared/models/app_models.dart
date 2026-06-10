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
      title: (json['title'] ?? 'Chat session').toString(),
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
      repositoryId: (json['repositoryId'] ?? '').toString(),
      repositoryName: (json['repoName'] ?? json['fullName'] ?? json['repositoryName'] ?? 'Repository').toString(),
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

  bool get isArchived => status == 'archived';
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
