import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minna_senshuken/features/answer/presentation/pages/answer_create_page.dart';

void main() {
  group('AnswerCreatePage', () {
    testWidgets('displays placeholder text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AnswerCreatePage(championshipId: 'champ-123'),
        ),
      );

      expect(find.text('回答投稿'), findsNWidgets(2));
    });

    testWidgets('requires championshipId parameter', (tester) async {
      const page = AnswerCreatePage(championshipId: 'champ-id');
      expect(page.championshipId, equals('champ-id'));
    });

    testWidgets('has AppBar with close button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AnswerCreatePage(championshipId: 'champ-123'),
        ),
      );

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });
}
