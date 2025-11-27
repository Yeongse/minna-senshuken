import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minna_senshuken/app/router.dart';
import 'package:minna_senshuken/app/main_shell.dart';
import 'package:minna_senshuken/features/championship/presentation/pages/home_page.dart';
import 'package:minna_senshuken/features/championship/presentation/pages/championship_detail_page.dart';
import 'package:minna_senshuken/features/championship/presentation/pages/championship_create_page.dart';
import 'package:minna_senshuken/features/answer/presentation/pages/answer_detail_page.dart';
import 'package:minna_senshuken/features/answer/presentation/pages/answer_create_page.dart';
import 'package:minna_senshuken/features/answer/presentation/pages/answer_edit_page.dart';
import 'package:minna_senshuken/features/user/presentation/pages/profile_page.dart';
import 'package:minna_senshuken/features/user/presentation/pages/profile_edit_page.dart';
import 'package:minna_senshuken/features/user/presentation/pages/user_detail_page.dart';

void main() {
  group('AppRouter', () {
    group('Home Branch', () {
      testWidgets('navigates to HomePage at root path', (tester) async {
        final router = createGoRouter();
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(HomePage), findsOneWidget);
        expect(find.byType(MainShell), findsOneWidget);
      });

      testWidgets('navigates to ChampionshipDetailPage with id parameter', (tester) async {
        final router = createGoRouter(initialLocation: '/championships/123');
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ChampionshipDetailPage), findsOneWidget);
        expect(find.text('選手権詳細: 123'), findsOneWidget);
      });

      testWidgets('navigates to AnswerDetailPage with championship and answer ids', (tester) async {
        final router = createGoRouter(initialLocation: '/championships/123/answers/456');
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AnswerDetailPage), findsOneWidget);
        expect(find.text('選手権ID: 123'), findsOneWidget);
        expect(find.text('回答ID: 456'), findsOneWidget);
      });

      testWidgets('navigates to UserDetailPage with id parameter', (tester) async {
        final router = createGoRouter(initialLocation: '/users/user123');
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(UserDetailPage), findsOneWidget);
        expect(find.text('ユーザー詳細: user123'), findsOneWidget);
      });
    });

    group('Profile Branch', () {
      testWidgets('navigates to ProfilePage at /profile', (tester) async {
        final router = createGoRouter(initialLocation: '/profile');
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ProfilePage), findsOneWidget);
        expect(find.byType(MainShell), findsOneWidget);
      });
    });

    group('Outside Shell Routes', () {
      testWidgets('navigates to ChampionshipCreatePage without bottom nav', (tester) async {
        final router = createGoRouter(initialLocation: '/championships/create');
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ChampionshipCreatePage), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
      });

      testWidgets('navigates to AnswerCreatePage with championship id', (tester) async {
        final router = createGoRouter(initialLocation: '/championships/123/answers/create');
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AnswerCreatePage), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
      });

      testWidgets('navigates to AnswerEditPage with championship and answer ids', (tester) async {
        final router = createGoRouter(initialLocation: '/championships/123/answers/456/edit');
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AnswerEditPage), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
      });

      testWidgets('navigates to ProfileEditPage without bottom nav', (tester) async {
        final router = createGoRouter(initialLocation: '/profile/edit');
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ProfileEditPage), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
      });
    });

    group('Initial Location', () {
      testWidgets('initial location is root path', (tester) async {
        final router = createGoRouter();
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(HomePage), findsOneWidget);
      });
    });
  });
}
