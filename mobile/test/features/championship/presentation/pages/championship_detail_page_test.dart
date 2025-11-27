import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minna_senshuken/features/championship/presentation/pages/championship_detail_page.dart';

void main() {
  group('ChampionshipDetailPage', () {
    testWidgets('displays championship id', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChampionshipDetailPage(id: 'test-id-123'),
        ),
      );

      expect(find.text('選手権詳細: test-id-123'), findsOneWidget);
    });

    testWidgets('requires id parameter', (tester) async {
      const page = ChampionshipDetailPage(id: 'required-id');
      expect(page.id, equals('required-id'));
    });

    testWidgets('has AppBar with back button support', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChampionshipDetailPage(id: 'test-id'),
        ),
      );

      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}
