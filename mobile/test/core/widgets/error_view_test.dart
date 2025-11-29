import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minna_senshuken/core/widgets/error_view.dart';
import 'package:minna_senshuken/core/api/api_exception.dart';

void main() {
  group('ErrorView', () {
    testWidgets('should display error message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorView(
              message: 'テストエラーメッセージ',
            ),
          ),
        ),
      );

      expect(find.text('テストエラーメッセージ'), findsOneWidget);
    });

    testWidgets('should display error icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorView(
              message: 'エラー',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('should display retry button when onRetry is provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorView(
              message: 'エラー',
              onRetry: () {},
            ),
          ),
        ),
      );

      expect(find.text('再試行'), findsOneWidget);
    });

    testWidgets('should not display retry button when onRetry is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorView(
              message: 'エラー',
            ),
          ),
        ),
      );

      expect(find.text('再試行'), findsNothing);
    });

    testWidgets('should call onRetry when retry button is tapped', (tester) async {
      var retryCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorView(
              message: 'エラー',
              onRetry: () {
                retryCount++;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('再試行'));
      expect(retryCount, equals(1));
    });

    group('fromException factory', () {
      testWidgets('should extract message from NetworkException', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorView.fromException(
                exception: NetworkException(),
              ),
            ),
          ),
        );

        expect(find.text('ネットワーク接続に失敗しました'), findsOneWidget);
      });

      testWidgets('should extract message from ServerException', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorView.fromException(
                exception: ServerException(),
              ),
            ),
          ),
        );

        expect(find.text('サーバーエラーが発生しました'), findsOneWidget);
      });

      testWidgets('should display default message for unknown exception', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorView.fromException(
                exception: Exception('Unknown error'),
              ),
            ),
          ),
        );

        expect(find.text('エラーが発生しました'), findsOneWidget);
      });
    });
  });
}
