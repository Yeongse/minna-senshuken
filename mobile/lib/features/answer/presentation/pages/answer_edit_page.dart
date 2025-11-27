import 'package:flutter/material.dart';

class AnswerEditPage extends StatelessWidget {
  const AnswerEditPage({
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
        title: const Text('回答編集'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const Center(
        child: Text('回答編集'),
      ),
    );
  }
}
