import '../../shared/models/app_models.dart';
import '../../shared/models/user_model.dart';
import 'demo_data.dart';

class DemoService {
  DemoService._();
  static final instance = DemoService._();

  UserModel user = DemoData.demoUser;
  ProfileModel profile = DemoData.demoProfile;
  List<RepositoryModel> repositories = List.of(DemoData.demoRepositories);
  List<AnalysisModel> analyses = List.of(DemoData.demoAnalyses);
  List<ChatSessionModel> chatSessions = List.of(DemoData.demoChatSessions);
  List<NotificationModel> notifications = List.of(DemoData.demoNotifications);
  var githubConnected = true;
  var _chatReplyIndex = 0;
  var _loggedIn = false;

  bool get isLoggedIn => _loggedIn;

  void restoreSession() => _loggedIn = true;

  Future<void> _delay() => Future<void>.delayed(const Duration(milliseconds: 350));

  void reset() {
    user = DemoData.demoUser;
    profile = DemoData.demoProfile;
    repositories = List.of(DemoData.demoRepositories);
    analyses = List.of(DemoData.demoAnalyses);
    chatSessions = List.of(DemoData.demoChatSessions);
    notifications = List.of(DemoData.demoNotifications);
    githubConnected = true;
    _chatReplyIndex = 0;
    _loggedIn = false;
  }

  Future<UserModel> login({String? email, String? fullName}) async {
    await _delay();
    _loggedIn = true;
    user = UserModel(
      id: user.id,
      email: email ?? DemoData.demoEmail,
      name: fullName ?? user.name,
      avatar: user.avatar,
      githubConnected: githubConnected,
      githubUsername: githubConnected ? 'alexjohnson' : null,
      createdAt: user.createdAt,
    );
    return user;
  }

  Future<UserModel> register({required String email, required String fullName}) async {
    await _delay();
    _loggedIn = true;
    user = UserModel(
      id: user.id,
      email: email,
      name: fullName,
      avatar: user.avatar,
      githubConnected: githubConnected,
      githubUsername: githubConnected ? 'alexjohnson' : null,
      createdAt: user.createdAt,
    );
    profile = ProfileModel(
      fullName: fullName,
      university: profile.university,
      major: profile.major,
      year: profile.year,
      targetCareer: profile.targetCareer,
      currentSkills: profile.currentSkills,
      githubUsername: profile.githubUsername,
    );
    return user;
  }

  Future<UserModel?> bootstrap() async {
    await _delay();
    if (!_loggedIn) return null;
    return user;
  }

  Future<void> logout() async {
    await _delay();
    reset();
  }

  Future<ProfileModel> getProfile() async {
    await _delay();
    return profile;
  }

  Future<ProfileModel> saveProfile(ProfileModel next) async {
    await _delay();
    profile = next;
    user = user.copyWith(name: next.fullName);
    return profile;
  }

  Future<void> changePassword() async => _delay();

  Future<Map<String, dynamic>> dashboardMe() async {
    await _delay();
    return DemoData.dashboardPayload();
  }

  Future<List<RepositoryModel>> getRepositories() async {
    await _delay();
    return List.of(repositories);
  }

  Future<List<RepositoryModel>> syncRepositories() async {
    await _delay();
    return List.of(repositories);
  }

  Future<RepositoryModel> getRepository(String id) async {
    await _delay();
    return repositories.firstWhere((r) => r.id == id);
  }

  Future<List<AnalysisModel>> getMyAnalyses() async {
    await _delay();
    return List.of(analyses);
  }

  Future<AnalysisModel?> getAnalysis(String id) async {
    await _delay();
    for (final a in analyses) {
      if (a.id == id || a.repositoryId == id) return a;
    }
    return null;
  }

