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
      fullName: (json['fullName'] ?? json['full_name'] ?? json['name'] ?? '')
          .toString(),
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

  bool get hasDetails =>
      architecture != 0 ||
      completeness != 0 ||
      commitQuality != 0 ||
      documentation != 0 ||
      codeConvention != 0;

  factory AnalysisScores.fromJson(Map<String, dynamic>? json) {
    json ??= {};
    double? pickNumber(List<String> keys) {
      for (final key in keys) {
        final v = json![key];
        if (v is num) return v.toDouble();
        final parsed = double.tryParse(v?.toString() ?? '');
        if (parsed != null) return parsed;
      }
      return null;
    }

    final raw = <String, double?>{
      'architecture': pickNumber(['architecture', 'architectureScore']),
      'completeness': pickNumber(['completeness', 'completenessScore']),
      'commitQuality': pickNumber(['commitQuality', 'commitQualityScore']),
      'documentation': pickNumber(['documentation', 'documentationScore']),
      'codeConvention': pickNumber([
        'codeConvention',
        'codeConventionScore',
        'codeQuality',
        'codeQualityScore',
      ]),
      'overall': pickNumber(['overall', 'overallScore']),
    };
    final present = raw.values.whereType<double>().toList();
    final usesRatioScale = present.isNotEmpty &&
        present.any((value) => value > 0) &&
        present.every((value) => value >= 0 && value <= 1);

    int score(String key) {
      final value = raw[key] ?? 0;
      return ((usesRatioScale ? value * 100 : value).round()).clamp(0, 100);
    }

    return AnalysisScores(
      architecture: score('architecture'),
      completeness: score('completeness'),
      commitQuality: score('commitQuality'),
      documentation: score('documentation'),
      codeConvention: score('codeConvention'),
      overall: score('overall'),
    );
  }
}

class AnalysisSkillModel {
  const AnalysisSkillModel({
    required this.skill,
    required this.canonicalSkillName,
    required this.category,
    required this.score,
    required this.level,
  });

  final String skill;
  final String canonicalSkillName;
  final String category;
  final double score;
  final String level;

  String get displayName =>
      canonicalSkillName.isNotEmpty ? canonicalSkillName : skill;

