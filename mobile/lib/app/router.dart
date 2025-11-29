import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'main_shell.dart';
import '../core/auth/auth_provider.dart';
import '../features/auth/presentation/pages/sign_in_page.dart';
import '../features/championship/presentation/pages/home_page.dart';
import '../features/championship/presentation/pages/championship_detail_page.dart';
import '../features/championship/presentation/pages/championship_create_page.dart';
import '../features/answer/presentation/pages/answer_detail_page.dart';
import '../features/answer/presentation/pages/answer_create_page.dart';
import '../features/answer/presentation/pages/answer_edit_page.dart';
import '../features/user/presentation/pages/profile_page.dart';
import '../features/user/presentation/pages/profile_edit_page.dart';
import '../features/user/presentation/pages/user_detail_page.dart';

/// GoRouterのProvider
final goRouterProvider = Provider<GoRouter>((ref) {
  return createGoRouter(ref: ref);
});

/// 認証が不要なルート
const _publicRoutes = ['/sign-in'];

GoRouter createGoRouter({String? initialLocation, Ref? ref}) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation ?? '/',
    redirect: ref != null
        ? (context, state) {
            final isAuthenticated = ref.read(isAuthenticatedProvider);
            final isPublicRoute = _publicRoutes.contains(state.matchedLocation);

            // ログイン済みでサインイン画面にアクセス → ホーム画面にリダイレクト
            if (isAuthenticated && isPublicRoute) {
              return '/';
            }

            // 未ログインで保護ルートにアクセス → サインイン画面にリダイレクト
            if (!isAuthenticated && !isPublicRoute) {
              return '/sign-in';
            }

            return null; // リダイレクトなし
          }
        : null,
    routes: [
    // Sign In Route
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/sign-in',
      builder: (context, state) => const SignInPage(),
    ),
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
