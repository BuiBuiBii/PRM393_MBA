import '../../core/network/api_utils.dart';
import '../../shared/models/app_models.dart';
import '../../shared/models/user_model.dart';

List<Map<String, dynamic>> asMapList(dynamic payload, [List<String> keys = const []]) {
  if (payload is List) {
    return payload.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
  final unwrapped = unwrapResponse<dynamic>(payload);
  if (unwrapped is List) {
    return unwrapped.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
  if (unwrapped is Map) {
    final map = Map<String, dynamic>.from(unwrapped);
    for (final key in keys) {
      if (map[key] is List) {
        return (map[key] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    }
    for (final key in ['items', 'data', 'repositories', 'results', 'analyses', 'sessions', 'notifications']) {
      if (map[key] is List) {
        return (map[key] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    }
  }
  return [];
}

List<dynamic> normalizeRepoPayloadList(dynamic payload) {
  final unwrapped = unwrapResponse<dynamic>(payload);
  if (unwrapped is List) return unwrapped;
  if (unwrapped is Map) {
    for (final key in ['files', 'packages', 'commits', 'items', 'data']) {
      final value = unwrapped[key];
      if (value is List) return List<dynamic>.from(value);
    }
  }
  return asMapList(payload, ['files', 'packages', 'commits', 'items']);
}

List<RepositoryModel> normalizeRepositories(dynamic payload) {
  return asMapList(payload, ['repositories', 'items']).map(RepositoryModel.fromJson).toList();
}

RepositoryModel normalizeRepository(dynamic payload) {
  final map = extractApiResource<Map<String, dynamic>>(payload, ['repository', 'repo']);
  return RepositoryModel.fromJson(toRecord(map.isNotEmpty ? map : payload));
}

List<AnalysisModel> normalizeAnalyses(dynamic payload) {
  return asMapList(payload, ['analyses', 'results', 'items']).map(AnalysisModel.fromJson).toList();
}

AnalysisModel normalizeAnalysis(dynamic payload) {
  final map = extractApiResource<Map<String, dynamic>>(payload, ['analysis', 'result']);
  return AnalysisModel.fromJson(toRecord(map.isNotEmpty ? map : payload));
}

List<ChatSessionModel> normalizeChatSessions(dynamic payload) {
  return asMapList(payload, ['sessions', 'chatSessions', 'items'])
      .map((item) => normalizeChatSession(item))
      .toList();
}

ChatSessionModel normalizeChatSession(dynamic payload) {
  final map = extractApiResource<Map<String, dynamic>>(payload, ['session', 'chatSession']);
  return ChatSessionModel.fromJson(toRecord(map.isNotEmpty ? map : payload));
}

ChatSessionModel normalizeChatSessionDetail(dynamic payload) {
  final record = toRecord(unwrapResponse<dynamic>(payload));
  final sessionMap = extractApiResource<Map<String, dynamic>>(record, ['session', 'chatSession']);
  var session = ChatSessionModel.fromJson(toRecord(sessionMap.isNotEmpty ? sessionMap : record));

  final messagesRaw = record['messages'] is List
      ? record['messages'] as List
      : (toRecord(record['data'])['messages'] is List ? toRecord(record['data'])['messages'] as List : null);

  if (messagesRaw != null && messagesRaw.isNotEmpty) {
    session = session.copyWith(
      messages: messagesRaw.whereType<Map>().map((e) => normalizeChatMessage(e)).toList(),
    );
  }
  return session;
}

ChatSessionModel mergeChatSession(ChatSessionModel base, ChatSessionModel next) {
  final merged = [...base.messages];
  for (final message in next.messages) {
    final index = merged.indexWhere((item) => item.id == message.id);
    if (index >= 0) {
      merged[index] = message;
    } else {
      merged.add(message);
    }
  }
  return ChatSessionModel(
    id: next.id.isNotEmpty ? next.id : base.id,
    title: next.title.isNotEmpty ? next.title : base.title,
    createdAt: next.createdAt.isNotEmpty ? next.createdAt : base.createdAt,
    messages: merged,
    repositoryContext: next.repositoryContext ?? base.repositoryContext,
  );
}

ChatMessageModel? pickAssistantMessage(dynamic payload) {
  final record = toRecord(unwrapResponse<dynamic>(payload));
  final data = toRecord(record['data']);

  final candidates = [
    record['assistantMessage'],
    data['assistantMessage'],
    record['aiMessage'],
    data['aiMessage'],
    record['reply'],
    data['reply'],
    record['answer'],
    data['answer'],
    record['aiResponse'],
    data['aiResponse'],
    record['response'],
    data['response'],
    record['message'],
    data['message'],
  ];

  for (final candidate in candidates) {
    if (candidate is String && candidate.trim().isNotEmpty) {
      return ChatMessageModel(
        id: 'assistant-${DateTime.now().millisecondsSinceEpoch}',
        role: 'assistant',
        content: candidate.trim(),
        timestamp: DateTime.now().toIso8601String(),
      );
    }

    final candidateRecord = toRecord(candidate);
    if (candidateRecord.isEmpty) continue;

    final nested = toRecord(candidateRecord['content']);
    final directText = [
      candidateRecord['answer'],
      candidateRecord['assistantResponse'],
      candidateRecord['aiResponse'],
      candidateRecord['response'],
      candidateRecord['reply'],
      candidateRecord['text'],
      candidateRecord['message'],
      candidateRecord['output'],
      nested['text'],
      nested['message'],
    ].whereType<String>().map((s) => s.trim()).firstWhere((s) => s.isNotEmpty, orElse: () => '');

    if (directText.isNotEmpty) {
      return ChatMessageModel(
        id: (candidateRecord['id'] ?? candidateRecord['_id'] ?? 'assistant-${DateTime.now().millisecondsSinceEpoch}').toString(),
        role: 'assistant',
        content: directText,
        timestamp: (candidateRecord['createdAt'] ?? DateTime.now().toIso8601String()).toString(),
      );
    }

    final message = normalizeChatMessage(candidateRecord);
    if (message.content.isNotEmpty) return message;
  }

  final messages = record['messages'] is List
      ? record['messages'] as List
      : (data['messages'] is List ? data['messages'] as List : null);
  if (messages != null) {
    for (final item in messages.reversed) {
      final message = normalizeChatMessage(item);
      if (message.role == 'assistant' && message.content.isNotEmpty) return message;
    }
  }
  return null;
}

ChatMessageModel normalizeChatMessage(dynamic payload) {
  final json = toRecord(payload);
  final rawRole = (json['role'] ?? json['sender'] ?? json['type'] ?? json['author'] ?? 'assistant')
      .toString()
      .toLowerCase();
  final role = ['user', 'human'].contains(rawRole) ? 'user' : 'assistant';
  final content = [
    json['content'],
    json['message'],
    json['text'],
    json['reply'],
    json['response'],
    json['aiResponse'],
  ].whereType<String>().map((s) => s.trim()).firstWhere((s) => s.isNotEmpty, orElse: () => '');

  return ChatMessageModel(
    id: (json['id'] ?? json['_id'] ?? 'message-${DateTime.now().millisecondsSinceEpoch}').toString(),
    role: role,
    content: content,
    timestamp: (json['timestamp'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()).toString(),
  );
}

UserModel normalizeUser(dynamic payload) {
  return UserModel.fromJson(toRecord(payload));
}

List<NotificationModel> normalizeNotifications(dynamic payload) {
  return asMapList(payload, ['notifications', 'items']).map(NotificationModel.fromJson).toList();
}

ProfileModel normalizeProfile(dynamic payload) {
  final map = extractApiResource<Map<String, dynamic>>(payload, ['profile', 'studentProfile']);
  return ProfileModel.fromJson(toRecord(map.isNotEmpty ? map : payload));
}

/// Chuẩn hóa payload `/dashboard/me` — hỗ trợ cả format cũ (flat) và mới (nested).
Map<String, dynamic> normalizeDashboard(dynamic payload) {
  final map = toRecord(unwrapResponse<dynamic>(payload));
  final github = map['github'];
  final repositories = map['repositories'];
  final skills = map['skills'];

  final githubMap = github is Map ? Map<String, dynamic>.from(github) : null;
  final repoMap = repositories is Map ? Map<String, dynamic>.from(repositories) : null;
  final skillsMap = skills is Map ? Map<String, dynamic>.from(skills) : null;

  return {
    ...map,
    'totalRepositories': map['totalRepositories'] ??
        map['repositoryCount'] ??
        repoMap?['total'],
    'analyzedRepositories': map['analyzedRepositories'] ??
        map['analysisCount'] ??
        repoMap?['analyzed'],
    'unanalyzedRepositories': map['unanalyzedRepositories'] ?? repoMap?['unanalyzed'],
    'githubConnected': map['githubConnected'] ?? githubMap?['connected'] ?? false,
    'githubUsername': map['githubUsername'] ?? githubMap?['username'],
    'strongSkills': map['strongSkills'] ?? skillsMap?['strong'] ?? const [],
    'missingSkills': map['missingSkills'] ?? skillsMap?['missing'] ?? const [],
    'suggestedCareerPath': map['suggestedCareerPath'],
    'roadmapProgress': map['roadmapProgress'] ?? 0,
    'latestAnalysisAt': map['latestAnalysisAt'],
  };
}

Map<String, dynamic> normalizeApiHealth(dynamic payload) {
  final map = toRecord(unwrapResponse<dynamic>(payload));
  return {
    ...map,
    'status': map['status'] ?? 'unknown',
    'environment': map['environment'],
  };
}

String mapRoadmapTaskStatus(String? status) {
  switch (status) {
    case 'completed':
      return 'completed';
    case 'in_progress':
      return 'in-progress';
    default:
      return 'unlocked';
  }
}

String categoryFromTargetRole(String targetRole) {
  if (targetRole.contains('Frontend')) return 'Frontend';
  if (targetRole.contains('Backend')) return 'Backend';
  if (targetRole.contains('Mobile')) return 'Mobile';
  if (targetRole.contains('DevOps')) return 'DevOps';
  if (targetRole.contains('Tester') || targetRole.contains('QA')) return 'Testing';
  if (targetRole.contains('AI') || targetRole.contains('Machine Learning')) return 'AI/ML';
  if (targetRole.contains('Data')) return 'Data';
  return 'Fullstack';
}

RoadmapModel normalizeRoadmap(dynamic payload) {
  final map = toRecord(extractApiResource<dynamic>(payload, ['roadmap']));
  final id = (map['_id'] ?? map['id'] ?? '').toString();
  final targetRole = (map['targetRole'] ?? '').toString();
  final summary = (map['summary'] ?? '').toString();
  final mainPath = map['mainPath'] is Map ? Map<String, dynamic>.from(map['mainPath'] as Map) : <String, dynamic>{};
  final phases = mainPath['phases'] as List? ?? [];

  var totalHours = 0;
  var completedTasks = 0;
  var totalTasks = 0;

  final modules = <RoadmapModuleModel>[];
  for (var phaseIndex = 0; phaseIndex < phases.length; phaseIndex++) {
    final phase = Map<String, dynamic>.from(phases[phaseIndex] as Map);
    final tasks = phase['tasks'] as List? ?? [];
    final nodes = <LearningNodeModel>[];
    for (var taskIndex = 0; taskIndex < tasks.length; taskIndex++) {
      final task = Map<String, dynamic>.from(tasks[taskIndex] as Map);
      final hours = int.tryParse(task['estimatedHours']?.toString() ?? '') ?? 4;
      totalHours += hours;
      totalTasks++;
      final status = task['status']?.toString() ?? 'not_started';
      if (status == 'completed') completedTasks++;
      nodes.add(LearningNodeModel(
        id: (task['_id'] ?? task['id'] ?? 'task-$phaseIndex-$taskIndex').toString(),
        title: (task['title'] ?? 'Task').toString(),
        description: (task['description'] ?? '').toString(),
        estimatedHours: hours,
        difficulty: 'Intermediate',
        status: mapRoadmapTaskStatus(status),
        skills: (task['skillTags'] as List? ?? []).map((e) => e.toString()).toList(),
        xp: hours * 40,
      ));
    }
    modules.add(RoadmapModuleModel(
      id: (phase['_id'] ?? phase['id'] ?? 'phase-$phaseIndex').toString(),
      title: (phase['title'] ?? 'Phase ${phaseIndex + 1}').toString(),
      description: (phase['goal'] ?? '').toString(),
      nodes: nodes,
    ));
  }

  final supporting = map['supportingPaths'] as List? ?? [];
  for (var i = 0; i < supporting.length; i++) {
    final path = Map<String, dynamic>.from(supporting[i] as Map);
    final suggested = path['suggestedTasks'] as List? ?? [];
    if (suggested.isEmpty) continue;
    modules.add(RoadmapModuleModel(
      id: (path['_id'] ?? 'support-$i').toString(),
      title: (path['title'] ?? 'Supporting Path').toString(),
      description: (path['reason'] ?? '').toString(),
      nodes: suggested.asMap().entries.map((entry) {
        return LearningNodeModel(
          id: 'support-$i-${entry.key}',
          title: entry.value.toString(),
          description: '',
          estimatedHours: 4,
          difficulty: 'Intermediate',
          status: 'locked',
          skills: (path['skills'] as List? ?? []).map((e) => e.toString()).toList(),
          xp: 160,
        );
      }).toList(),
    ));
  }

  final sourceCtx = map['sourceContextSummary'] is Map
      ? Map<String, dynamic>.from(map['sourceContextSummary'] as Map)
      : <String, dynamic>{};
  final detected = (sourceCtx['detectedSkills'] as List? ?? []).map((e) => e.toString()).toList();
  final missing = (sourceCtx['missingSkills'] as List? ?? []).map((e) => e.toString()).toList();
  final progress = totalTasks == 0 ? 0 : ((completedTasks / totalTasks) * 100).round();
  final estimatedWeeks = (totalHours / 8).ceil().clamp(1, 52);

  return RoadmapModel(
    id: id,
    slug: targetRole.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-'),
    title: (mainPath['title'] ?? targetRole).toString(),
    subtitle: targetRole,
    description: summary.isNotEmpty ? summary : (mainPath['reason'] ?? '').toString(),
    category: categoryFromTargetRole(targetRole),
    difficulty: 'Intermediate',
    estimatedWeeks: estimatedWeeks,
    estimatedHours: totalHours > 0 ? totalHours : estimatedWeeks * 8,
    tags: [...detected, ...missing].take(8).toList(),
    isFeatured: false,
    isAIRecommended: true,
    progress: progress,
    modules: modules,
    careerOutcome: targetRole,
    status: (map['status'] ?? 'active').toString(),
  );
}

List<RoadmapModel> normalizeRoadmaps(dynamic payload) {
  return asMapList(payload, ['roadmaps', 'items']).map(normalizeRoadmap).toList();
}

AIRecommendationModel normalizeAiRecommendation(RoadmapModel roadmap, {List<String>? strengths, List<String>? weaknesses, List<String>? missingSkills}) {
  final detected = strengths ?? roadmap.tags;
  final missing = missingSkills ?? (detected.length > 4 ? detected.skip(4).toList() : <String>[]);
  return AIRecommendationModel(
    summary: roadmap.description,
    confidence: 82,
    strengths: detected.take(4).toList(),
    weaknesses: weaknesses ?? [],
    missingSkills: missing,
    careerSuggestion: roadmap.careerOutcome,
    estimatedCompletionWeeks: roadmap.estimatedWeeks,
    roadmap: roadmap,
  );
}

AiFeedbackModel normalizeAiFeedback(dynamic payload) {
  final map = extractApiResource<Map<String, dynamic>>(payload, ['feedback', 'aiFeedback', 'result']);
  return AiFeedbackModel.fromJson(toRecord(map.isNotEmpty ? map : payload));
}

List<AiFeedbackModel> normalizeAiFeedbacks(dynamic payload) {
  return asMapList(payload, ['feedbacks', 'items', 'results']).map(normalizeAiFeedback).toList();
}

LearningStatsModel computeLearningStats(List<RoadmapModel> roadmaps) {
  var completedNodes = 0;
  var totalNodes = 0;
  var totalHours = 0;
  final activeIds = <String>[];

  for (final roadmap in roadmaps) {
    if (roadmap.id.isNotEmpty) activeIds.add(roadmap.id);
    for (final module in roadmap.modules) {
      for (final node in module.nodes) {
        totalNodes++;
        totalHours += node.estimatedHours;
        if (node.status == 'completed') completedNodes++;
      }
    }
  }

  return LearningStatsModel(
    activeRoadmapIds: activeIds,
    completedNodes: completedNodes,
    totalNodes: totalNodes,
    totalXp: completedNodes * 120,
    level: (completedNodes / 5).floor() + 1,
    currentStreak: 0,
    weeklyGoalHours: 10,
    weeklyHoursCompleted: totalHours.clamp(0, 10),
    bookmarkedNodeIds: const [],
  );
}

List<SkillProgressModel> computeSkillProgress(List<RoadmapModel> roadmaps) {
  final counts = <String, int>{};
  for (final roadmap in roadmaps) {
    for (final tag in roadmap.tags) {
      counts[tag] = (counts[tag] ?? 0) + 1;
    }
  }
  if (counts.isEmpty) return const [];
  return counts.entries
      .map((entry) => SkillProgressModel(
            skill: entry.key,
            category: 'GitHub',
            current: (entry.value * 15).clamp(10, 90),
            target: 100,
          ))
      .toList();
}
