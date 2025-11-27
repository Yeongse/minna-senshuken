import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'main_shell.dart';
import '../features/championship/presentation/pages/home_page.dart';
import '../features/championship/presentation/pages/championship_detail_page.dart';
import '../features/championship/presentation/pages/championship_create_page.dart';
import '../features/answer/presentation/pages/answer_detail_page.dart';
import '../features/answer/presentation/pages/answer_create_page.dart';
import '../features/answer/presentation/pages/answer_edit_page.dart';
import '../features/user/presentation/pages/profile_page.dart';
import '../features/user/presentation/pages/profile_edit_page.dart';
import '../features/user/presentation/pages/user_detail_page.dart';

GoRouter createGoRouter({String? initialLocation}) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation ?? '/',
    routes: [
    // Outside Shell Routes - must be before StatefulShellRoute to prevent :id from matching 'create'
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/championships/create',
      builder: (context, state) => const ChampionshipCreatePage(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/championships/:id/answers/create',
      builder: (context, state) => AnswerCreatePage(
        championshipId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/championships/:championshipId/answers/:answerId/edit',
      builder: (context, state) => AnswerEditPage(
        championshipId: state.pathParameters['championshipId']!,
        answerId: state.pathParameters['answerId']!,
      ),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/profile/edit',
      builder: (context, state) => const ProfileEditPage(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => MainShell(
        navigationShell: navigationShell,
      ),
      branches: [
        // Home Branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomePage(),
              routes: [
                GoRoute(
                  path: 'championships/:id',
                  builder: (context, state) => ChampionshipDetailPage(
                    id: state.pathParameters['id']!,
                  ),
                  routes: [
                    GoRoute(
                      path: 'answers/:answerId',
                      builder: (context, state) => AnswerDetailPage(
                        championshipId: state.pathParameters['id']!,
                        answerId: state.pathParameters['answerId']!,
                      ),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'users/:id',
                  builder: (context, state) => UserDetailPage(
                    id: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ],
        ),
        // Profile Branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),
      ],
    ),
  ],
  );
}
