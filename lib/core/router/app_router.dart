import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_controller.dart';
import '../../features/auth/login_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/drug_search/drug_search_screen.dart';
import '../../features/interaction_check/interaction_screen.dart';
import '../../features/medication_schedule/dose_history_screen.dart';
import '../../features/medication_schedule/schedule_screen.dart';
import '../../features/pdf_report/report_screen.dart';
import '../../features/pk_engine/presentation/pk_screen.dart';
import '../../features/settings/settings_screen.dart';

/// Centralised route names so feature code links via the constants
/// instead of stringly-typed paths.
class Routes {
  const Routes._();
  static const login = '/login';
  static const dashboard = '/';
  static const search = '/search';
  static const schedule = '/schedule';
  static const interactions = '/interactions';
  static const report = '/report';
  static const settings = '/settings';
  static const pk = '/pk';
}

/// Redirect logic: anonymous sessions are still allowed (local-first),
/// but if the user has explicitly opted out (locked the app) they must
/// pass through the lock screen.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.dashboard,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final goingToLogin = state.matchedLocation == Routes.login;
      if (auth.requiresUnlock && !goingToLogin) return Routes.login;
      if (!auth.requiresUnlock && goingToLogin) return Routes.dashboard;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.login,
        name: 'login',
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          name: state.name,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: Routes.dashboard,
        name: 'dashboard',
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          name: state.name,
          child: const DashboardScreen(),
        ),
        routes: [
          GoRoute(
            path: 'search',
            name: 'search',
            pageBuilder: (context, state) => CupertinoPage<void>(
              key: state.pageKey,
              name: state.name,
              child: const DrugSearchScreen(),
            ),
          ),
          GoRoute(
            path: 'schedule',
            name: 'schedule',
            pageBuilder: (context, state) => CupertinoPage<void>(
              key: state.pageKey,
              name: state.name,
              child: const ScheduleScreen(),
            ),
          ),
          GoRoute(
            path: 'interactions',
            name: 'interactions',
            pageBuilder: (context, state) => CupertinoPage<void>(
              key: state.pageKey,
              name: state.name,
              child: const InteractionScreen(),
            ),
          ),
          GoRoute(
            path: 'report',
            name: 'report',
            pageBuilder: (context, state) => CupertinoPage<void>(
              key: state.pageKey,
              name: state.name,
              child: const ReportScreen(),
            ),
          ),
          GoRoute(
            path: 'settings',
            name: 'settings',
            pageBuilder: (context, state) => CupertinoPage<void>(
              key: state.pageKey,
              name: state.name,
              child: const SettingsScreen(),
            ),
          ),
          GoRoute(
            path: 'pk/:drugId',
            name: 'pk',
            pageBuilder: (context, state) => CupertinoPage<void>(
              key: state.pageKey,
              name: state.name,
              child: PkScreen(
                drugId: state.pathParameters['drugId'] ?? '',
              ),
            ),
          ),
          GoRoute(
            path: 'dose-history/:drugId',
            name: 'dose-history',
            pageBuilder: (context, state) => CupertinoPage<void>(
              key: state.pageKey,
              name: state.name,
              child: DoseHistoryScreen(
                drugId: state.pathParameters['drugId'] ?? '',
              ),
            ),
          ),
        ],
      ),
    ],
  );
});
