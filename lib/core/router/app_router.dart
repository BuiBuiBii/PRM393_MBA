import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/screens/admin_access_denied_screen.dart';
import '../../features/admin/screens/admin_ai_feedback_screen.dart';
import '../../features/admin/screens/admin_analysis_detail_screen.dart';
import '../../features/admin/screens/admin_analysis_screen.dart';
import '../../features/admin/screens/admin_ai_feedback_detail_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/admin_chat_detail_screen.dart';
import '../../features/admin/screens/admin_chat_screen.dart';
import '../../features/admin/screens/admin_report_detail_screen.dart';
import '../../features/admin/screens/admin_reports_screen.dart';
import '../../features/admin/screens/admin_repositories_screen.dart';
import '../../features/admin/screens/admin_repository_detail_screen.dart';
import '../../features/admin/screens/admin_roadmap_detail_screen.dart';
import '../../features/admin/screens/admin_roadmaps_screen.dart';
import '../../features/admin/screens/admin_shell.dart';
import '../../features/admin/screens/admin_user_detail_screen.dart';
import '../../features/admin/screens/admin_users_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/analysis/screens/analysis_result_screen.dart';
import '../../features/analysis/screens/snapshot_list_screen.dart';
import '../../features/analysis/screens/snapshot_detail_screen.dart';
import '../../features/analysis/screens/snapshot_compare_screen.dart';
import '../../features/analysis/screens/snapshot_select_repo_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/feedback/screens/ai_feedback_dashboard_screen.dart';
import '../../features/github/screens/github_auth_callback_screen.dart';
import '../../features/github/screens/github_callback_screen.dart';
import '../../features/github/screens/github_connect_screen.dart';
import '../../features/misc/screens/not_found_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/repositories/screens/repositories_screen.dart';
import '../../features/repositories/screens/repository_detail_screen.dart';
import '../../features/roadmaps/screens/roadmap_detail_screen.dart';
import '../../features/roadmaps/screens/roadmaps_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/shell/screens/main_shell.dart';
import 'app_navigator_keys.dart';
import 'auth_navigation.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefreshListenable(ref);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/dashboard',
    refreshListenable: refresh,
    errorBuilder: (_, __) => const NotFoundScreen(),
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final isBootstrapping = auth.status == AuthStatus.unknown;
      final isAuthenticated = auth.isAuthenticated;
      final loc = state.matchedLocation;
      final isAuthRoute = loc == '/login' || loc == '/register';
      final isGitHubCallback = loc.startsWith('/github/oauth/callback') ||
          loc.startsWith('/github/callback') ||
          loc.startsWith('/github/auth/callback') ||
          loc.startsWith('/auth/github/callback');
      final isPublicRoute = isAuthRoute || isGitHubCallback;
      final isAdminRoute = loc.startsWith('/admin');
      final isAdminDenied = loc == '/admin/denied';
      final isAdmin = auth.user?.isAdmin == true;

      if (isBootstrapping) return null;
      if (!isAuthenticated && !isPublicRoute) return '/login';
      if (isAuthenticated && isAuthRoute) {
        return getDefaultAuthenticatedPath(auth.user);
      }
      if (isAdminRoute && !isAdminDenied && isAuthenticated && !isAdmin) {
        return '/admin/denied';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
          path: '/github/oauth/callback',
          builder: (_, __) => const GitHubCallbackScreen()),
      GoRoute(
          path: '/github/callback',
          builder: (_, __) => const GitHubCallbackScreen()),
      GoRoute(
          path: '/github/auth/callback',
          builder: (_, __) => const GitHubAuthCallbackScreen()),
      GoRoute(
          path: '/auth/github/callback',
          builder: (_, __) => const GitHubAuthCallbackScreen()),
      GoRoute(
          path: '/admin/denied',
          builder: (_, __) => const AdminAccessDeniedScreen()),
      ShellRoute(
        navigatorKey: adminShellNavigatorKey,
        builder: (_, __, child) => AdminShell(child: child),
        routes: [
          GoRoute(
              path: '/admin', builder: (_, __) => const AdminDashboardScreen()),
          GoRoute(
              path: '/admin/users',
              builder: (_, __) => const AdminUsersScreen()),
          GoRoute(
            path: '/admin/users/:userId',
            builder: (_, state) =>
                AdminUserDetailScreen(userId: state.pathParameters['userId']!),
          ),
          GoRoute(
              path: '/admin/reports',
              builder: (_, __) => const AdminReportsScreen()),
          GoRoute(
            path: '/admin/reports/:reportId',
            builder: (_, state) => AdminReportDetailScreen(
                reportId: state.pathParameters['reportId']!),
          ),
          GoRoute(
              path: '/admin/repositories',
              builder: (_, __) => const AdminRepositoriesScreen()),
          GoRoute(
            path: '/admin/repositories/:repositoryId',
            builder: (_, state) => AdminRepositoryDetailScreen(
                repositoryId: state.pathParameters['repositoryId']!),
          ),
          GoRoute(
              path: '/admin/analysis',
              builder: (_, __) => const AdminAnalysisScreen()),
          GoRoute(
            path: '/admin/analysis/:analysisId',
            builder: (_, state) => AdminAnalysisDetailScreen(
                analysisId: state.pathParameters['analysisId']!),
          ),
          GoRoute(
              path: '/admin/ai-feedback',
              builder: (_, __) => const AdminAiFeedbackScreen()),
          GoRoute(
            path: '/admin/ai-feedback/:feedbackId',
            builder: (_, state) => AdminAiFeedbackDetailScreen(
                feedbackId: state.pathParameters['feedbackId']!),
          ),
          GoRoute(
              path: '/admin/roadmaps',
              builder: (_, __) => const AdminRoadmapsScreen()),
          GoRoute(
            path: '/admin/roadmaps/:roadmapId',
            builder: (_, state) => AdminRoadmapDetailScreen(
                roadmapId: state.pathParameters['roadmapId']!),
          ),
          GoRoute(
              path: '/admin/chat', builder: (_, __) => const AdminChatScreen()),
          GoRoute(
            path: '/admin/chat/:sessionId',
            builder: (_, state) => AdminChatDetailScreen(
              sessionId: state.pathParameters['sessionId']!,
            ),
          ),
        ],
      ),
      ShellRoute(
        navigatorKey: mainShellNavigatorKey,
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(
              path: '/dashboard', builder: (_, __) => const DashboardScreen()),
          GoRoute(
              path: '/repositories',
              builder: (_, __) => const RepositoriesScreen()),
          GoRoute(
              path: '/ai-feedback',
              builder: (_, __) => const AiFeedbackDashboardScreen()),
          GoRoute(
            path: '/repositories/:id',
            builder: (_, state) =>
                RepositoryDetailScreen(repoId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'analysis',
                builder: (_, state) =>
                    AnalysisResultScreen(repoId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: 'snapshots',
                builder: (_, state) =>
                    SnapshotListScreen(repoId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: 'progress',
                builder: (_, state) =>
                    SnapshotCompareScreen(repoId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/snapshots',
            builder: (_, __) => const SnapshotSelectRepoScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) => SnapshotDetailScreen(
                    snapshotId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
              path: '/analysis/:id',
              builder: (_, state) =>
                  AnalysisResultScreen(repoId: state.pathParameters['id']!)),
          GoRoute(
            path: '/chat',
            builder: (_, state) => ChatScreen(
              repositoryId: state.uri.queryParameters['repositoryId'],
              roadmapId: state.uri.queryParameters['roadmapId'],
              analysisId: state.uri.queryParameters['analysisId'],
              snapshotId: state.uri.queryParameters['snapshotId'],
            ),
          ),
          GoRoute(
              path: '/roadmaps', builder: (_, __) => const RoadmapsScreen()),
          GoRoute(
            path: '/roadmaps/:id',
            builder: (_, state) =>
                RoadmapDetailScreen(roadmapId: state.pathParameters['id']!),
          ),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          GoRoute(
              path: '/settings', builder: (_, __) => const SettingsScreen()),
          GoRoute(
              path: '/notifications',
              builder: (_, __) => const NotificationsScreen()),
          GoRoute(
              path: '/github/connect',
              builder: (_, __) => const GitHubConnectScreen()),
        ],
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});

class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(this.ref) {
    _subscription =
        ref.listen<AuthState>(authProvider, (_, __) => _notifyAuthChanged());
  }

  final Ref ref;
  late final ProviderSubscription<AuthState> _subscription;
  var _disposed = false;

  void _notifyAuthChanged() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription.close();
    super.dispose();
  }
}
