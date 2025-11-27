import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minna_senshuken/features/answer/presentation/pages/answer_detail_page.dart';

void main() {
  group('AnswerDetailPage', () {
    testWidgets('displays championship id and answer id', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AnswerDetailPage(
            championshipId: 'champ-123',
            answerId: 'answer-456',
          ),
        ),
      );

      expect(find.text('回答詳細'), findsNWidgets(2));
      expect(find.textContaining('champ-123'), findsOneWidget);
      expect(find.textContaining('answer-456'), findsOneWidget);
    });

    testWidgets('requires both championshipId and answerId parameters',
        (tester) async {
      const page = AnswerDetailPage(
        championshipId: 'champ-id',
        answerId: 'answer-id',
      );
      expect(page.championshipId, equals('champ-id'));
      expect(page.answerId, equals('answer-id'));
    });

    testWidgets('has AppBar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AnswerDetailPage(
            championshipId: 'champ-123',
            answerId: 'answer-456',
          ),
        ),
      );

      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}
