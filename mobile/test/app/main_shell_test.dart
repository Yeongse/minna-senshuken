import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:minna_senshuken/app/main_shell.dart';

void main() {
  group('MainShell', () {
    testWidgets('displays NavigationBar with two destinations', (tester) async {
      final goRouter = GoRouter(
        initialLocation: '/',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) => MainShell(
              navigationShell: navigationShell,
            ),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/',
                    builder: (context, state) => const Scaffold(
                      body: Center(child: Text('ホーム')),
                    ),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/profile',
                    builder: (context, state) => const Scaffold(
                      body: Center(child: Text('マイページ')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: goRouter,
        ),
      );

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationDestination), findsNWidgets(2));
    });

    testWidgets('displays home and profile tab labels', (tester) async {
      final goRouter = GoRouter(
        initialLocation: '/',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) => MainShell(
              navigationShell: navigationShell,
            ),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/',
                    builder: (context, state) => const Scaffold(
                      body: Center(child: Text('ホームページ')),
                    ),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/profile',
                    builder: (context, state) => const Scaffold(
                      body: Center(child: Text('プロフィールページ')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: goRouter,
        ),
      );

      final navigationBar = find.byType(NavigationBar);
      expect(navigationBar, findsOneWidget);
      expect(find.descendant(of: navigationBar, matching: find.text('ホーム')), findsOneWidget);
      expect(find.descendant(of: navigationBar, matching: find.text('マイページ')), findsOneWidget);
    });

    testWidgets('shows home icon and profile icon', (tester) async {
      final goRouter = GoRouter(
        initialLocation: '/',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) => MainShell(
              navigationShell: navigationShell,
            ),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/',
                    builder: (context, state) => const Scaffold(
                      body: Center(child: Text('ホーム')),
                    ),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/profile',
                    builder: (context, state) => const Scaffold(
                      body: Center(child: Text('マイページ')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: goRouter,
        ),
      );

      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('navigates to profile tab when tapped', (tester) async {
      final goRouter = GoRouter(
        initialLocation: '/',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) => MainShell(
              navigationShell: navigationShell,
            ),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/',
                    builder: (context, state) => const Scaffold(
                      body: Center(child: Text('ホームコンテンツ')),
                    ),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/profile',
                    builder: (context, state) => const Scaffold(
                      body: Center(child: Text('マイページコンテンツ')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: goRouter,
        ),
      );

      expect(find.text('ホームコンテンツ'), findsOneWidget);

      await tester.tap(find.text('マイページ'));
      await tester.pumpAndSettle();

      expect(find.text('マイページコンテンツ'), findsOneWidget);
    });

    testWidgets('is a StatelessWidget', (tester) async {
      final goRouter = GoRouter(
        initialLocation: '/',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) => MainShell(
              navigationShell: navigationShell,
            ),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/',
                    builder: (context, state) => const Scaffold(
                      body: Center(child: Text('ホーム')),
                    ),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/profile',
                    builder: (context, state) => const Scaffold(
                      body: Center(child: Text('マイページ')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: goRouter,
        ),
      );

      final mainShellFinder = find.byType(MainShell);
      final mainShellWidget = tester.widget<MainShell>(mainShellFinder);
      expect(mainShellWidget, isA<StatelessWidget>());
    });
  });
}
