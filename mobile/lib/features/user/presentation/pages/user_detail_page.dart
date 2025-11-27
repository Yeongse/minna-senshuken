import 'package:flutter/material.dart';

class UserDetailPage extends StatelessWidget {
  const UserDetailPage({
    required this.id,
    super.key,
  });

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ユーザー詳細'),
      ),
      body: Center(
        child: Text('ユーザー詳細: $id'),
      ),
    );
  }
}
