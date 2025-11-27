import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minna_senshuken/features/user/presentation/pages/profile_edit_page.dart';

void main() {
  group('ProfileEditPage', () {
    testWidgets('displays placeholder text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileEditPage(),
        ),
      );

      expect(find.text('プロフィール編集'), findsNWidgets(2));
    });

    testWidgets('has AppBar with close button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileEditPage(),
        ),
      );

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('is a StatelessWidget', (tester) async {
      const page = ProfileEditPage();
      expect(page, isA<StatelessWidget>());
    });
  });
}