  factory AnalysisSkillModel.fromJson(Map<String, dynamic> json) {
    return AnalysisSkillModel(
      skill: (json['skill'] ?? json['name'] ?? '').toString(),
      canonicalSkillName: (json['canonicalSkillName'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      score: double.tryParse(json['score']?.toString() ?? '') ?? 0,
      level: (json['level'] ?? '').toString(),
    );
  }
}

class AnalysisScopeModel {
  const AnalysisScopeModel({
    required this.type,
    required this.githubUsername,
    required this.totalRepoCommits,
    required this.userCommits,
    required this.activeDays,
    this.firstCommitDate,
    this.lastCommitDate,
  });

  final String type;
  final String githubUsername;
  final int totalRepoCommits;
  final int userCommits;
  final int activeDays;
  final String? firstCommitDate;
  final String? lastCommitDate;

  factory AnalysisScopeModel.fromJson(Map<String, dynamic> json) {
    int integer(String key) => int.tryParse(json[key]?.toString() ?? '') ?? 0;

    return AnalysisScopeModel(
      type: (json['type'] ?? '').toString(),
      githubUsername: (json['githubUsername'] ?? '').toString(),
      totalRepoCommits: integer('totalRepoCommits'),
      userCommits: integer('userCommits'),
      activeDays: integer('activeDays'),
      firstCommitDate: json['firstCommitDate']?.toString(),
      lastCommitDate: json['lastCommitDate']?.toString(),
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
    this.userReadinessScore,
    this.userLevel,
    this.topSkills = const [],
    this.missingSkills = const [],
    this.scoreBreakdown = const {},
    this.confidence,
    this.snapshotId,
    this.githubRepoId,
    this.topSkillDetails = const [],
    this.analysisScope,
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
  final int? userReadinessScore;
  final String? userLevel;
  final List<String> topSkills;
  final List<String> missingSkills;
  final Map<String, int> scoreBreakdown;
  final double? confidence;
  final String? snapshotId;
  final int? githubRepoId;
  final List<AnalysisSkillModel> topSkillDetails;
  final AnalysisScopeModel? analysisScope;

  bool get hasCompleteNarrative =>
      strengths.isNotEmpty &&
      weaknesses.isNotEmpty &&
      recommendations.isNotEmpty;

  AnalysisModel withNarrative({
    List<String>? strengths,
    List<String>? weaknesses,
    List<String>? recommendations,
  }) {
    return AnalysisModel(
      id: id,
      repositoryId: repositoryId,
      repositoryName: repositoryName,
      createdAt: createdAt,
      projectType: projectType,
      techStack: techStack,
      scores: scores,
      strengths: strengths ?? this.strengths,
      weaknesses: weaknesses ?? this.weaknesses,
      recommendations: recommendations ?? this.recommendations,
      careerDirection: careerDirection,
      userReadinessScore: userReadinessScore,
      userLevel: userLevel,
      topSkills: topSkills,
      missingSkills: missingSkills,
      scoreBreakdown: scoreBreakdown,
      confidence: confidence,
      snapshotId: snapshotId,
      githubRepoId: githubRepoId,
      topSkillDetails: topSkillDetails,
      analysisScope: analysisScope,
    );
  }

  factory AnalysisModel.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] is Map
        ? Map<String, dynamic>.from(json['summary'] as Map)
        : <String, dynamic>{};
    final repository = json['repository'] is Map
        ? Map<String, dynamic>.from(json['repository'] as Map)
        : <String, dynamic>{};
    final scopeJson = json['analysisScope'] is Map
        ? Map<String, dynamic>.from(json['analysisScope'] as Map)
        : null;
    final topSkillDetails = (json['topSkills'] as List? ?? [])
        .whereType<Map>()
        .map((item) =>
            AnalysisSkillModel.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.displayName.isNotEmpty)
        .toList();
    final scoresSource = json['scores'] ?? json['metrics'];
    final scoresJson = scoresSource is Map
        ? Map<String, dynamic>.from(scoresSource)
        : <String, dynamic>{
            'overallScore': summary['overallScore'] ??
                summary['userReadinessScore'] ??
                json['overallScore'],
          };

    List<String> strList(dynamic v) => (v as List? ?? [])
        .map((e) => e is Map
            ? (e['canonicalSkillName'] ??
                    e['skill'] ??
                    e['name'] ??
                    e['title'] ??
                    e['description'] ??
                    '')
                .toString()
            : e.toString())
        .where((e) => e.isNotEmpty)
        .toList();

    Map<String, int> breakdownMap(dynamic v) {
      if (v is! Map) return {};
      final parsedValues = <String, double>{};
      v.forEach((key, value) {
        final parsed = value is num
            ? value.toDouble()
            : double.tryParse(value?.toString() ?? '');
        if (parsed != null) parsedValues[key.toString()] = parsed;
      });
      final usesRatioScale = parsedValues.isNotEmpty &&
          parsedValues.values.any((value) => value > 0) &&
          parsedValues.values.every((value) => value >= 0 && value <= 1);
      return parsedValues.map(
        (key, value) => MapEntry(
          key,
          ((usesRatioScale ? value * 100 : value).round()).clamp(0, 100),
        ),
      );
    }

    final readiness =
        summary['userReadinessScore'] ?? json['userReadinessScore'];
    final career = summary['careerDirection'] ?? json['careerDirection'];
    int? percent(dynamic value) {
      final parsed = value is num
          ? value.toDouble()
          : double.tryParse(value?.toString() ?? '');
      if (parsed == null) return null;
      final normalized = parsed > 0 && parsed <= 1 ? parsed * 100 : parsed;
      return normalized.round().clamp(0, 100);
    }

    return AnalysisModel(
      id: (json['id'] ?? json['_id'] ?? json['analysisId'] ?? '').toString(),
      repositoryId: (json['repositoryId'] ??
              json['repoId'] ??
              repository['repositoryId'] ??
              repository['id'] ??
              '')
          .toString(),
      repositoryName: (json['repositoryName'] ??
              json['repoName'] ??
              json['fullName'] ??
              repository['fullName'] ??
              repository['repoName'] ??
              'Repository')
          .toString(),
      createdAt:
          (json['createdAt'] ?? DateTime.now().toIso8601String()).toString(),
      projectType: (summary['projectType'] ?? json['projectType'] ?? 'Unknown')
          .toString(),
      techStack: strList(json['techStack'] ?? json['languages']),
      scores: AnalysisScores.fromJson(scoresJson),
      strengths: strList(json['strengths']),
      weaknesses: strList(json['weaknesses']),
      recommendations: (json['recommendations'] as List? ?? [])
          .map((e) => e is Map
              ? (e['title'] ?? e['description'] ?? '').toString()
              : e.toString())
          .where((e) => e.isNotEmpty)
          .toList(),
      careerDirection:
          career is Map ? career['primary']?.toString() : career?.toString(),
      userReadinessScore: percent(readiness),
      userLevel: (summary['userLevel'] ?? json['userLevel'])?.toString(),
      topSkills: topSkillDetails.isNotEmpty
          ? topSkillDetails.map((item) => item.displayName).toList()
          : strList(json['topSkills']),
      missingSkills: strList(json['missingSkills']),
      scoreBreakdown: breakdownMap(json['scoreBreakdown']),
      confidence: double.tryParse(
          (summary['confidence'] ?? json['confidence'])?.toString() ?? ''),
      snapshotId:
          (json['snapshotId'] ?? json['repoAnalysisSnapshotId'])?.toString(),
      githubRepoId: int.tryParse(repository['githubRepoId']?.toString() ?? ''),
      topSkillDetails: topSkillDetails,
      analysisScope:
          scopeJson == null ? null : AnalysisScopeModel.fromJson(scopeJson),
    );
  }
}

class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.senderType = '',
  });

  final String id;
  final String role;
  final String content;
  final String timestamp;
  final String senderType;

  String get effectiveSenderType {
    final explicit = senderType.trim().toUpperCase();
    if (explicit.isNotEmpty) return explicit;
    return role.toLowerCase() == 'user' ? 'USER' : 'AI';
  }

  bool get isUser => effectiveSenderType == 'USER';
  bool get isAdmin => effectiveSenderType == 'ADMIN';

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: (json['id'] ?? json['_id'] ?? DateTime.now().millisecondsSinceEpoch)
          .toString(),
      role: (json['role'] ?? 'assistant').toString(),
      content: (json['content'] ?? json['message'] ?? '').toString(),
      timestamp: (json['timestamp'] ??
              json['createdAt'] ??
              DateTime.now().toIso8601String())
          .toString(),
      senderType: (json['senderType'] ?? '').toString(),
    );
  }
}

