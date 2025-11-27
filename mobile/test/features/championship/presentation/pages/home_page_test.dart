import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minna_senshuken/features/championship/presentation/pages/home_page.dart';

void main() {
  group('HomePage', () {
    testWidgets('displays placeholder text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      expect(find.text('選手権一覧'), findsOneWidget);
    });

    testWidgets('is a StatelessWidget', (tester) async {
      const homePage = HomePage();
      expect(homePage, isA<StatelessWidget>());
    });
  });
}
