import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/answer.dart';
import '../../../../core/models/championship.dart';
import '../../../../core/models/enums.dart';
import '../../../../core/providers/answer_providers.dart';
import '../../../../core/providers/championship_providers.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';

class ChampionshipDetailPage extends ConsumerWidget {
  const ChampionshipDetailPage({
    required this.id,
    super.key,
  });

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final championshipAsync = ref.watch(championshipDetailProvider(id));
    final answersAsync = ref.watch(answerListProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('選手権詳細'),
      ),
      body: championshipAsync.when(
        data: (championship) => _ChampionshipDetailContent(
          championship: championship,
          answersAsync: answersAsync,
        ),
        loading: () => const LoadingView(),
        error: (error, stack) => ErrorView.fromException(
          exception: error,
          onRetry: () => ref.invalidate(championshipDetailProvider(id)),
        ),
      ),
      floatingActionButton: championshipAsync.whenOrNull(
        data: (championship) {
          if (championship.status == ChampionshipStatus.recruiting) {
            return FloatingActionButton.extended(
              onPressed: () => context.push('/championships/$id/answers/create'),
              icon: const Icon(Icons.edit),
              label: const Text('回答を投稿'),
            );
          }
          return null;
        },
      ),
    );
  }
}

class _ChampionshipDetailContent extends ConsumerWidget {
  const _ChampionshipDetailContent({
    required this.championship,
    required this.answersAsync,
  });

  final ChampionshipDetail championship;
  final AsyncValue<List<Answer>> answersAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(championshipDetailProvider(championship.id));
        ref.invalidate(answerListProvider(championship.id));
        await Future.wait([
          ref.read(championshipDetailProvider(championship.id).future),
          ref.read(answerListProvider(championship.id).future),
        ]);
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _ChampionshipHeader(championship: championship),
          ),
          const SliverToBoxAdapter(
            child: Divider(height: 32),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '回答一覧',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          answersAsync.when(
            data: (answers) => answers.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'まだ回答がありません',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _AnswerCard(
                          answer: answers[index],
                          championshipId: championship.id,
                        ),
                        childCount: answers.length,
                      ),
                    ),
                  ),
            loading: () => const SliverFillRemaining(
              child: LoadingView(),
            ),
            error: (error, stack) => SliverFillRemaining(
              child: ErrorView.fromException(
                exception: error,
                onRetry: () => ref.invalidate(answerListProvider(championship.id)),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

class _ChampionshipHeader extends StatelessWidget {
  const _ChampionshipHeader({required this.championship});

  final ChampionshipDetail championship;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  championship.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _StatusBadge(status: championship.status),
            ],
          ),
          const SizedBox(height: 16),
          // Description
          Text(
            championship.description,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          // Host user
          InkWell(
            onTap: () => context.go('/users/${championship.user.id}'),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: championship.user.avatarUrl != null
                        ? NetworkImage(championship.user.avatarUrl!)
                        : null,
                    child: championship.user.avatarUrl == null
                        ? Text(
                            championship.user.displayName.isNotEmpty
                                ? championship.user.displayName[0]
                                : '?',
                            style: theme.textTheme.titleMedium,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        championship.user.displayName,
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        '主催者',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Date info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '開始: ${dateFormat.format(championship.startAt)}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.event,
                        size: 16,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '終了: ${dateFormat.format(championship.endAt)}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Stats
          Row(
            children: [
              _StatChip(
                icon: Icons.edit_note,
                label: '${championship.answerCount}件の回答',
              ),
              const SizedBox(width: 16),
              _StatChip(
                icon: Icons.favorite_outline,
                label: '${championship.totalLikes}いいね',
              ),
            ],
          ),
          // Summary comment (if announced)
          if (championship.status == ChampionshipStatus.announced &&
              championship.summaryComment != null) ...[
            const SizedBox(height: 16),
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.message,
                          size: 18,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '総括コメント',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      championship.summaryComment!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({
    required this.answer,
    required this.championshipId,
  });

  final Answer answer;
  final String championshipId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.go('/championships/$championshipId/answers/${answer.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Award badge (if any)
              if (answer.awardType != null) ...[
                _AwardBadge(awardType: answer.awardType!),
                const SizedBox(height: 8),
              ],
              // Answer text
              Text(
                answer.text,
                style: theme.textTheme.bodyLarge,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              // Image preview (if any)
              if (answer.imageUrl != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    answer.imageUrl!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 120,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Center(
                        child: Icon(Icons.broken_image),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // User info and stats
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundImage: answer.user.avatarUrl != null
                        ? NetworkImage(answer.user.avatarUrl!)
                        : null,
                    child: answer.user.avatarUrl == null
                        ? Text(
                            answer.user.displayName.isNotEmpty
                                ? answer.user.displayName[0]
                                : '?',
                            style: theme.textTheme.labelSmall,
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      answer.user.displayName,
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.favorite,
                    size: 14,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${answer.likeCount}',
                    style: theme.textTheme.labelSmall,
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.comment,
                    size: 14,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${answer.commentCount}',
                    style: theme.textTheme.labelSmall,
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

class _AwardBadge extends StatelessWidget {
  const _AwardBadge({required this.awardType});

  final AwardType awardType;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (awardType) {
      AwardType.grandPrize => ('大賞', Colors.amber, Icons.emoji_events),
      AwardType.prize => ('入賞', Colors.grey, Icons.star),
      AwardType.specialPrize => ('特別賞', Colors.purple, Icons.auto_awesome),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
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
