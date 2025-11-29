import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minna_senshuken/core/auth/auth_provider.dart';
import 'package:minna_senshuken/core/auth/auth_service.dart';
import 'package:minna_senshuken/core/models/championship.dart';
import 'package:minna_senshuken/core/models/enums.dart';
import 'package:minna_senshuken/core/models/user.dart';
import 'package:minna_senshuken/core/providers/championship_providers.dart';
import 'package:minna_senshuken/features/championship/presentation/pages/home_page.dart';

/// テスト用モックAuthService
class MockAuthService implements AuthServiceInterface {
  @override
  User? get currentUser => _MockUser();

  @override
  bool get isAuthenticated => true;

  @override
  Stream<User?> get authStateChanges => Stream.value(_MockUser());

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async => 'test-token';

  @override
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
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
  group('選手権機能E2E確認', () {
    final testChampionships = [
      Championship(
        id: '1',
        title: '大喜利選手権1',
        description: 'テスト説明1',
        status: ChampionshipStatus.recruiting,
        startAt: DateTime(2024, 1, 1),
        endAt: DateTime(2024, 1, 14),
        user: const UserSummary(
          id: 'user-1',
          displayName: 'ユーザー1',
          avatarUrl: null,
        ),
        answerCount: 10,
        totalLikes: 50,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ),
      Championship(
        id: '2',
        title: '大喜利選手権2',
        description: 'テスト説明2',
        status: ChampionshipStatus.selecting,
        startAt: DateTime(2024, 1, 1),
        endAt: DateTime(2024, 1, 14),
        user: const UserSummary(
          id: 'user-2',
          displayName: 'ユーザー2',
          avatarUrl: null,
        ),
        answerCount: 20,
        totalLikes: 100,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ),
      Championship(
        id: '3',
        title: '大喜利選手権3',
        description: 'テスト説明3',
        status: ChampionshipStatus.announced,
        startAt: DateTime(2024, 1, 1),
        endAt: DateTime(2024, 1, 14),
        user: const UserSummary(
          id: 'user-3',
          displayName: 'ユーザー3',
          avatarUrl: null,
        ),
        answerCount: 30,
        totalLikes: 150,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ),
    ];

    group('タスク7.2.1: ホーム画面でタブ切り替え', () {
      testWidgets('タブ切り替えでステータス別一覧表示を確認', (tester) async {
        final container = ProviderContainer(
          overrides: [
            authServiceProvider.overrideWithValue(MockAuthService()),
            // 募集中のみ
            championshipListProvider(ChampionshipStatus.recruiting)
                .overrideWith((ref) async => testChampionships
                    .where((c) => c.status == ChampionshipStatus.recruiting)
                    .toList()),
            // 選考中のみ
            championshipListProvider(ChampionshipStatus.selecting)
                .overrideWith((ref) async => testChampionships
                    .where((c) => c.status == ChampionshipStatus.selecting)
                    .toList()),
            // 発表済みのみ
            championshipListProvider(ChampionshipStatus.announced)
                .overrideWith((ref) async => testChampionships
                    .where((c) => c.status == ChampionshipStatus.announced)
                    .toList()),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: HomePage(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // タブが3つとも表示されている
        expect(find.text('募集中'), findsWidgets);
        expect(find.text('選考中'), findsOneWidget);
        expect(find.text('発表済み'), findsOneWidget);

        // 募集中の選手権が表示されている
        expect(find.text('大喜利選手権1'), findsOneWidget);

        // 選考中タブに切り替え
        await tester.tap(find.text('選考中'));
        await tester.pumpAndSettle();

        // 選考中の選手権が表示されている
        expect(find.text('大喜利選手権2'), findsOneWidget);

        // 発表済みタブに切り替え
        await tester.tap(find.text('発表済み'));
        await tester.pumpAndSettle();

        // 発表済みの選手権が表示されている
        expect(find.text('大喜利選手権3'), findsOneWidget);
      });
    });

    group('タスク7.2.2: 選手権一覧表示', () {
      testWidgets('選手権一覧に必要な情報が表示される', (tester) async {
        final container = ProviderContainer(
          overrides: [
            authServiceProvider.overrideWithValue(MockAuthService()),
            championshipListProvider(ChampionshipStatus.recruiting)
                .overrideWith((ref) async => [testChampionships[0]]),
            championshipListProvider(ChampionshipStatus.selecting)
                .overrideWith((ref) async => []),
            championshipListProvider(ChampionshipStatus.announced)
                .overrideWith((ref) async => []),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: HomePage(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // タイトル・説明が表示されている
        expect(find.text('大喜利選手権1'), findsOneWidget);
        expect(find.text('テスト説明1'), findsOneWidget);

        // 主催者情報が表示されている
        expect(find.text('ユーザー1'), findsOneWidget);

        // 回答数といいね数が表示されている
        expect(find.text('10件の回答'), findsOneWidget);
        expect(find.text('50いいね'), findsOneWidget);
      });

      testWidgets('選手権が空の場合はメッセージが表示される', (tester) async {
        final container = ProviderContainer(
          overrides: [
            authServiceProvider.overrideWithValue(MockAuthService()),
            championshipListProvider(ChampionshipStatus.recruiting)
                .overrideWith((ref) async => []),
            championshipListProvider(ChampionshipStatus.selecting)
                .overrideWith((ref) async => []),
            championshipListProvider(ChampionshipStatus.announced)
                .overrideWith((ref) async => []),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: HomePage(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('選手権がありません'), findsOneWidget);
      });
    });

    group('タスク7.2.3: Pull-to-Refresh', () {
      testWidgets('Pull-to-Refreshコンポーネントが存在する', (tester) async {
        final container = ProviderContainer(
          overrides: [
            authServiceProvider.overrideWithValue(MockAuthService()),
            championshipListProvider(ChampionshipStatus.recruiting)
                .overrideWith((ref) async => [testChampionships[0]]),
            championshipListProvider(ChampionshipStatus.selecting)
                .overrideWith((ref) async => []),
            championshipListProvider(ChampionshipStatus.announced)
                .overrideWith((ref) async => []),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: HomePage(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 初期表示を確認
        expect(find.text('大喜利選手権1'), findsOneWidget);

        // RefreshIndicatorが存在する
        expect(find.byType(RefreshIndicator), findsOneWidget);
      });
    });

    group('タスク7.2.4: エラーハンドリング', () {
      testWidgets('API取得失敗時にエラー画面が表示される', (tester) async {
        final container = ProviderContainer(
          overrides: [
            authServiceProvider.overrideWithValue(MockAuthService()),
            championshipListProvider(ChampionshipStatus.recruiting)
                .overrideWith((ref) async => throw Exception('API Error')),
            championshipListProvider(ChampionshipStatus.selecting)
                .overrideWith((ref) async => []),
            championshipListProvider(ChampionshipStatus.announced)
                .overrideWith((ref) async => []),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: HomePage(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // エラーメッセージと再試行ボタンが表示される
        expect(find.text('再試行'), findsOneWidget);
      });
    });

    group('タスク7.2.5: 選手権作成バリデーション', () {
      test('ChampionshipCreateStateが正しく初期化される', () {
        const state = ChampionshipCreateState();

        expect(state.isLoading, isFalse);
        expect(state.championship, isNull);
        expect(state.error, isNull);
        expect(state.validationErrors, isEmpty);
      });

      test('ChampionshipCreateStateのcopyWithが正しく動作する', () {
        const state = ChampionshipCreateState();

        final newState = state.copyWith(isLoading: true);
        expect(newState.isLoading, isTrue);
        expect(newState.error, isNull);

        final errorState = state.copyWith(error: 'エラーメッセージ');
        expect(errorState.error, 'エラーメッセージ');
        expect(errorState.isLoading, isFalse);

        final validationState = state.copyWith(
          validationErrors: {'title': 'タイトルを入力してください'},
        );
        expect(validationState.validationErrors['title'], 'タイトルを入力してください');
      });
    });

    group('タスク7.2.6: 選手権作成ボタン', () {
      testWidgets('選手権作成ボタンが表示されている', (tester) async {
        final container = ProviderContainer(
          overrides: [
            authServiceProvider.overrideWithValue(MockAuthService()),
            championshipListProvider(ChampionshipStatus.recruiting)
                .overrideWith((ref) async => []),
            championshipListProvider(ChampionshipStatus.selecting)
                .overrideWith((ref) async => []),
            championshipListProvider(ChampionshipStatus.announced)
                .overrideWith((ref) async => []),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: HomePage(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 作成ボタン（+アイコン）が表示されている
        expect(find.byIcon(Icons.add), findsOneWidget);

        // ツールチップのテキスト
        expect(find.byTooltip('選手権を作成'), findsOneWidget);
      });
    });

    group('タスク7.2.7: ステータスバッジ表示', () {
      testWidgets('募集中バッジが正しく表示される', (tester) async {
        final container = ProviderContainer(
          overrides: [
            authServiceProvider.overrideWithValue(MockAuthService()),
            championshipListProvider(ChampionshipStatus.recruiting)
                .overrideWith((ref) async => [testChampionships[0]]),
            championshipListProvider(ChampionshipStatus.selecting)
                .overrideWith((ref) async => []),
            championshipListProvider(ChampionshipStatus.announced)
                .overrideWith((ref) async => []),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: HomePage(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 募集中バッジが表示されている（タブとカード内で2つ）
        expect(find.text('募集中'), findsNWidgets(2));
      });
    });
  });
}
