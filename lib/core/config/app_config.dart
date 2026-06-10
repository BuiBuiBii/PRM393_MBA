class AppConfig {
  static const String appName = 'GitAnalyzer AI';

  /// Override at build time:
  /// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000/api',
  );

  static const String tokenKey = 'gitanalyzer.jwt';
  static const String userKey = 'gitanalyzer.user';

  /// Bật demo: flutter run --dart-define=DEMO_MODE=true
  static const bool demoMode = bool.fromEnvironment('DEMO_MODE', defaultValue: false);

  /// Target roles khớp BE (/api/roadmaps/generate)
  static const List<String> targetRoles = [
    'Frontend Developer',
    'Backend Developer',
    'Fullstack Developer',
    'Mobile Developer',
    'Tester / QA Engineer',
    'DevOps Beginner',
    'Data Analyst',
    'AI / Machine Learning Beginner',
  ];

  static const String demoEmail = 'demo@gitanalyzer.vn';
  static const String demoPassword = 'demo123';

  /// Khớp BE GOOGLE_CLIENT_ID — dùng cho Google Sign-In (idToken).
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '970437677508-k1jc855q10hnl3sktcop9job68hgkd0r.apps.googleusercontent.com',
  );

  /// GitHub OAuth App — cần cho nút đăng nhập GitHub (khác OAuth kết nối repo trên BE).
  static const String githubClientId = String.fromEnvironment('GITHUB_CLIENT_ID');
  static const String githubClientSecret = String.fromEnvironment('GITHUB_CLIENT_SECRET');
  static const String githubAuthRedirectUri = String.fromEnvironment(
    'GITHUB_AUTH_REDIRECT_URI',
    defaultValue: 'gitanalyzer://github/auth/callback',
  );

  static bool get isGoogleLoginConfigured => googleClientId.isNotEmpty;
  static bool get isGithubLoginConfigured =>
      githubClientId.isNotEmpty && githubClientSecret.isNotEmpty;
}
