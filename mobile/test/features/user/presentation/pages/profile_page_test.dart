import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minna_senshuken/features/user/presentation/pages/profile_page.dart';

void main() {
  group('ProfilePage', () {
    testWidgets('displays placeholder text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProfilePage(),
        ),
      );

      expect(find.text('マイページ'), findsOneWidget);
    });

    testWidgets('is a StatelessWidget', (tester) async {
      const page = ProfilePage();
      expect(page, isA<StatelessWidget>());
    });
  });
}
