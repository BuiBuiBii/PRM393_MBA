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
    final users = json['users'] is Map ? Map<String, dynamic>.from(json['users'] as Map) : <String, dynamic>{};
    final github = json['github'] is Map ? Map<String, dynamic>.from(json['github'] as Map) : <String, dynamic>{};
    final analysis = json['analysis'] is Map ? Map<String, dynamic>.from(json['analysis'] as Map) : <String, dynamic>{};
    final feedback = json['aiFeedback'] is Map ? Map<String, dynamic>.from(json['aiFeedback'] as Map) : <String, dynamic>{};
    final roadmaps = json['roadmaps'] is Map ? Map<String, dynamic>.from(json['roadmaps'] as Map) : <String, dynamic>{};
    final reports = json['reports'] is Map ? Map<String, dynamic>.from(json['reports'] as Map) : <String, dynamic>{};

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
    final reporterMap = reporter is Map ? Map<String, dynamic>.from(reporter) : null;

    return AdminReportRecord(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      targetType: (json['targetType'] ?? 'other').toString(),
      targetId: json['targetId']?.toString(),
      reason: (json['reason'] ?? '').toString(),
      description: json['description']?.toString(),
      status: (json['status'] ?? 'pending').toString(),
      adminNote: json['adminNote']?.toString(),
      reporterName: reporterMap?['name']?.toString() ?? reporterMap?['fullName']?.toString(),
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
    this.updatedAt,
  });

  final String id;
  final String name;
  final String fullName;
  final String language;
  final String ownerName;
  final String? ownerEmail;
  final int? stars;
  final String? updatedAt;

  factory AdminRepoRecord.fromJson(Map<String, dynamic> json) {
    final user = json['userId'];
    final userMap = user is Map ? Map<String, dynamic>.from(user) : null;

    return AdminRepoRecord(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      fullName: (json['fullName'] ?? json['name'] ?? '').toString(),
      language: (json['language'] ?? '-').toString(),
      ownerName: userMap?['name']?.toString() ?? userMap?['fullName']?.toString() ?? '—',
      ownerEmail: userMap?['email']?.toString(),
      stars: int.tryParse(json['stargazersCount']?.toString() ?? ''),
      updatedAt: json['updatedAtGithub']?.toString() ?? json['updatedAt']?.toString(),
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
    this.overallScore,
    this.analyzedAt,
  });

  final String id;
  final String repoName;
  final String projectType;
  final String careerDirection;
  final String ownerName;
  final int? overallScore;
  final String? analyzedAt;

  factory AdminAnalysisRecord.fromJson(Map<String, dynamic> json) {
    final user = json['userId'];
    final userMap = user is Map ? Map<String, dynamic>.from(user) : null;
    final scores = json['scores'] is Map ? Map<String, dynamic>.from(json['scores'] as Map) : null;

    return AdminAnalysisRecord(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      repoName: (json['repoName'] ?? json['fullName'] ?? 'Repo').toString(),
      projectType: (json['projectType'] ?? '-').toString(),
      careerDirection: (json['careerDirection'] ?? '-').toString(),
      ownerName: userMap?['name']?.toString() ?? userMap?['fullName']?.toString() ?? '—',
      overallScore: int.tryParse(scores?['overall']?.toString() ?? ''),
      analyzedAt: json['analyzedAt']?.toString(),
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
    this.generatedAt,
  });

  final String id;
  final String repoName;
  final String summary;
  final String careerDirection;
  final String ownerName;
  final String? generatedAt;

  factory AdminFeedbackRecord.fromJson(Map<String, dynamic> json) {
    final user = json['userId'];
    final userMap = user is Map ? Map<String, dynamic>.from(user) : null;

    return AdminFeedbackRecord(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      repoName: (json['repoName'] ?? json['fullName'] ?? 'Repo').toString(),
      summary: (json['summary'] ?? '').toString(),
      careerDirection: (json['careerDirection'] ?? '-').toString(),
      ownerName: userMap?['name']?.toString() ?? userMap?['fullName']?.toString() ?? '—',
      generatedAt: json['generatedAt']?.toString(),
    );
  }
}

class AdminRoadmapRecord {
  const AdminRoadmapRecord({
    required this.id,
    required this.targetRole,
    required this.status,
    required this.ownerName,
    this.summary,
    this.updatedAt,
  });

  final String id;
  final String targetRole;
  final String status;
  final String ownerName;
  final String? summary;
  final String? updatedAt;

  factory AdminRoadmapRecord.fromJson(Map<String, dynamic> json) {
    final user = json['userId'];
    final userMap = user is Map ? Map<String, dynamic>.from(user) : null;

    return AdminRoadmapRecord(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      targetRole: (json['targetRole'] ?? '-').toString(),
      status: (json['status'] ?? 'active').toString(),
      ownerName: userMap?['name']?.toString() ?? userMap?['fullName']?.toString() ?? '—',
      summary: json['summary']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }
}
