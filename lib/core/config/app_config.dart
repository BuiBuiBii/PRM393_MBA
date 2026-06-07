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

  /// Mặc định bật demo để test FE không cần BE.
  /// Tắt khi nối BE thật: flutter run --dart-define=DEMO_MODE=false
  static const bool demoMode = bool.fromEnvironment('DEMO_MODE', defaultValue: true);

  static const String demoEmail = 'demo@gitanalyzer.vn';
  static const String demoPassword = 'demo123';
}
