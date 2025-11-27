import 'package:flutter/material.dart';

class ChampionshipDetailPage extends StatelessWidget {
  const ChampionshipDetailPage({
    required this.id,
    super.key,
  });

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('選手権詳細'),
      ),
      body: Center(
        child: Text('選手権詳細: $id'),
      ),
    );
  }
}