  Future<AnalysisModel> analyzeRepository(String repoId) async {
    await _delay();
    final repo = repositories.firstWhere((r) => r.id == repoId);
    final template = analyses.first;
    final analysis = AnalysisModel(
      id: 'analysis-$repoId-${DateTime.now().millisecondsSinceEpoch}',
      repositoryId: repoId,
      repositoryName: repo.name,
      createdAt: DateTime.now().toIso8601String(),
      projectType: template.projectType,
      techStack: template.techStack,
      scores: template.scores,
      strengths: template.strengths,
      weaknesses: template.weaknesses,
      recommendations: template.recommendations,
      careerDirection: template.careerDirection,
    );
    analyses = [analysis, ...analyses.where((a) => a.repositoryId != repoId)];
    repositories = repositories
        .map((r) => r.id == repoId
            ? RepositoryModel(
                id: r.id,
                name: r.name,
                fullName: r.fullName,
                description: r.description,
                language: r.language,
                stars: r.stars,
                forks: r.forks,
                updatedAt: r.updatedAt,
                hasReadme: r.hasReadme,
                analyzed: true,
                analysisId: analysis.id,
                url: r.url,
                private: r.private,
              )
            : r)
        .toList();
    return analysis;
  }

  Future<List<ChatSessionModel>> getChatSessions() async {
    await _delay();
    return List.of(chatSessions);
  }

  Future<ChatSessionModel> createChatSession(String title) async {
    await _delay();
    final session = ChatSessionModel(
      id: 'chat-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      createdAt: DateTime.now().toIso8601String(),
      messages: const [],
    );
    chatSessions = [session, ...chatSessions];
    return session;
  }

  Future<ChatSessionModel> getChatSession(String id) async {
    await _delay();
    return chatSessions.firstWhere((s) => s.id == id);
  }

  Future<ChatSessionModel> sendChatMessage(String sessionId, String content) async {
    await _delay();
    final session = chatSessions.firstWhere((s) => s.id == sessionId);
    final reply = DemoData.demoChatReplies[_chatReplyIndex % DemoData.demoChatReplies.length];
    _chatReplyIndex++;
    final now = DateTime.now().toIso8601String();
    final updated = session.copyWith(
      messages: [
        ...session.messages,
        ChatMessageModel(id: 'user-$now', role: 'user', content: content, timestamp: now),
        ChatMessageModel(id: 'assistant-$now', role: 'assistant', content: reply, timestamp: now),
      ],
    );
    chatSessions = chatSessions.map((s) => s.id == sessionId ? updated : s).toList();
    return updated;
  }

  Future<List<NotificationModel>> getNotifications({bool unreadOnly = false, String? type}) async {
    await _delay();
    var items = List.of(notifications);
    if (unreadOnly) items = items.where((n) => !n.read).toList();
    if (type != null && type.isNotEmpty) items = items.where((n) => n.type == type).toList();
    return items;
  }

  Future<void> markNotificationRead(String id) async {
    await _delay();
    notifications = notifications
        .map((n) => n.id == id ? NotificationModel(id: n.id, title: n.title, message: n.message, type: n.type, read: true, createdAt: n.createdAt) : n)
        .toList();
  }

  Future<void> deleteNotification(String id) async {
    await _delay();
    notifications = notifications.where((n) => n.id != id).toList();
  }

  Future<void> createNotification({required String title, required String message, required String type}) async {
    await _delay();
    notifications = [
      NotificationModel(
        id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        message: message,
        type: type,
        read: false,
        createdAt: DateTime.now().toIso8601String(),
      ),
      ...notifications,
    ];
  }

  Future<Map<String, dynamic>> getGitHubAccount() async {
    await _delay();
    if (!githubConnected) return {};
    return {'username': 'alexjohnson', 'avatarUrl': user.avatar};
  }

  Future<void> connectGitHub() async {
    await _delay();
    githubConnected = true;
    user = user.copyWith(githubConnected: true, githubUsername: 'alexjohnson');
  }

  Future<void> disconnectGitHub() async {
    await _delay();
    githubConnected = false;
    user = user.copyWith(githubConnected: false, githubUsername: null);
  }
}
