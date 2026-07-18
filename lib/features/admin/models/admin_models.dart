import '../../../shared/models/app_models.dart';

class AdminPagination {
  const AdminPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasNext => page < totalPages;
  bool get hasPrev => page > 1;

  factory AdminPagination.fromJson(Map<String, dynamic>? json) {
    final map = json ?? {};
    return AdminPagination(
      page: int.tryParse(map['page']?.toString() ?? '') ?? 1,
      limit: int.tryParse(map['limit']?.toString() ?? '') ?? 20,
      total: int.tryParse(map['total']?.toString() ?? '') ?? 0,
      totalPages: int.tryParse(map['totalPages']?.toString() ?? '') ?? 0,
    );
  }
}

class AdminChatSettings {
  const AdminChatSettings({
    required this.mode,
    required this.aiEnabled,
    required this.manualEnabled,
    this.updatedAt,
  });

  final String mode;
  final bool aiEnabled;
  final bool manualEnabled;
  final String? updatedAt;

  factory AdminChatSettings.fromJson(Map<String, dynamic> json) {
    final mode = (json['mode'] ?? 'AI_AUTO').toString();
    return AdminChatSettings(
      mode: mode,
      aiEnabled: json['aiEnabled'] == true || mode == 'AI_AUTO',
      manualEnabled: json['manualEnabled'] == true || mode == 'MANUAL',
      updatedAt: json['updatedAt']?.toString(),
    );
  }
}

class AdminChatUser {
  const AdminChatUser(
      {required this.id, required this.name, required this.email});

  final String id;
  final String name;
  final String email;

  factory AdminChatUser.fromJson(Map<String, dynamic> json) => AdminChatUser(
        id: (json['_id'] ?? json['id'] ?? '').toString(),
        name: (json['fullName'] ?? json['name'] ?? 'Người dùng').toString(),
        email: (json['email'] ?? '').toString(),
      );
}

