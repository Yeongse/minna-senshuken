import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minna_senshuken/features/answer/presentation/pages/answer_edit_page.dart';

void main() {
  group('AnswerEditPage', () {
    testWidgets('displays placeholder text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AnswerEditPage(
            championshipId: 'champ-123',
            answerId: 'answer-456',
          ),
        ),
      );

      expect(find.text('回答編集'), findsNWidgets(2));
    });

    testWidgets('requires both championshipId and answerId parameters',
        (tester) async {
      const page = AnswerEditPage(
        championshipId: 'champ-id',
        answerId: 'answer-id',
      );
      expect(page.championshipId, equals('champ-id'));
      expect(page.answerId, equals('answer-id'));
    });

    testWidgets('has AppBar with close button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AnswerEditPage(
            championshipId: 'champ-123',
            answerId: 'answer-456',
          ),
        ),
      );

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });
}
