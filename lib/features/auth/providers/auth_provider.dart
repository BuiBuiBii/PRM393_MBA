import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/social_auth_service.dart';
import '../../../core/network/app_api.dart';
import '../../../core/network/api_utils.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/models/app_models.dart';
import '../data/auth_repository.dart';
import '../../../shared/models/user_model.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import '../../../core/config/app_config.dart';
import '../../../core/demo/demo_data.dart';
import '../../../core/demo/demo_service.dart';

enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
}

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.profile,
    this.isLoading = false,
    this.error,
  });

  final AuthStatus status;
  final UserModel? user;
  final ProfileModel? profile;
  final bool isLoading;
  final String? error;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    ProfileModel? profile,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  late AuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.read(authRepositoryProvider);
    Future.microtask(bootstrap);
    return const AuthState(status: AuthStatus.unknown);
  }

  Future<void> bootstrap() async {
    try {
      final storage = ref.read(tokenStorageProvider);
      final token = await storage.getToken();
      final cached = await storage.getUser();

      if (AppConfig.demoMode) {
        if (token == DemoData.demoToken && cached != null) {
          DemoService.instance.restoreSession();
          final user = UserModel.fromJson(cached);
          DemoService.instance.user = user;
          state = AuthState(status: AuthStatus.authenticated, user: user, profile: DemoService.instance.profile);
          return;
        }
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }

      if (cached != null) {
        state = state.copyWith(
          user: UserModel.fromJson(cached),
          status: AuthStatus.authenticated,
        );
      }

      final user = await safeRequest(_repository.bootstrap);
      if (user == null) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }

      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (error) {
      await ref.read(tokenStorageProvider).clear();
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: getApiErrorMessage(error),
      );
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (AppConfig.demoMode) {
        final user = await DemoService.instance.login(email: email.trim());
        final storage = ref.read(tokenStorageProvider);
        await storage.saveToken(DemoData.demoToken);
        await storage.saveUser(user.toJson());
        state = AuthState(status: AuthStatus.authenticated, user: user, profile: DemoService.instance.profile, isLoading: false);
        return;
      }
      final user = await safeRequest(() => _repository.login(email, password));
      state = AuthState(status: AuthStatus.authenticated, user: user, isLoading: false);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: getApiErrorMessage(error),
      );
      rethrow;
    }
  }

  Future<void> register(String email, String password, String fullName) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (AppConfig.demoMode) {
        final user = await DemoService.instance.register(email: email.trim(), fullName: fullName.trim());
        final storage = ref.read(tokenStorageProvider);
        await storage.saveToken(DemoData.demoToken);
        await storage.saveUser(user.toJson());
        state = AuthState(status: AuthStatus.authenticated, user: user, profile: DemoService.instance.profile, isLoading: false);
        return;
      }
      final user = await safeRequest(
        () => _repository.register(email, password, fullName),
      );
      state = AuthState(status: AuthStatus.authenticated, user: user, isLoading: false);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: getApiErrorMessage(error),
      );
      rethrow;
    }
  }

  Future<void> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (AppConfig.demoMode) {
        throw ApiException('Demo mode không hỗ trợ đăng nhập Google.');
      }
      final social = ref.read(socialAuthServiceProvider);
      final idToken = await social.signInWithGoogle();
      final user = await safeRequest(() => _repository.loginWithGoogle(idToken));
      state = AuthState(status: AuthStatus.authenticated, user: user, isLoading: false);
      await fetchProfile();
    } catch (error) {
      state = state.copyWith(isLoading: false, error: getApiErrorMessage(error));
      rethrow;
    }
  }

  Future<void> loginWithGithub() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (AppConfig.demoMode) {
        throw ApiException('Demo mode không hỗ trợ đăng nhập GitHub.');
      }
      final social = ref.read(socialAuthServiceProvider);
      final result = await social.signInWithGithub();
      final UserModel user;
      if (result.mode == GithubSignInMode.appToken) {
        user = await safeRequest(() => _repository.completeSocialLoginWithToken(result.value));
      } else {
        user = await safeRequest(() => _repository.loginWithGithub(result.value));
      }
      state = AuthState(status: AuthStatus.authenticated, user: user, isLoading: false);
      if (user.provider == 'github' || user.githubConnected) {
        await refreshGitHubAccount();
      }
    } catch (error) {
      state = state.copyWith(isLoading: false, error: getApiErrorMessage(error));
      rethrow;
    }
  }

  Future<void> completeGithubLoginWithToken(String token) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await safeRequest(() => _repository.completeSocialLoginWithToken(token));
      state = AuthState(status: AuthStatus.authenticated, user: user, isLoading: false);
      if (user.provider == 'github' || user.githubConnected) {
        await refreshGitHubAccount();
      }
    } catch (error) {
      state = state.copyWith(isLoading: false, error: getApiErrorMessage(error));
      rethrow;
    }
  }

  Future<void> logout() async {
    if (!AppConfig.demoMode) {
      try {
        await ref.read(socialAuthServiceProvider).signOutGoogle();
      } catch (_) {}
    }
    if (AppConfig.demoMode) {
      await DemoService.instance.logout();
      await ref.read(tokenStorageProvider).clear();
    } else {
      await _repository.logout();
    }
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> fetchProfile() async {
    try {
      if (AppConfig.demoMode) {
        state = state.copyWith(profile: await DemoService.instance.getProfile());
        return;
      }
      final api = ref.read(appApiProvider);
      final profile = await safeRequest(api.getProfile);
      state = state.copyWith(profile: profile);
    } catch (_) {}
  }

  Future<void> saveProfile(ProfileModel profile, {bool exists = false}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (AppConfig.demoMode) {
        final saved = await DemoService.instance.saveProfile(profile);
        state = state.copyWith(profile: saved, user: DemoService.instance.user, isLoading: false);
        await ref.read(tokenStorageProvider).saveUser(DemoService.instance.user.toJson());
        return;
      }
      final api = ref.read(appApiProvider);
      final saved = await safeRequest(() => api.saveProfile(profile, exists: exists));
      state = state.copyWith(profile: saved, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: getApiErrorMessage(error));
      rethrow;
    }
  }

  Future<void> changePassword(String current, String newPass, String confirm) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (AppConfig.demoMode) {
        await DemoService.instance.changePassword();
        state = state.copyWith(isLoading: false);
        return;
      }
      final api = ref.read(appApiProvider);
      await safeRequest(() => api.changePassword(
            currentPassword: current,
            newPassword: newPass,
            confirmPassword: confirm,
          ));
      state = state.copyWith(isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: getApiErrorMessage(error));
      rethrow;
    }
  }

  Future<void> connectGitHub() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (AppConfig.demoMode) {
        await DemoService.instance.connectGitHub();
        final user = DemoService.instance.user;
        state = state.copyWith(isLoading: false, user: user);
        await ref.read(tokenStorageProvider).saveUser(user.toJson());
        return;
      }
      final api = ref.read(appApiProvider);
      final redirectUri = 'gitanalyzer://github/connect';
      final payload = await safeRequest(() => api.getGitHubOAuthUrl(redirectUrl: redirectUri));
      print('PAYLOAD FROM getGitHubOAuthUrl: $payload');
      final url = payload['authUrl'] ?? payload['authorizeUrl'] ?? payload['authorizationUrl'] ?? payload['oauthUrl'] ?? payload['url'];
      if (url == null) throw ApiException('Backend không trả authorizeUrl');
      final absolute = url.toString().startsWith('http')
          ? url.toString()
          : '${Uri.parse(AppConfig.apiBaseUrl).origin}$url';
      
      final result = await FlutterWebAuth2.authenticate(
        url: absolute,
        callbackUrlScheme: Uri.parse(redirectUri).scheme,
      );

      final callback = Uri.parse(result);
      final error = callback.queryParameters['error'] ?? Uri.splitQueryString(callback.fragment)['error'];
      if (error != null && error.isNotEmpty) {
        throw ApiException(error);
      }

      state = state.copyWith(isLoading: false);
      await refreshGitHubAccount();
    } catch (error) {
      state = state.copyWith(isLoading: false, error: getApiErrorMessage(error));
      rethrow;
    }
  }

  Future<void> refreshGitHubAccount() async {
    try {
      if (AppConfig.demoMode) {
        final account = await DemoService.instance.getGitHubAccount();
        final user = state.user;
        if (user == null) return;
        final hasAccount = account.isNotEmpty;
        state = state.copyWith(
          user: user.copyWith(
            githubConnected: hasAccount,
            githubUsername: hasAccount ? account['username']?.toString() : null,
          ),
        );
        return;
      }
      final api = ref.read(appApiProvider);
      final account = extractApiResource<dynamic>(await api.getGitHubAccount(), ['githubAccount', 'github', 'account']);
      final hasAccount = account is Map && account.isNotEmpty;
      final user = state.user;
      if (user == null) return;
      if (hasAccount) {
        state = state.copyWith(
          user: user.copyWith(
            githubConnected: true,
            githubUsername: account['username']?.toString(),
          ),
        );
      } else {
        state = state.copyWith(user: user.copyWith(githubConnected: false, githubUsername: null));
      }
    } catch (_) {
      final user = state.user;
      if (user != null) {
        state = state.copyWith(user: user.copyWith(githubConnected: false));
      }
    }
  }

  Future<void> disconnectGitHub() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (AppConfig.demoMode) {
        await DemoService.instance.disconnectGitHub();
        final user = DemoService.instance.user;
        state = state.copyWith(isLoading: false, user: user);
        await ref.read(tokenStorageProvider).saveUser(user.toJson());
        return;
      }
      final api = ref.read(appApiProvider);
      await safeRequest(api.disconnectGitHub);
      final user = state.user;
      if (user != null) {
        state = state.copyWith(
          isLoading: false,
          user: user.copyWith(githubConnected: false, githubUsername: null),
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (error) {
      state = state.copyWith(isLoading: false, error: getApiErrorMessage(error));
      rethrow;
    }
  }
}

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(dioProvider));
});

final socialAuthServiceProvider = Provider<SocialAuthService>((ref) => SocialAuthService());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  return AuthRepository(
    api: ref.watch(authApiProvider),
    storage: storage,
  );
});

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

final appApiProvider = Provider<AppApi>((ref) => AppApi(ref.watch(dioProvider)));
