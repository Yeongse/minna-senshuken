import 'package:flutter/material.dart';

class AnswerCreatePage extends StatelessWidget {
  const AnswerCreatePage({
    required this.championshipId,
    super.key,
  });

  final String championshipId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('回答投稿'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const Center(
        child: Text('回答投稿'),
      ),
    );
  }
}