class ChatContextModel {
  const ChatContextModel({
    this.repositoryId,
    this.repoName,
    this.roadmapId,
    this.analysisId,
    this.snapshotId,
    this.progressUpdatedAt,
    this.analysisSource,
    this.contextSelectionReason,
    this.contextPinned = false,
    this.intent,
    this.intents = const [],
    this.hasRoadmapContext = false,
    this.hasComparisonContext = false,
    this.comparedRepoCount = 0,
  });

  final String? repositoryId;
  final String? repoName;
  final String? roadmapId;
  final String? analysisId;
  final String? snapshotId;
  final String? progressUpdatedAt;
  final String? analysisSource;
  final String? contextSelectionReason;
  final bool contextPinned;
  final String? intent;
  final List<String> intents;
  final bool hasRoadmapContext;
  final bool hasComparisonContext;
  final int comparedRepoCount;

  bool get hasContext =>
      repositoryId?.isNotEmpty == true ||
      repoName?.isNotEmpty == true ||
      roadmapId?.isNotEmpty == true ||
      analysisId?.isNotEmpty == true ||
      snapshotId?.isNotEmpty == true ||
      contextSelectionReason == 'latest_user_analysis' ||
      hasComparisonContext;

  factory ChatContextModel.fromJson(Map<String, dynamic> json) {
    return ChatContextModel(
      repositoryId: json['repositoryId']?.toString(),
      repoName: json['repoName']?.toString(),
      roadmapId: json['roadmapId']?.toString(),
      analysisId: json['analysisId']?.toString(),
      snapshotId: json['snapshotId']?.toString(),
      progressUpdatedAt: json['progressUpdatedAt']?.toString(),
      analysisSource: json['analysisSource']?.toString(),
      contextSelectionReason: json['contextSelectionReason']?.toString(),
      contextPinned: json['contextPinned'] == true,
      intent: json['intent']?.toString(),
      intents: (json['intents'] as List? ?? const [])
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList(),
      hasRoadmapContext: json['hasRoadmapContext'] == true,
      hasComparisonContext: json['hasComparisonContext'] == true,
      comparedRepoCount:
          int.tryParse(json['comparedRepoCount']?.toString() ?? '') ?? 0,
    );
  }
}

