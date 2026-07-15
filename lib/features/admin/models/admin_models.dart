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
    this.lastMessageAt,
    this.manualReason,
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
  final String? lastMessageAt;
  final String? manualReason;

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
      lastMessageAt: (json['lastMessageAt'] ?? json['updatedAt'])?.toString(),
      manualReason: json['manualReason']?.toString(),
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

  factory AdminAnalysisRecord.fromJson(Map<String, dynamic> json) {
    final user = json['userId'];
    final userMap = user is Map ? Map<String, dynamic>.from(user) : null;
    final scoresMap = json['scores'] is Map
        ? Map<String, dynamic>.from(json['scores'] as Map)
        : null;
    final checklistMap = json['checklist'] is Map
        ? Map<String, dynamic>.from(json['checklist'] as Map)
        : null;
    final commitMap = json['commitSummary'] is Map
        ? Map<String, dynamic>.from(json['commitSummary'] as Map)
        : null;

    List<String> listOf(dynamic value) {
      if (value is! List) return const [];
      return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }

    final scores = <String, int>{};
    scoresMap?.forEach((key, value) {
      final parsed = int.tryParse(value?.toString() ?? '');
      if (parsed != null) scores[key] = parsed;
    });

    final checklist = <String, bool>{};
    checklistMap?.forEach((key, value) {
      if (value is bool) checklist[key] = value;
    });

    return AdminAnalysisRecord(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      repoName: (json['repoName'] ?? json['fullName'] ?? 'Repo').toString(),
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
      missingSkills: listOf(json['missingSkills']),
      recommendations: listOf(json['recommendations']),
      skillSignals: listOf(json['skillSignals']),
      scores: scores,
      checklist: checklist,
      commitSummary: commitMap ?? const {},
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
    required this.targetRole,
    required this.status,
    required this.ownerName,
    this.ownerEmail,
    this.summary,
    this.currentGithubDirection,
    this.mainPath,
    this.supportingPaths = const [],
    this.sourceContextSummary,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String targetRole;
  final String status;
  final String ownerName;
  final String? ownerEmail;
  final String? summary;
  final String? currentGithubDirection;
  final AdminRoadmapPath? mainPath;
  final List<AdminRoadmapPath> supportingPaths;
  final AdminRoadmapSourceContext? sourceContextSummary;
  final String? createdAt;
  final String? updatedAt;

  String get title =>
      mainPath?.title?.isNotEmpty == true ? mainPath!.title! : targetRole;

  int get phaseCount => mainPath?.phases.length ?? 0;

  int get taskCount =>
      mainPath?.phases.fold<int>(0, (sum, p) => sum + p.tasks.length) ?? 0;

  int get hourCount =>
      mainPath?.phases.fold<int>(0, (sum, p) => sum + p.estimatedHours) ?? 0;

  int get repositoriesCount => sourceContextSummary?.repositoriesCount ?? 0;

  factory AdminRoadmapRecord.fromJson(Map<String, dynamic> json) {
    final user = json['userId'];
    final userMap = user is Map ? Map<String, dynamic>.from(user) : null;
    final mainPathRaw = json['mainPath'];
    final supportingRaw = json['supportingPaths'];
    final contextRaw = json['sourceContextSummary'];

    return AdminRoadmapRecord(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      targetRole: (json['targetRole'] ?? '-').toString(),
      status: (json['status'] ?? 'active').toString(),
      ownerName: userMap?['name']?.toString() ??
          userMap?['fullName']?.toString() ??
          '—',
      ownerEmail: userMap?['email']?.toString(),
      summary: json['summary']?.toString(),
      currentGithubDirection: json['currentGithubDirection']?.toString(),
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
      sourceContextSummary: contextRaw is Map
          ? AdminRoadmapSourceContext.fromJson(
              Map<String, dynamic>.from(contextRaw))
          : null,
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }
}

class AdminRoadmapSourceContext {
  const AdminRoadmapSourceContext({
    this.repositoriesCount = 0,
    this.detectedSkills = const [],
    this.missingSkills = const [],
  });

  final int repositoriesCount;
  final List<String> detectedSkills;
  final List<String> missingSkills;

  factory AdminRoadmapSourceContext.fromJson(Map<String, dynamic> json) {
    List<String> skills(dynamic value) {
      if (value is! List) return const [];
      return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }

    return AdminRoadmapSourceContext(
      repositoriesCount: json['repositoriesCount'] is num
          ? (json['repositoriesCount'] as num).toInt()
          : 0,
      detectedSkills: skills(json['detectedSkills']),
      missingSkills: skills(json['missingSkills']),
    );
  }
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
