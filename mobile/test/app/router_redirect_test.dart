import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minna_senshuken/app/router.dart';
import 'package:minna_senshuken/core/auth/auth_provider.dart';
import 'package:minna_senshuken/core/auth/auth_service.dart';

/// 認証状態をテスト用にオーバーライドするモック
class MockAuthService implements AuthServiceInterface {
  final bool _isAuthenticated;

  MockAuthService({bool isAuthenticated = false})
      : _isAuthenticated = isAuthenticated;

  @override
  User? get currentUser => _isAuthenticated ? _MockUser() : null;

  @override
  bool get isAuthenticated => _isAuthenticated;

  @override
  Stream<User?> get authStateChanges =>
      Stream.value(_isAuthenticated ? _MockUser() : null);

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async => null;

  @override
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}
}

// ignore: subtype_of_sealed_class
class _MockUser implements User {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;

  @override
  String get uid => 'test-uid';
}

void main() {
  group('GoRouter redirect', () {
    testWidgets('should redirect to sign-in when not authenticated',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(
            MockAuthService(isAuthenticated: false),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(goRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 未ログイン時は/sign-inにリダイレクトされる
      expect(router.routerDelegate.currentConfiguration.fullPath, '/sign-in');
    });

    testWidgets('should stay on home when authenticated', (tester) async {
      final mockAuthService = MockAuthService(isAuthenticated: true);
      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          // StreamProviderもオーバーライドしてログイン状態を設定
          authStateProvider.overrideWith(
            (ref) => Stream.value(_MockUser()),
          ),
          currentUserProvider.overrideWith(
            (ref) => _MockUser(),
          ),
          isAuthenticatedProvider.overrideWith(
            (ref) => true,
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(goRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // ログイン済みは/にアクセス可能
      expect(router.routerDelegate.currentConfiguration.fullPath, '/');
    });

    testWidgets('should redirect to home when authenticated user visits sign-in',
        (tester) async {
      final mockAuthService = MockAuthService(isAuthenticated: true);
      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          authStateProvider.overrideWith(
            (ref) => Stream.value(_MockUser()),
          ),
          currentUserProvider.overrideWith(
            (ref) => _MockUser(),
          ),
          isAuthenticatedProvider.overrideWith(
            (ref) => true,
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(goRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // ログイン済みユーザーが/sign-inにアクセスしようとした場合、/にリダイレクト
      router.go('/sign-in');
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.fullPath, '/');
    });
  });
}
