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
}
