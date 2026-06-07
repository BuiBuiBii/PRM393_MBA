import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/analysis/screens/analysis_result_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/github/screens/github_connect_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/misc/screens/not_found_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/progress/screens/progress_screen.dart';
import '../../features/repositories/screens/repositories_screen.dart';
import '../../features/repositories/screens/repository_detail_screen.dart';
import '../../features/roadmaps/screens/roadmaps_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/shell/screens/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: _AuthRefreshListenable(ref),
    redirect: (context, state) {
      final isBootstrapping = auth.status == AuthStatus.unknown;
      final isAuthenticated = auth.isAuthenticated;
      final loc = state.matchedLocation;
      final isAuthRoute = loc == '/login' || loc == '/register';

      if (isBootstrapping) return null;
      if (!isAuthenticated && !isAuthRoute) return '/login';
      if (isAuthenticated && isAuthRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      ShellRoute(
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/repositories', builder: (_, __) => const RepositoriesScreen()),
          GoRoute(
            path: '/repositories/:id',
            builder: (_, state) => RepositoryDetailScreen(repoId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'analysis',
                builder: (_, state) => AnalysisResultScreen(repoId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(path: '/analysis/:id', builder: (_, state) => AnalysisResultScreen(repoId: state.pathParameters['id']!)),
          GoRoute(path: '/chat', builder: (_, __) => const ChatScreen()),
          GoRoute(path: '/roadmaps', builder: (_, __) => const RoadmapsScreen()),
          GoRoute(path: '/roadmaps/ai', builder: (_, __) => const AIRoadmapScreen()),
          GoRoute(
            path: '/roadmaps/:id',
            builder: (_, state) => RoadmapDetailScreen(roadmapId: state.pathParameters['id']!),
          ),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
          GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
          GoRoute(path: '/progress', builder: (_, __) => const ProgressScreen()),
          GoRoute(path: '/github/connect', builder: (_, __) => const GitHubConnectScreen()),
          GoRoute(path: '/*', builder: (_, __) => const NotFoundScreen()),
        ],
      ),
    ],
  );
});

class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(this.ref) {
    ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }

  final Ref ref;
}
