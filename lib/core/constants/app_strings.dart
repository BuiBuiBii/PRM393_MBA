/// Chuỗi UI dùng chung — tránh hard-code rải rác (tiêu chí tái sử dụng code).
class AppStrings {
  AppStrings._();

  static const String appName = 'GitAnalyzer AI';

  // Auth
  static const String loginTitle = 'Đăng nhập GitAnalyzer';
  static const String registerTitle = 'Tạo tài khoản';
  static const String welcomeBack = 'Chào mừng trở lại';
  static const String email = 'Email';
  static const String password = 'Mật phẩy';
  static const String login = 'Đăng nhập';
  static const String register = 'Đăng ký';
  static const String forgotPassword = 'Quên mật khẩu?';
  static const String orContinueWith = 'hoặc tiếp tục với';

  // Trạng thái chung
  static const String loading = 'Đang tải...';
  static const String retry = 'Thử lại';
  static const String emptyData = 'Chưa có dữ liệu';
  static const String errorGeneric = 'Đã có lỗi xảy ra';
  static const String networkError = 'Không thể kết nối máy chủ. Kiểm tra mạng và thử lại.';

  // Validation
  static const String emailRequired = 'Vui lòng nhập email';
  static const String emailInvalid = 'Email không hợp lệ';
  static const String passwordRequired = 'Vui lòng nhập mật khẩu';
  static const String passwordMinLength = 'Mật khẩu tối thiểu 6 ký tự';
}