class AdminChatSession {
  const AdminChatSession({
    required this.id,
    required this.title,
    required this.status,
    required this.mode,
    required this.modeSource,
    required this.effectiveMode,
    required this.messages,
    this.user,
    this.assignedAdminId,
    this.unreadByAdmin = false,
    this.unreadByUser = false,
    this.lastMessage,
    this.lastMessageText,
    this.lastMessageAt,
    this.manualReason,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String status;
  final String mode;
  final String modeSource;
  final String effectiveMode;
  final List<ChatMessageModel> messages;
  final AdminChatUser? user;
  final String? assignedAdminId;
  final bool unreadByAdmin;
  final bool unreadByUser;
  final ChatMessageModel? lastMessage;
  final String? lastMessageText;
  final String? lastMessageAt;
  final String? manualReason;
  final String? updatedAt;

  AdminChatSession copyWith({
    String? status,
    String? mode,
    String? modeSource,
    String? effectiveMode,
    List<ChatMessageModel>? messages,
    bool? unreadByAdmin,
    bool? unreadByUser,
    ChatMessageModel? lastMessage,
    String? lastMessageText,
    bool clearLastMessageText = false,
    bool clearLastMessage = false,
    String? lastMessageAt,
    bool clearLastMessageAt = false,
    String? manualReason,
    bool clearManualReason = false,
    String? updatedAt,
  }) {
    return AdminChatSession(
      id: id,
      title: title,
      status: status ?? this.status,
      mode: mode ?? this.mode,
      modeSource: modeSource ?? this.modeSource,
      effectiveMode: effectiveMode ?? this.effectiveMode,
      messages: messages ?? this.messages,
      user: user,
      assignedAdminId: assignedAdminId,
      unreadByAdmin: unreadByAdmin ?? this.unreadByAdmin,
      unreadByUser: unreadByUser ?? this.unreadByUser,
      lastMessage: clearLastMessage ? null : (lastMessage ?? this.lastMessage),
      lastMessageText: clearLastMessageText
          ? null
          : (lastMessageText ?? this.lastMessageText),
      lastMessageAt:
          clearLastMessageAt ? null : (lastMessageAt ?? this.lastMessageAt),
      manualReason:
          clearManualReason ? null : (manualReason ?? this.manualReason),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory AdminChatSession.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] ?? json['userId'];
    final lastMessageJson = json['lastMessage'];
    return AdminChatSession(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Cuộc trò chuyện').toString(),
      status: (json['status'] ?? 'active').toString(),
      mode: (json['mode'] ?? 'AI_AUTO').toString(),
      modeSource: (json['modeSource'] ?? 'GLOBAL').toString(),
      effectiveMode:
          (json['effectiveMode'] ?? json['mode'] ?? 'AI_AUTO').toString(),
      messages: (json['messages'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => ChatMessageModel.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList(),
      user: userJson is Map
          ? AdminChatUser.fromJson(Map<String, dynamic>.from(userJson))
          : null,
      assignedAdminId: json['assignedAdminId']?.toString(),
      unreadByAdmin: json['unreadByAdmin'] == true,
      unreadByUser: json['unreadByUser'] == true,
      lastMessage: lastMessageJson is Map
          ? ChatMessageModel.fromJson(
              Map<String, dynamic>.from(lastMessageJson),
            )
          : null,
      lastMessageText: lastMessageJson is Map
          ? lastMessageJson['content']?.toString()
          : lastMessageJson?.toString(),
      lastMessageAt: (json['lastMessageAt'] ?? json['updatedAt'])?.toString(),
      manualReason: json['manualReason']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }
}

class AdminPage<T> {
  const AdminPage({required this.items, required this.pagination});

  final List<T> items;
  final AdminPagination pagination;
}

class AdminDashboardStats {
  const AdminDashboardStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.bannedUsers,
    required this.repositories,
    required this.analyses,
    required this.aiFeedback,
    required this.activeRoadmaps,
    required this.pendingReports,
  });

  final int totalUsers;
  final int activeUsers;
  final int bannedUsers;
  final int repositories;
  final int analyses;
  final int aiFeedback;
  final int activeRoadmaps;
  final int pendingReports;

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) {
    final users = json['users'] is Map
        ? Map<String, dynamic>.from(json['users'] as Map)
        : <String, dynamic>{};
    final github = json['github'] is Map
        ? Map<String, dynamic>.from(json['github'] as Map)
        : <String, dynamic>{};
    final analysis = json['analysis'] is Map
        ? Map<String, dynamic>.from(json['analysis'] as Map)
        : <String, dynamic>{};
    final feedback = json['aiFeedback'] is Map
        ? Map<String, dynamic>.from(json['aiFeedback'] as Map)
        : <String, dynamic>{};
    final roadmaps = json['roadmaps'] is Map
        ? Map<String, dynamic>.from(json['roadmaps'] as Map)
        : <String, dynamic>{};
    final reports = json['reports'] is Map
        ? Map<String, dynamic>.from(json['reports'] as Map)
        : <String, dynamic>{};

    int n(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;

    return AdminDashboardStats(
      totalUsers: n(users['total']),
      activeUsers: n(users['active']),
      bannedUsers: n(users['banned']),
      repositories: n(github['repositories']),
      analyses: n(analysis['total']),
      aiFeedback: n(feedback['total']),
      activeRoadmaps: n(roadmaps['active']),
      pendingReports: n(reports['pending']),
    );
  }
}

class AdminUserRecord {
  const AdminUserRecord({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.provider,
    this.avatar,
    this.githubUsername,
    this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String status;
  final String provider;
  final String? avatar;
  final String? githubUsername;
  final String? createdAt;

  factory AdminUserRecord.fromJson(Map<String, dynamic> json) {
    return AdminUserRecord(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? json['fullName'] ?? 'User').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? 'student').toString(),
      status: (json['status'] ?? 'active').toString(),
      provider: (json['provider'] ?? 'local').toString(),
      avatar: json['avatar']?.toString() ?? json['avatarUrl']?.toString(),
      githubUsername: json['githubUsername']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }
}

class AdminReportRecord {
  const AdminReportRecord({
    required this.id,
    required this.targetType,
    required this.reason,
    required this.status,
    this.targetId,
    this.description,
    this.adminNote,
    this.reporterName,
    this.reporterEmail,
    this.createdAt,
    this.resolvedAt,
  });

  final String id;
  final String targetType;
  final String? targetId;
  final String reason;
  final String? description;
  final String status;
  final String? adminNote;
  final String? reporterName;
  final String? reporterEmail;
  final String? createdAt;
  final String? resolvedAt;

  factory AdminReportRecord.fromJson(Map<String, dynamic> json) {
    final reporter = json['reporterId'];
    final reporterMap =
        reporter is Map ? Map<String, dynamic>.from(reporter) : null;

    return AdminReportRecord(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      targetType: (json['targetType'] ?? 'other').toString(),
      targetId: json['targetId']?.toString(),
      reason: (json['reason'] ?? '').toString(),
      description: json['description']?.toString(),
      status: (json['status'] ?? 'pending').toString(),
      adminNote: json['adminNote']?.toString(),
      reporterName: reporterMap?['name']?.toString() ??
          reporterMap?['fullName']?.toString(),
      reporterEmail: reporterMap?['email']?.toString(),
      createdAt: json['createdAt']?.toString(),
      resolvedAt: json['resolvedAt']?.toString(),
    );
  }
}

class AdminRepoRecord {
  const AdminRepoRecord({
    required this.id,
    required this.name,
    required this.fullName,
    required this.language,
    required this.ownerName,
    this.ownerEmail,
    this.stars,
    this.forks,
    this.openIssues,
    this.sizeKb,
    this.updatedAt,
    this.description,
    this.defaultBranch,
    this.githubRepoId,
    this.htmlUrl,
    this.cloneUrl,
    this.homepage,
    this.isPrivate = false,
    this.isFork = false,
    this.topics = const [],
    this.lastSyncedAt,
    this.createdAt,
    this.pushedAt,
    this.rawData = const {},
  });

  final String id;
  final String name;
  final String fullName;
  final String language;
  final String ownerName;
  final String? ownerEmail;
  final int? stars;
  final int? forks;
  final int? openIssues;
  final int? sizeKb;
  final String? updatedAt;
  final String? description;
  final String? defaultBranch;
  final int? githubRepoId;
  final String? htmlUrl;
  final String? cloneUrl;
  final String? homepage;
  final bool isPrivate;
  final bool isFork;
  final List<String> topics;
  final String? lastSyncedAt;
  final String? createdAt;
  final String? pushedAt;
  final Map<String, dynamic> rawData;

  bool? rawBool(String key) {
    final value = rawData[key];
    return value is bool ? value : null;
  }

  factory AdminRepoRecord.fromJson(Map<String, dynamic> json) {
    final user = json['userId'];
    final userMap = user is Map ? Map<String, dynamic>.from(user) : null;
    final raw = json['rawData'] is Map
        ? Map<String, dynamic>.from(json['rawData'] as Map)
        : <String, dynamic>{};

    List<String> topics(dynamic value) {
      if (value is! List) return const [];
      return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }

    return AdminRepoRecord(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      fullName: (json['fullName'] ?? json['name'] ?? '').toString(),
      language: (json['language'] ?? '-').toString(),
      ownerName: userMap?['name']?.toString() ??
          userMap?['fullName']?.toString() ??
          '—',
      ownerEmail: userMap?['email']?.toString(),
      stars: int.tryParse(json['stargazersCount']?.toString() ?? ''),
      forks: int.tryParse(json['forksCount']?.toString() ?? ''),
      openIssues: int.tryParse(json['openIssuesCount']?.toString() ?? ''),
      sizeKb: int.tryParse(json['size']?.toString() ?? ''),
      updatedAt:
          json['updatedAtGithub']?.toString() ?? json['updatedAt']?.toString(),
      description: json['description']?.toString(),
      defaultBranch: json['defaultBranch']?.toString(),
      githubRepoId: int.tryParse(json['githubRepoId']?.toString() ?? ''),
      htmlUrl: json['htmlUrl']?.toString() ?? raw['html_url']?.toString(),
      cloneUrl: raw['clone_url']?.toString(),
      homepage: raw['homepage']?.toString(),
      isPrivate: json['private'] == true,
      isFork: json['fork'] == true,
      topics: topics(json['topics']),
      lastSyncedAt: json['lastSyncedAt']?.toString(),
      createdAt: json['createdAt']?.toString(),
      pushedAt: json['pushedAt']?.toString(),
      rawData: raw,
    );
  }
}

class AdminAnalysisRecord {
  const AdminAnalysisRecord({
    required this.id,
    required this.repoName,
    required this.projectType,
    required this.careerDirection,
    required this.ownerName,
    this.ownerEmail,
    this.overallScore,
    this.analyzedAt,
    this.languages = const [],
    this.frameworks = const [],
    this.packages = const [],
    this.strengths = const [],
    this.weaknesses = const [],
    this.missingSkills = const [],
    this.recommendations = const [],
    this.skillSignals = const [],
    this.scores = const {},
    this.checklist = const {},
    this.commitSummary = const {},
    this.analysisScope = const {},
  });

  final String id;
  final String repoName;
  final String projectType;
  final String careerDirection;
  final String ownerName;
  final String? ownerEmail;
  final int? overallScore;
  final String? analyzedAt;
  final List<String> languages;
  final List<String> frameworks;
  final List<String> packages;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> missingSkills;
  final List<String> recommendations;
  final List<String> skillSignals;
  final Map<String, int> scores;
  final Map<String, bool> checklist;
  final Map<String, dynamic> commitSummary;
  final Map<String, dynamic> analysisScope;

  factory AdminAnalysisRecord.fromJson(Map<String, dynamic> json) {
    final user = json['userId'];
    final userMap = user is Map ? Map<String, dynamic>.from(user) : null;
    final repository = json['repositoryId'];
    final repositoryMap =
        repository is Map ? Map<String, dynamic>.from(repository) : null;
    final scoresMap = json['scores'] is Map
        ? Map<String, dynamic>.from(json['scores'] as Map)
        : null;
    final checklistMap = json['checklist'] is Map
        ? Map<String, dynamic>.from(json['checklist'] as Map)
        : null;
    final commitMap = json['commitSummary'] is Map
        ? Map<String, dynamic>.from(json['commitSummary'] as Map)
        : null;
    final analysisScopeMap = json['analysisScope'] is Map
        ? Map<String, dynamic>.from(json['analysisScope'] as Map)
        : null;

    List<String> listOf(dynamic value) {
      if (value is! List) return const [];
      return value
          .map((item) {
            if (item is Map) {
              final map = Map<String, dynamic>.from(item);
              return (map['skill'] ??
                      map['canonicalSkillName'] ??
                      map['name'] ??
                      map['title'] ??
                      '')
                  .toString();
            }
            return item.toString();
          })
          .where((item) => item.isNotEmpty)
          .toList();
    }

    final scores = <String, int>{};
    scoresMap?.forEach((key, value) {
      final parsed = value is num
          ? value.round()
          : num.tryParse(value?.toString() ?? '')?.round();
      if (parsed != null) scores[key] = parsed;
    });

    final checklist = <String, bool>{};
    checklistMap?.forEach((key, value) {
      if (value is bool) checklist[key] = value;
    });

    return AdminAnalysisRecord(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      repoName: (json['repoName'] ??
              repositoryMap?['name'] ??
              json['fullName'] ??
              repositoryMap?['fullName'] ??
              'Repo')
          .toString(),
      projectType: (json['projectType'] ?? '-').toString(),
      careerDirection: (json['careerDirection'] ?? '-').toString(),
      ownerName: userMap?['name']?.toString() ??
          userMap?['fullName']?.toString() ??
          '—',
      ownerEmail: userMap?['email']?.toString(),
      overallScore: scores['overallScore'] ??
          int.tryParse(scoresMap?['overall']?.toString() ?? ''),
      analyzedAt:
          json['analyzedAt']?.toString() ?? json['createdAt']?.toString(),
      languages: listOf(json['languages']),
      frameworks: listOf(json['frameworks']),
      packages: listOf(json['packages']),
      strengths: listOf(json['strengths']),
      weaknesses: listOf(json['weaknesses']),
      missingSkills: listOf(json['skillSignals']),
      recommendations: listOf(json['recommendations']),
      skillSignals: listOf(json['skillSignals']),
      scores: scores,
      checklist: checklist,
      commitSummary: commitMap ?? const {},
      analysisScope: analysisScopeMap ?? const {},
    );
  }
}

class AdminFeedbackRecord {
  const AdminFeedbackRecord({
    required this.id,
    required this.repoName,
    required this.summary,
    required this.careerDirection,
    required this.ownerName,
    this.ownerEmail,
    this.generatedAt,
    this.projectType,
    this.strengthFeedback = const [],
    this.weaknessFeedback = const [],
    this.learningAdvice,
    this.nextSteps = const [],
    this.recommendedTopics = const [],
    this.careerSuggestion,
    this.portfolioAdvice,
    this.riskNotes = const [],
    this.createdAt,
  });

  final String id;
  final String repoName;
  final String summary;
  final String careerDirection;
  final String ownerName;
  final String? ownerEmail;
  final String? generatedAt;
  final String? projectType;
  final List<String> strengthFeedback;
  final List<String> weaknessFeedback;
  final String? learningAdvice;
  final List<String> nextSteps;
  final List<String> recommendedTopics;
  final String? careerSuggestion;
  final String? portfolioAdvice;
  final List<String> riskNotes;
  final String? createdAt;

  factory AdminFeedbackRecord.fromJson(Map<String, dynamic> json) {
    final user = json['userId'];
    final userMap = user is Map ? Map<String, dynamic>.from(user) : null;

    List<String> listOf(dynamic value) {
      if (value is! List) return const [];
      return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }

    return AdminFeedbackRecord(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      repoName: (json['repoName'] ?? json['fullName'] ?? 'Repo').toString(),
      summary: (json['summary'] ?? '').toString(),
      careerDirection: (json['careerDirection'] ?? '-').toString(),
      ownerName: userMap?['name']?.toString() ??
          userMap?['fullName']?.toString() ??
          '—',
      ownerEmail: userMap?['email']?.toString(),
      generatedAt: json['generatedAt']?.toString(),
      projectType: json['projectType']?.toString(),
      strengthFeedback: listOf(json['strengthFeedback']),
      weaknessFeedback: listOf(json['weaknessFeedback']),
      learningAdvice: json['learningAdvice']?.toString(),
      nextSteps: listOf(json['nextSteps']),
      recommendedTopics: listOf(json['recommendedTopics']),
      careerSuggestion: json['careerSuggestion']?.toString(),
      portfolioAdvice: json['portfolioAdvice']?.toString(),
      riskNotes: listOf(json['riskNotes']),
      createdAt: json['createdAt']?.toString(),
    );
  }
}

class AdminRoadmapRecord {
  const AdminRoadmapRecord({
    required this.id,
    required this.title,
    required this.targetRole,
    required this.status,
    required this.progressSummary,
    this.user,
    this.repository,
    this.isDeleted = false,
    this.deletedAt,
    this.requestedLevel,
    this.effectiveLevel,
    this.durationWeeks,
    this.language,
    this.mainPath,
    this.supportingPaths = const [],
    this.learningProgress,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String targetRole;
  final String status;
  final AdminRoadmapUser? user;
  final AdminRoadmapRepository? repository;
  final bool isDeleted;
  final String? deletedAt;
  final String? requestedLevel;
  final String? effectiveLevel;
  final int? durationWeeks;
  final String? language;
  final AdminRoadmapProgressSummary progressSummary;
  final AdminRoadmapPath? mainPath;
  final List<AdminRoadmapPath> supportingPaths;
  final AdminRoadmapLearningProgress? learningProgress;
  final String? createdAt;
  final String? updatedAt;

  String get ownerName =>
      user?.displayName.isNotEmpty == true ? user!.displayName : 'Unknown user';

  String? get ownerEmail => user?.email.isNotEmpty == true ? user!.email : null;

  int get phaseCount => mainPath?.phases.length ?? 0;

  int get taskCount =>
      mainPath?.phases.fold<int>(0, (sum, p) => sum + p.tasks.length) ?? 0;

  int get hourCount =>
      mainPath?.phases.fold<int>(0, (sum, p) => sum + p.estimatedHours) ?? 0;

  int get repositoriesCount => repository == null ? 0 : 1;

  factory AdminRoadmapRecord.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final userMap = user is Map ? Map<String, dynamic>.from(user) : null;
    final repository = json['repository'];
    final mainPathRaw = json['mainRoadmap'];
    final supportingRaw = json['alternativeRoadmaps'];
    final progressRaw = json['progressSummary'];
    final learningRaw = json['learningProgress'];
    final title = (json['title'] ?? '').toString();

    return AdminRoadmapRecord(
      id: (json['roadmapId'] ?? '').toString(),
      title: title.isNotEmpty ? title : (json['targetRole'] ?? '-').toString(),
      targetRole: (json['targetRole'] ?? '-').toString(),
      status: (json['status'] ?? 'active').toString(),
      user: userMap == null ? null : AdminRoadmapUser.fromJson(userMap),
      repository: repository is Map
          ? AdminRoadmapRepository.fromJson(
              Map<String, dynamic>.from(repository))
          : null,
      isDeleted: json['isDeleted'] == true,
      deletedAt: json['deletedAt']?.toString(),
      requestedLevel: json['requestedLevel']?.toString(),
      effectiveLevel: json['effectiveLevel']?.toString(),
      durationWeeks: int.tryParse(json['durationWeeks']?.toString() ?? ''),
      language: json['language']?.toString(),
      progressSummary: AdminRoadmapProgressSummary.fromJson(
        progressRaw is Map ? Map<String, dynamic>.from(progressRaw) : const {},
      ),
      mainPath: mainPathRaw is Map
          ? AdminRoadmapPath.fromJson(Map<String, dynamic>.from(mainPathRaw))
          : null,
      supportingPaths: supportingRaw is List
          ? supportingRaw
              .whereType<Map>()
              .map((e) =>
                  AdminRoadmapPath.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      learningProgress: learningRaw is Map
          ? AdminRoadmapLearningProgress.fromJson(
              Map<String, dynamic>.from(learningRaw))
          : null,
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }
}

class AdminRoadmapUser {
  const AdminRoadmapUser({
    required this.id,
    required this.name,
    required this.displayName,
    required this.email,
    required this.avatar,
    required this.status,
    required this.role,
  });

  final String id;
  final String name;
  final String displayName;
  final String email;
  final String avatar;
  final String status;
  final String role;

  factory AdminRoadmapUser.fromJson(Map<String, dynamic> json) =>
      AdminRoadmapUser(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        displayName: (json['displayName'] ?? json['name'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        avatar: (json['avatar'] ?? '').toString(),
        status: (json['status'] ?? '').toString(),
        role: (json['role'] ?? '').toString(),
      );
}

class AdminRoadmapRepository {
  const AdminRoadmapRepository({
    required this.id,
    required this.name,
    required this.fullName,
    required this.htmlUrl,
    required this.language,
  });

  final String id;
  final String name;
  final String fullName;
  final String htmlUrl;
  final String language;

  factory AdminRoadmapRepository.fromJson(Map<String, dynamic> json) =>
      AdminRoadmapRepository(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        fullName: (json['fullName'] ?? '').toString(),
        htmlUrl: (json['htmlUrl'] ?? '').toString(),
        language: (json['language'] ?? '').toString(),
      );
}

class AdminRoadmapProgressSummary {
  const AdminRoadmapProgressSummary({
    required this.totalItems,
    required this.completedItems,
    required this.inProgressItems,
    required this.pendingItems,
    required this.overallProgress,
  });

  final int totalItems;
  final int completedItems;
  final int inProgressItems;
  final int pendingItems;
  final int overallProgress;

  factory AdminRoadmapProgressSummary.fromJson(Map<String, dynamic> json) {
    int value(String key) => int.tryParse(json[key]?.toString() ?? '') ?? 0;
    return AdminRoadmapProgressSummary(
      totalItems: value('totalItems'),
      completedItems: value('completedItems'),
      inProgressItems: value('inProgressItems'),
      pendingItems: value('pendingItems'),
      overallProgress: value('overallProgress'),
    );
  }
}

class AdminRoadmapLearningProgress {
  const AdminRoadmapLearningProgress({
    this.currentTask,
    this.recentlyCompleted = const [],
    this.nextRecommendedTask,
    this.completedTasks = const [],
    this.inProgressTasks = const [],
    this.pendingTasks = const [],
    this.orphanProgressItems = const [],
    this.items = const [],
  });

  final AdminRoadmapLearningItem? currentTask;
  final List<AdminRoadmapLearningItem> recentlyCompleted;
  final AdminRoadmapLearningItem? nextRecommendedTask;
  final List<AdminRoadmapLearningItem> completedTasks;
  final List<AdminRoadmapLearningItem> inProgressTasks;
  final List<AdminRoadmapLearningItem> pendingTasks;
  final List<AdminRoadmapLearningItem> orphanProgressItems;
  final List<AdminRoadmapLearningItem> items;

  factory AdminRoadmapLearningProgress.fromJson(Map<String, dynamic> json) {
    AdminRoadmapLearningItem? item(dynamic value) => value is Map &&
            value.isNotEmpty
        ? AdminRoadmapLearningItem.fromJson(Map<String, dynamic>.from(value))
        : null;
    List<AdminRoadmapLearningItem> items(dynamic value) => value is List
        ? value
            .whereType<Map>()
            .map((e) =>
                AdminRoadmapLearningItem.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : const [];

    return AdminRoadmapLearningProgress(
      currentTask: item(json['currentTask']),
      recentlyCompleted: items(json['recentlyCompleted']),
      nextRecommendedTask: item(json['nextRecommendedTask']),
      completedTasks: items(json['completedTasks']),
      inProgressTasks: items(json['inProgressTasks']),
      pendingTasks: items(json['pendingTasks']),
      orphanProgressItems: items(json['orphanProgressItems']),
      items: items(json['items']),
    );
  }
}

class AdminRoadmapLearningItem {
  const AdminRoadmapLearningItem({
    required this.itemId,
    required this.title,
    required this.status,
    required this.progressPercent,
    this.description,
    this.skillName,
    this.canonicalSkillName,
    this.category,
    this.priority,
    this.week,
    this.phase,
    this.estimatedHours,
    this.startedAt,
    this.completedAt,
  });

  final String itemId;
  final String title;
  final String? description;
  final String? skillName;
  final String? canonicalSkillName;
  final String? category;
  final String? priority;
  final int? week;
  final String? phase;
  final int? estimatedHours;
  final String status;
  final int progressPercent;
  final String? startedAt;
  final String? completedAt;

  factory AdminRoadmapLearningItem.fromJson(Map<String, dynamic> json) =>
      AdminRoadmapLearningItem(
        itemId: (json['itemId'] ?? '').toString(),
        title: (json['title'] ?? json['itemId'] ?? 'Unknown task').toString(),
        description: json['description']?.toString(),
        skillName: json['skillName']?.toString(),
        canonicalSkillName: json['canonicalSkillName']?.toString(),
        category: json['category']?.toString(),
        priority: json['priority']?.toString(),
        week: int.tryParse(json['week']?.toString() ?? ''),
        phase: json['phase']?.toString(),
        estimatedHours: int.tryParse(json['estimatedHours']?.toString() ?? ''),
        status: (json['status'] ?? 'not_started').toString(),
        progressPercent:
            int.tryParse(json['progressPercent']?.toString() ?? '') ?? 0,
        startedAt: json['startedAt']?.toString(),
        completedAt: json['completedAt']?.toString(),
      );
}

class AdminRoadmapPath {
  const AdminRoadmapPath({
    this.title,
    this.reason,
    this.phases = const [],
  });

  final String? title;
  final String? reason;
  final List<AdminRoadmapPhase> phases;

  factory AdminRoadmapPath.fromJson(Map<String, dynamic> json) {
    final phasesRaw = json['phases'];
    return AdminRoadmapPath(
      title: json['title']?.toString(),
      reason: json['reason']?.toString(),
      phases: phasesRaw is List
          ? phasesRaw
              .whereType<Map>()
              .map((e) =>
                  AdminRoadmapPhase.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}

class AdminRoadmapPhase {
  const AdminRoadmapPhase({
    this.title,
    this.goal,
    this.skills = const [],
    this.tasks = const [],
    this.status,
  });

  final String? title;
  final String? goal;
  final List<String> skills;
  final List<AdminRoadmapTask> tasks;
  final String? status;

  int get estimatedHours =>
      tasks.fold<int>(0, (sum, t) => sum + t.estimatedHours);

  factory AdminRoadmapPhase.fromJson(Map<String, dynamic> json) {
    List<String> skills(dynamic value) {
      if (value is! List) return const [];
      return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }

    final tasksRaw = json['tasks'];
    return AdminRoadmapPhase(
      title: json['title']?.toString(),
      goal: json['goal']?.toString(),
      skills: skills(json['skills']),
      tasks: tasksRaw is List
          ? tasksRaw
              .whereType<Map>()
              .map((e) =>
                  AdminRoadmapTask.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      status: json['status']?.toString(),
    );
  }
}

class AdminRoadmapTask {
  const AdminRoadmapTask({
    this.title,
    this.description,
    this.estimatedHours = 0,
    this.status,
  });

  final String? title;
  final String? description;
  final int estimatedHours;
  final String? status;

  factory AdminRoadmapTask.fromJson(Map<String, dynamic> json) {
    return AdminRoadmapTask(
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      estimatedHours: json['estimatedHours'] is num
          ? (json['estimatedHours'] as num).toInt()
          : 0,
      status: json['status']?.toString(),
    );
  }
}
