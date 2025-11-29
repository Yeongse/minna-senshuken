import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/answer.dart';
import '../../../../core/models/championship.dart';
import '../../../../core/models/enums.dart';
import '../../../../core/models/user.dart';
import '../../../../core/providers/user_providers.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';

class UserDetailPage extends ConsumerStatefulWidget {
  const UserDetailPage({
    required this.id,
    super.key,
  });

  final String id;

  @override
  ConsumerState<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends ConsumerState<UserDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userDetailProvider(widget.id));

    return Scaffold(
      body: userAsync.when(
        data: (user) => _UserDetailContent(
          user: user,
          userId: widget.id,
          tabController: _tabController,
        ),
        loading: () => Scaffold(
          appBar: AppBar(title: const Text('ユーザー詳細')),
          body: const LoadingView(),
        ),
        error: (error, stack) => Scaffold(
          appBar: AppBar(title: const Text('ユーザー詳細')),
          body: ErrorView.fromException(
            exception: error,
            onRetry: () => ref.invalidate(userDetailProvider(widget.id)),
          ),
        ),
      ),
    );
  }
}

class _UserDetailContent extends ConsumerWidget {
  const _UserDetailContent({
    required this.user,
    required this.userId,
    required this.tabController,
  });

  final UserProfile user;
  final String userId;
  final TabController tabController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            flexibleSpace: FlexibleSpaceBar(
              background: _UserHeader(user: user),
            ),
            bottom: TabBar(
              controller: tabController,
              tabs: const [
                Tab(text: '主催した選手権'),
                Tab(text: '投稿した回答'),
              ],
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: tabController,
        children: [
          _UserChampionshipsTab(userId: userId),
          _UserAnswersTab(userId: userId),
        ],
      ),
    );
  }
}

class _UserHeader extends StatelessWidget {
  const _UserHeader({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 80, 16, 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage:
                user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
            child: user.avatarUrl == null
                ? Text(
                    user.displayName.isNotEmpty
                        ? user.displayName[0].toUpperCase()
                        : '?',
                    style: theme.textTheme.headlineMedium,
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            user.displayName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (user.bio != null && user.bio!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              user.bio!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _UserChampionshipsTab extends ConsumerWidget {
  const _UserChampionshipsTab({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final championshipsAsync = ref.watch(userChampionshipsProvider(userId));

    return championshipsAsync.when(
      data: (championships) {
        if (championships.isEmpty) {
          return const _EmptyContent(
            icon: Icons.emoji_events_outlined,
            message: 'まだ選手権を主催していません',
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userChampionshipsProvider(userId));
            await ref.read(userChampionshipsProvider(userId).future);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: championships.length,
            itemBuilder: (context, index) => _ChampionshipCard(
              championship: championships[index],
            ),
          ),
        );
      },
      loading: () => const LoadingView(),
      error: (error, stack) => ErrorView.fromException(
        exception: error,
        onRetry: () => ref.invalidate(userChampionshipsProvider(userId)),
      ),
    );
  }
}

class _UserAnswersTab extends ConsumerWidget {
  const _UserAnswersTab({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final answersAsync = ref.watch(userAnswersProvider(userId));

    return answersAsync.when(
      data: (answers) {
        if (answers.isEmpty) {
          return const _EmptyContent(
            icon: Icons.edit_note_outlined,
            message: 'まだ回答を投稿していません',
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userAnswersProvider(userId));
            await ref.read(userAnswersProvider(userId).future);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: answers.length,
            itemBuilder: (context, index) => _AnswerCard(
              answer: answers[index],
            ),
          ),
        );
      },
      loading: () => const LoadingView(),
      error: (error, stack) => ErrorView.fromException(
        exception: error,
        onRetry: () => ref.invalidate(userAnswersProvider(userId)),
      ),
    );
  }
}

class _EmptyContent extends StatelessWidget {
  const _EmptyContent({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChampionshipCard extends StatelessWidget {
  const _ChampionshipCard({required this.championship});

  final Championship championship;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd');
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.go('/championships/${championship.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      championship.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(status: championship.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                championship.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${dateFormat.format(championship.startAt)} - ${dateFormat.format(championship.endAt)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({required this.answer});

  final Answer answer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.go(
          '/championships/${answer.championshipId}/answers/${answer.id}',
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                answer.text,
                style: theme.textTheme.bodyLarge,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (answer.imageUrl != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    answer.imageUrl!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatChip(
                    icon: Icons.favorite_outline,
                    label: '${answer.likeCount}',
                  ),
                  const SizedBox(width: 16),
                  _StatChip(
                    icon: Icons.chat_bubble_outline,
                    label: '${answer.commentCount}',
                  ),
                  if (answer.awardType != null) ...[
                    const Spacer(),
                    _AwardBadge(awardType: answer.awardType!),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ChampionshipStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ChampionshipStatus.recruiting => ('募集中', Colors.green),
      ChampionshipStatus.selecting => ('選考中', Colors.orange),
      ChampionshipStatus.announced => ('発表済み', Colors.blue),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

class _AwardBadge extends StatelessWidget {
  const _AwardBadge({required this.awardType});

  final AwardType awardType;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (awardType) {
      AwardType.grandPrize => ('大賞', Colors.amber),
      AwardType.prize => ('入賞', Colors.grey),
      AwardType.specialPrize => ('特別賞', Colors.purple),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.outline,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}
