import '../../../shared/models/user_model.dart';

/// Khớp Web `getDefaultAuthenticatedPath` — admin → /admin, còn lại → /dashboard.
String getDefaultAuthenticatedPath(UserModel? user) {
  return user?.isAdmin == true ? '/admin' : '/dashboard';
}
