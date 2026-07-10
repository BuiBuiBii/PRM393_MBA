/// Đường dẫn route tập trung — khớp go_router (tiêu chí navigation).
class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String repositories = '/repositories';
  static const String roadmaps = '/roadmaps';
  static const String chat = '/chat';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String githubConnect = '/github/connect';
  static const String admin = '/admin';
  static const String adminDenied = '/admin/denied';
  static const String notFound = '/404';

  static const String githubAuthCallback = '/auth/github/callback';
  static const String githubOAuthCallback = '/github/oauth/callback';

  static String repositoryDetail(String id) => '/repositories/$id';
  static String roadmapDetail(String id) => '/roadmaps/$id';
  static String analysisResult(String id) => '/analysis/$id';
}
