import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minna_senshuken/features/championship/presentation/pages/championship_create_page.dart';

void main() {
  group('ChampionshipCreatePage', () {
    testWidgets('displays placeholder text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChampionshipCreatePage(),
        ),
      );

      expect(find.text('選手権作成'), findsNWidgets(2));
    });

    testWidgets('has AppBar with close button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChampionshipCreatePage(),
        ),
      );

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('is a StatelessWidget', (tester) async {
      const page = ChampionshipCreatePage();
      expect(page, isA<StatelessWidget>());
    });
  });
}
