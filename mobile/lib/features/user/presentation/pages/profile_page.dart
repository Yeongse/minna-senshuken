import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_provider.dart';
import '../../../../core/models/user.dart';
import '../../../../core/providers/user_providers.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('マイページ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/profile/edit'),
            tooltip: 'プロフィール編集',
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(
              child: Text('ログインしてください'),
            );
          }
          return _ProfileContent(profile: profile);
        },
        loading: () => const LoadingView(),
        error: (error, stack) => ErrorView.fromException(
          exception: error,
          onRetry: () => ref.invalidate(profileProvider),
        ),
      ),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  final UserProfile profile;

  const _ProfileContent({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // アバター
          CircleAvatar(
            radius: 50,
            backgroundImage: profile.avatarUrl != null
                ? NetworkImage(profile.avatarUrl!)
                : null,
            child: profile.avatarUrl == null
                ? Text(
                    profile.displayName.isNotEmpty
                        ? profile.displayName[0].toUpperCase()
                        : '?',
                    style: Theme.of(context).textTheme.headlineLarge,
                  )
                : null,
          ),
          const SizedBox(height: 16),

          // 表示名
          Text(
            profile.displayName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),

          // 自己紹介
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            Text(
              profile.bio!,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],

          // Twitter URL
          if (profile.twitterUrl != null && profile.twitterUrl!.isNotEmpty) ...[
            InkWell(
              onTap: () {
                // TODO: URLを開く
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.link, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    profile.twitterUrl!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          const Divider(),
          const SizedBox(height: 16),

          // ログアウトボタン
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showLogoutConfirmation(context, ref),
              icon: const Icon(Icons.logout),
              label: const Text('ログアウト'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ログアウト'),
        content: const Text('ログアウトしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final authService = ref.read(authServiceProvider);
              await authService.signOut();
            },
            child: const Text('ログアウト'),
          ),
        ],
      ),
    );
  }
}
