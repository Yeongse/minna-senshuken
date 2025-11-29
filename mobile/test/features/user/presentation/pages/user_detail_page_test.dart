import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minna_senshuken/features/user/presentation/pages/user_detail_page.dart';

void main() {
  group('UserDetailPage', () {
    testWidgets('requires id parameter', (tester) async {
      const page = UserDetailPage(id: 'required-id');
      expect(page.id, equals('required-id'));
    });

    testWidgets('is a ConsumerStatefulWidget', (tester) async {
      const page = UserDetailPage(id: 'user-123');
      expect(page, isA<ConsumerStatefulWidget>());
    });

    testWidgets('displays loading state initially', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: UserDetailPage(id: 'user-123'),
          ),
        ),
      );

      // Shows loading indicator when fetching user data
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
