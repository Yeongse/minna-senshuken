import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minna_senshuken/features/user/presentation/pages/profile_edit_page.dart';

void main() {
  group('ProfileEditPage', () {
    testWidgets('displays AppBar with title', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ProfileEditPage(),
          ),
        ),
      );

      expect(find.text('プロフィール編集'), findsOneWidget);
    });

    testWidgets('has AppBar with close button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ProfileEditPage(),
          ),
        ),
      );

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('is a ConsumerStatefulWidget', (tester) async {
      const page = ProfileEditPage();
      expect(page, isA<ConsumerStatefulWidget>());
    });

    testWidgets('has save button in AppBar', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ProfileEditPage(),
          ),
        ),
      );

      expect(find.text('保存'), findsOneWidget);
    });
  });
}
