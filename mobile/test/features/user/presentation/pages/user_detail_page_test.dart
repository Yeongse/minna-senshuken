import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minna_senshuken/features/user/presentation/pages/user_detail_page.dart';

void main() {
  group('UserDetailPage', () {
    testWidgets('displays user id', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: UserDetailPage(id: 'user-123'),
        ),
      );

      expect(find.text('ユーザー詳細: user-123'), findsOneWidget);
    });

    testWidgets('requires id parameter', (tester) async {
      const page = UserDetailPage(id: 'required-id');
      expect(page.id, equals('required-id'));
    });

    testWidgets('has AppBar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: UserDetailPage(id: 'user-123'),
        ),
      );

      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}
