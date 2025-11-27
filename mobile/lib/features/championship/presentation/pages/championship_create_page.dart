import 'package:flutter/material.dart';

class ChampionshipCreatePage extends StatelessWidget {
  const ChampionshipCreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('選手権作成'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const Center(
        child: Text('選手権作成'),
      ),
    );
  }
}
