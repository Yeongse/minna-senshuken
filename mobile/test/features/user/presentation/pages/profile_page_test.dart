import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minna_senshuken/features/user/presentation/pages/profile_page.dart';

void main() {
  group('ProfilePage', () {
    testWidgets('displays AppBar with title', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ProfilePage(),
          ),
        ),
      );

      expect(find.text('マイページ'), findsOneWidget);
    });

    testWidgets('is a ConsumerWidget', (tester) async {
      const page = ProfilePage();
      expect(page, isA<ConsumerWidget>());
    });

    testWidgets('has edit button in AppBar', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ProfilePage(),
          ),
        ),
      );

      expect(find.byIcon(Icons.edit), findsOneWidget);
    });
  });
}