class ChatSessionCreatePayload {
  const ChatSessionCreatePayload({
    required this.title,
    this.repositoryId,
    this.roadmapId,
    this.analysisId,
    this.snapshotId,
  });

  final String title;
  final String? repositoryId;
  final String? roadmapId;
  final String? analysisId;
  final String? snapshotId;

  Map<String, dynamic> toJson() => {
        'title': title,
        if (repositoryId?.isNotEmpty == true) 'repositoryId': repositoryId,
        if (roadmapId?.isNotEmpty == true) 'roadmapId': roadmapId,
        if (analysisId?.isNotEmpty == true) 'analysisId': analysisId,
        if (snapshotId?.isNotEmpty == true) 'snapshotId': snapshotId,
      };
}

class ChatSessionModel {
  const ChatSessionModel({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.messages,
    this.repositoryContext,
    this.status = 'active',
    this.mode = 'AI_AUTO',
    this.modeSource = 'GLOBAL',
    this.effectiveMode = 'AI_AUTO',
    this.unreadByUser = false,
    this.unreadByAdmin = false,
    this.updatedAt,
    this.lastMessageAt,
    this.lastMessage,
    this.lastMessageText,
    this.manualReason,
    this.repositoryId,
    this.roadmapId,
    this.analysisId,
    this.snapshotId,
    this.contextSelectionReason,
    this.contextPinnedAt,
    this.context,
  });

  final String id;
  final String title;
  final String createdAt;
  final List<ChatMessageModel> messages;
  final String? repositoryContext;
  final String status;
  final String mode;
  final String modeSource;
  final String effectiveMode;
  final bool unreadByUser;
  final bool unreadByAdmin;
  final String? updatedAt;
  final String? lastMessageAt;
  final ChatMessageModel? lastMessage;
  final String? lastMessageText;
  final String? manualReason;
  final String? repositoryId;
  final String? roadmapId;
  final String? analysisId;
  final String? snapshotId;
  final String? contextSelectionReason;
  final String? contextPinnedAt;
  final ChatContextModel? context;

  ChatSessionModel copyWith({
    List<ChatMessageModel>? messages,
    String? status,
    String? mode,
    String? modeSource,
    String? effectiveMode,
    bool? unreadByUser,
    bool? unreadByAdmin,
    String? updatedAt,
    String? lastMessageAt,
    ChatMessageModel? lastMessage,
    String? lastMessageText,
    String? manualReason,
    String? repositoryId,
    String? roadmapId,
    String? analysisId,
    String? snapshotId,
    String? contextSelectionReason,
    String? contextPinnedAt,
    ChatContextModel? context,
  }) {
    return ChatSessionModel(
      id: id,
      title: title,
      createdAt: createdAt,
      messages: messages ?? this.messages,
      repositoryContext: repositoryContext,
      status: status ?? this.status,
      mode: mode ?? this.mode,
      modeSource: modeSource ?? this.modeSource,
      effectiveMode: effectiveMode ?? this.effectiveMode,
      unreadByUser: unreadByUser ?? this.unreadByUser,
      unreadByAdmin: unreadByAdmin ?? this.unreadByAdmin,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      manualReason: manualReason ?? this.manualReason,
      repositoryId: repositoryId ?? this.repositoryId,
      roadmapId: roadmapId ?? this.roadmapId,
      analysisId: analysisId ?? this.analysisId,
      snapshotId: snapshotId ?? this.snapshotId,
      contextSelectionReason:
          contextSelectionReason ?? this.contextSelectionReason,
      contextPinnedAt: contextPinnedAt ?? this.contextPinnedAt,
      context: context ?? this.context,
    );
  }

