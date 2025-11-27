import 'package:flutter/material.dart';

class AnswerDetailPage extends StatelessWidget {
  const AnswerDetailPage({
    required this.championshipId,
    required this.answerId,
    super.key,
  });

  final String championshipId;
  final String answerId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('回答詳細'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('回答詳細'),
            Text('選手権ID: $championshipId'),
            Text('回答ID: $answerId'),
          ],
        ),
      ),
    );
  }
}
