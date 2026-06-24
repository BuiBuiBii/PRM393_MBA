class AppConfig {
  static const String appName = 'GitAnalyzer AI';

  /// Override at build time:
  /// - Android emulator + BE local: --dart-define=API_BASE_URL=http://10.0.2.2:5000/api
  /// - API Render (mặc định): https://career-roadmap-api-zs7y.onrender.com/api
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://career-roadmap-api-zs7y.onrender.com/api',
  );

  /// BE chạy trên máy host, dùng khi develop với emulator.
  static const String localAndroidApiBaseUrl = 'http://10.0.2.2:5000/api';

  static const String tokenKey = 'gitanalyzer.jwt';
  static const String userKey = 'gitanalyzer.user';

  /// Bật demo (offline): flutter run --dart-define=DEMO_MODE=true
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

  /// Chỉ dùng nếu tự triển khai PKCE (không bắt buộc — login mặc định qua BE OAuth).
  static const String githubClientId = String.fromEnvironment('GITHUB_CLIENT_ID');
  static const String githubAuthRedirectUri = String.fromEnvironment(
    'GITHUB_AUTH_REDIRECT_URI',
    defaultValue: 'gitanalyzer://auth/github/callback',
  );

  static const String githubConnectRedirectUri = String.fromEnvironment(
    'GITHUB_CONNECT_REDIRECT_URI',
    defaultValue: 'gitanalyzer://github/connect',
  );

  static bool get isGoogleLoginConfigured => googleClientId.isNotEmpty;

  /// Login GitHub qua BE OAuth — không cần GITHUB_CLIENT_ID trong app.
  static bool get isGithubLoginConfigured => !demoMode;
}