  factory ChatSessionModel.fromJson(Map<String, dynamic> json) {
    final lastMessageJson = json['lastMessage'];
    return ChatSessionModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title:
          (json['title'] ?? json['name'] ?? 'Cuộc trò chuyện mới').toString(),
      createdAt:
          (json['createdAt'] ?? DateTime.now().toIso8601String()).toString(),
      repositoryContext: json['repositoryContext']?.toString(),
      status: (json['status'] ?? 'active').toString(),
      mode: (json['mode'] ?? 'AI_AUTO').toString(),
      modeSource: (json['modeSource'] ?? 'GLOBAL').toString(),
      effectiveMode:
          (json['effectiveMode'] ?? json['mode'] ?? 'AI_AUTO').toString(),
      unreadByUser: json['unreadByUser'] == true,
      unreadByAdmin: json['unreadByAdmin'] == true,
      updatedAt: json['updatedAt']?.toString(),
      lastMessageAt: json['lastMessageAt']?.toString(),
      lastMessage: lastMessageJson is Map
          ? ChatMessageModel.fromJson(
              Map<String, dynamic>.from(lastMessageJson),
            )
          : null,
      lastMessageText: lastMessageJson is Map
          ? lastMessageJson['content']?.toString()
          : lastMessageJson?.toString(),
      manualReason: json['manualReason']?.toString(),
      repositoryId: json['repositoryId']?.toString(),
      roadmapId: json['roadmapId']?.toString(),
      analysisId: json['analysisId']?.toString(),
      snapshotId: json['snapshotId']?.toString(),
      contextSelectionReason: json['contextSelectionReason']?.toString(),
      contextPinnedAt: json['contextPinnedAt']?.toString(),
      context: json['context'] is Map
          ? ChatContextModel.fromJson(
              Map<String, dynamic>.from(json['context'] as Map),
            )
          : null,
      messages: (json['messages'] as List? ?? [])
          .whereType<Map>()
          .map((e) => ChatMessageModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class ChatSendResult {
  const ChatSendResult({
    required this.effectiveMode,
    required this.mode,
    required this.modeSource,
    required this.status,
    this.userMessage,
    this.aiMessage,
    this.adminMessage,
    this.context,
  });

  final String effectiveMode;
  final String mode;
  final String modeSource;
  final String status;
  final ChatMessageModel? userMessage;
  final ChatMessageModel? aiMessage;
  final ChatMessageModel? adminMessage;
  final ChatContextModel? context;

  List<ChatMessageModel> get messages => [
        if (userMessage != null) userMessage!,
        if (aiMessage != null) aiMessage!,
        if (adminMessage != null) adminMessage!,
      ];
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
    this.analysisId,
    this.snapshotId,
    this.roadmapId,
    this.progressUpdatedAt,
    this.context,
    this.isStale = false,
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
  final String? analysisId;
  final String? snapshotId;
  final String? roadmapId;
  final String? progressUpdatedAt;
  final Map<String, dynamic>? context;
  final bool isStale;

  factory AiFeedbackModel.fromJson(Map<String, dynamic> json) {
    List<String> listOf(dynamic value) {
      if (value is List) {
        return value
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList();
      }
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
      analysisId: json['analysisId']?.toString(),
      snapshotId:
          (json['snapshotId'] ?? json['analysisSnapshotId'])?.toString(),
      roadmapId: json['roadmapId']?.toString(),
      progressUpdatedAt: json['progressUpdatedAt']?.toString(),
      context: json['context'] is Map
          ? Map<String, dynamic>.from(json['context'] as Map)
          : null,
      isStale: json['isStale'] == true,
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
      analysisId: analysisId,
      snapshotId: snapshotId,
      roadmapId: roadmapId,
      progressUpdatedAt: progressUpdatedAt,
      context: context,
      isStale: isStale,
    );
  }

  static String _refId(dynamic value) {
    if (value is Map) return (value['_id'] ?? value['id'] ?? '').toString();
    return (value ?? '').toString();
  }

  static String? _refName(dynamic value) {
    if (value is! Map) return null;
    return (value['fullName'] ?? value['name'] ?? value['repoName'])
        ?.toString();
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
      currentSkills: (json['currentSkills'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
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

class LearningResourceModel {
  const LearningResourceModel({
    required this.title,
    required this.url,
    this.provider,
    this.thumbnailUrl,
    this.channelTitle,
    this.publishedAt,
    this.source,
    this.score,
  });

  final String title;
  final String url;
  final String? provider;
  final String? thumbnailUrl;
  final String? channelTitle;
  final String? publishedAt;
  final String? source;
  final double? score;

  factory LearningResourceModel.fromJson(Map<String, dynamic> json) =>
      LearningResourceModel(
        title: (json['title'] ?? '').toString(),
        url: (json['url'] ?? '').toString(),
        provider: json['provider']?.toString(),
        thumbnailUrl: json['thumbnailUrl']?.toString(),
        channelTitle: json['channelTitle']?.toString(),
        publishedAt: json['publishedAt']?.toString(),
        source: json['source']?.toString(),
        score: double.tryParse(json['score']?.toString() ?? ''),
      );
}

class LearningContentModel {
  const LearningContentModel({
    required this.title,
    required this.overview,
    required this.whyLearn,
    required this.useCases,
    required this.howToApply,
    required this.examples,
    required this.checklist,
    required this.exercises,
    required this.commonMistakes,
    required this.nextSkills,
    required this.resources,
  });

  final String title;
  final String overview;
  final String whyLearn;
  final List<String> useCases;
  final List<String> howToApply;
  final List<String> examples;
  final List<String> checklist;
  final List<String> exercises;
  final List<String> commonMistakes;
  final List<String> nextSkills;
  final List<LearningResourceModel> resources;

  factory LearningContentModel.fromJson(Map<String, dynamic> json) {
    List<String> strings(dynamic value) {
      if (value is List) {
        return value
            .map((item) {
              if (item is Map) {
                return (item['title'] ??
                        item['description'] ??
                        item['content'] ??
                        '')
                    .toString();
              }
              return item.toString();
            })
            .where((item) => item.isNotEmpty)
            .toList();
      }
      if (value is String && value.trim().isNotEmpty) return [value.trim()];
      return const [];
    }

    return LearningContentModel(
      title: (json['title'] ?? '').toString(),
      overview: (json['overview'] ?? '').toString(),
      whyLearn: (json['whyLearn'] ?? '').toString(),
      useCases: strings(json['useCases']),
      howToApply: strings(json['howToApply']),
      examples: strings(json['examples']),
      checklist: strings(json['checklist']),
      exercises: strings(json['exercises']),
      commonMistakes: strings(json['commonMistakes']),
      nextSkills: strings(json['nextSkills']),
      resources: (json['resources'] as List? ?? const [])
          .whereType<Map>()
          .map((item) =>
              LearningResourceModel.fromJson(Map<String, dynamic>.from(item)))
          .where((item) => item.url.isNotEmpty)
          .toList(),
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
      suggestedTasks: (json['suggestedTasks'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
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
    this.progressSummary,
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
  final Map<String, dynamic>? roadmapSource;
  final Map<String, dynamic>? progressSummary;
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
    Map<String, dynamic>? progressSummary,
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
      progressSummary: progressSummary ?? this.progressSummary,
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
    required this.roleId,
    required this.role,
    required this.description,
    required this.category,
    required this.matchScore,
    required this.matchLevel,
    required this.matchLevelLabel,
    required this.matchedSkills,
    required this.weakSkills,
    required this.missingSkills,
    required this.recommendedNextSkills,
    this.scoringMethod,
  });

  final String roleId;
  final String role;
  final String description;
  final String category;
  final double matchScore;
  final String matchLevel;
  final String matchLevelLabel;
  final List<String> matchedSkills;
  final List<String> weakSkills;
  final List<String> missingSkills;
  final List<String> recommendedNextSkills;
  final String? scoringMethod;

  factory RoleMatchItem.fromJson(Map<String, dynamic> json) {
    List<String> strList(dynamic v) => (v as List? ?? [])
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();

    final roleId = (json['roleId'] ?? '').toString();
    final roleName =
        (json['roleName'] ?? json['role'] ?? json['targetRole'] ?? '')
            .toString();

    return RoleMatchItem(
      roleId: roleId,
      role: roleName,
      description: (json['description'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      matchScore: double.tryParse(json['matchScore']?.toString() ?? '') ?? 0.0,
      matchLevel: (json['matchLevel'] ?? '').toString(),
      matchLevelLabel:
          (json['matchLevelLabel'] ?? json['matchLevel'] ?? '').toString(),
      matchedSkills: strList(
        json['matchedSkillNames'] ??
            json['matchedSkills'] ??
            json['topMatchedSkills'],
      ),
      weakSkills: strList(json['weakSkillNames'] ?? json['weakSkills']),
      missingSkills: strList(
        json['missingSkillNames'] ??
            json['missingSkills'] ??
            json['topMissingSkills'],
      ),
      recommendedNextSkills: strList(json['recommendedNextSkills']),
      scoringMethod: json['scoringMethod']?.toString(),
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
    this.analysisSource,
    this.repositoryId,
    this.repoName,
  });

  final String topRole;
  final List<RoleMatchItem> matches;
  final List<String> recommendedNextSkills;
  final List<String> topMatchedSkills;
  final List<String> topMissingSkills;
  final String? analysisSource;
  final String? repositoryId;
  final String? repoName;

  RoleMatchItem? get topMatch => matches.isNotEmpty ? matches.first : null;

  factory RoleMatchModel.fromJson(Map<String, dynamic> json) {
    List<String> strList(dynamic v) => (v as List? ?? [])
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();

    final matchesList = (json['matches'] as List? ?? [])
        .whereType<Map>()
        .map((e) => RoleMatchItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    String topRole = '';
    final tr = json['topRole'];
    if (tr is Map) {
      topRole =
          (tr['roleName'] ?? tr['role'] ?? tr['targetRole'] ?? '').toString();
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
      analysisSource: json['analysisSource']?.toString(),
      repositoryId: json['repositoryId']?.toString(),
      repoName: json['repoName']?.toString(),
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
    this.userReadinessScore,
    this.userLevel,
    this.careerDirection,
    this.topSkills = const [],
    this.topSkillDetails = const [],
    this.scoreBreakdown = const {},
    this.analysisScope,
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
  final int? userReadinessScore;
  final String? userLevel;
  final String? careerDirection;
  final List<String> topSkills;
  final List<AnalysisSkillModel> topSkillDetails;
  final Map<String, int> scoreBreakdown;
  final AnalysisScopeModel? analysisScope;

  int get readinessScore => userReadinessScore ?? scores.overall;

  factory RepoAnalysisSnapshotModel.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] is Map
        ? Map<String, dynamic>.from(json['summary'] as Map)
        : <String, dynamic>{};
    final repository = json['repository'] is Map
        ? Map<String, dynamic>.from(json['repository'] as Map)
        : <String, dynamic>{};
    final scopeJson = json['analysisScope'] is Map
        ? Map<String, dynamic>.from(json['analysisScope'] as Map)
        : null;
    final topSkillDetails = (json['topSkills'] as List? ?? [])
        .whereType<Map>()
        .map((item) =>
            AnalysisSkillModel.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.displayName.isNotEmpty)
        .toList();

    List<String> strList(dynamic v) {
      Iterable iterable = [];
      if (v is List) {
        iterable = v;
      } else if (v is Map) {
        iterable = v.values;
      }

      return iterable
          .map((e) {
            if (e is Map) {
              return (e['canonicalSkillName'] ??
                      e['skillName'] ??
                      e['skill'] ??
                      e['title'] ??
                      e['description'] ??
                      e['name'] ??
                      '')
                  .toString();
            }
            return e.toString();
          })
          .where((e) => e.isNotEmpty)
          .toList();
    }

    Map<String, int> breakdownMap(dynamic v) {
      if (v is! Map) return {};
      final parsedValues = <String, double>{};
      v.forEach((key, value) {
        final parsed = value is num
            ? value.toDouble()
            : double.tryParse(value?.toString() ?? '');
        if (parsed != null) parsedValues[key.toString()] = parsed;
      });
      final usesRatioScale = parsedValues.isNotEmpty &&
          parsedValues.values.any((value) => value > 0) &&
          parsedValues.values.every((value) => value >= 0 && value <= 1);
      return parsedValues.map(
        (key, value) => MapEntry(
          key,
          ((usesRatioScale ? value * 100 : value).round()).clamp(0, 100),
        ),
      );
    }

    int? percent(dynamic value) {
      final parsed = value is num
          ? value.toDouble()
          : double.tryParse(value?.toString() ?? '');
      if (parsed == null) return null;
      final normalized = parsed > 0 && parsed <= 1 ? parsed * 100 : parsed;
      return normalized.round().clamp(0, 100);
    }

    final readiness =
        summary['userReadinessScore'] ?? json['userReadinessScore'];
    final scoresSource = json['scores'] ?? json['metrics'];
    final scoresJson = scoresSource is Map
        ? Map<String, dynamic>.from(scoresSource)
        : <String, dynamic>{
            'overallScore': summary['overallScore'] ??
                summary['userReadinessScore'] ??
                json['overallScore'],
          };

    return RepoAnalysisSnapshotModel(
      id: (json['id'] ??
              json['_id'] ??
              json['snapshotId'] ??
              '')
          .toString(),
      repoId: (json['repositoryId'] ??
              json['repoId'] ??
              repository['repositoryId'] ??
              repository['id'] ??
              '')
          .toString(),
      createdAt: (json['createdAt'] ??
              json['analyzedAt'] ??
              DateTime.now().toIso8601String())
          .toString(),
      scores: AnalysisScores.fromJson(scoresJson),
      checklist: strList(json['checklist']),
      missingSkills: strList(json['missingSkills']),
      strengths: strList(json['strengths']),
      weaknesses: strList(json['weaknesses']),
      recommendations: strList(json['recommendationSummary'] ?? json['recommendations']),
      userReadinessScore: percent(readiness),
      userLevel: (summary['userLevel'] ?? json['userLevel'])?.toString(),
      careerDirection:
          (summary['careerDirection'] ?? json['careerDirection'])?.toString(),
      topSkills: topSkillDetails.isNotEmpty
          ? topSkillDetails.map((item) => item.displayName).toList()
          : strList(json['topSkills']),
      topSkillDetails: topSkillDetails,
      scoreBreakdown: breakdownMap(json['scoreBreakdown']),
      analysisScope: scopeJson == null
          ? null
          : AnalysisScopeModel.fromJson(scopeJson),
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
      if (v is List) {
        iterable = v;
      } else if (v is Map) {
        iterable = v.values;
      }

      return iterable
          .map((e) {
            if (e is Map) {
              return (e['canonicalSkillName'] ??
                      e['skillName'] ??
                      e['skill'] ??
                      e['title'] ??
                      e['description'] ??
                      e['name'] ??
                      '')
                  .toString();
            }
            return e.toString();
          })
          .where((e) => e.isNotEmpty)
          .toList();
    }

    double pickScore(List<String> keys) {
      for (final key in keys) {
        final parsed = double.tryParse(json[key]?.toString() ?? '');
        if (parsed != null) return parsed;
      }
      return 0;
    }

    final fromSnapshot = json['fromSnapshot'] is Map
        ? Map<String, dynamic>.from(json['fromSnapshot'] as Map)
        : <String, dynamic>{};
    final toSnapshot = json['toSnapshot'] is Map
        ? Map<String, dynamic>.from(json['toSnapshot'] as Map)
        : <String, dynamic>{};
    final delta = json['delta'] is Map
        ? Map<String, dynamic>.from(json['delta'] as Map)
        : <String, dynamic>{};

    final overallBefore = pickScore(['overallBefore']) != 0
        ? pickScore(['overallBefore'])
        : double.tryParse(
                fromSnapshot['userReadinessScore']?.toString() ?? '') ??
            0;
    final overallAfter = pickScore(['overallAfter']) != 0
        ? pickScore(['overallAfter'])
        : double.tryParse(toSnapshot['userReadinessScore']?.toString() ?? '') ??
            0;
    final overallChange = pickScore(['overallChange']) != 0
        ? pickScore(['overallChange'])
        : double.tryParse(delta['userReadinessScore']?.toString() ?? '') ??
            (overallAfter - overallBefore);

    return SnapshotCompareResultModel(
      overallBefore: overallBefore,
      overallAfter: overallAfter,
      overallChange: overallChange,
      resolvedMissingSkills: strList(json['resolvedMissingSkills']),
      remainingMissingSkills: strList(json['remainingMissingSkills']),
      newMissingSkills: strList(json['newMissingSkills']),
      summary: (json['summary'] ?? delta['toLevel'] ?? '').toString(),
    );
  }
}
