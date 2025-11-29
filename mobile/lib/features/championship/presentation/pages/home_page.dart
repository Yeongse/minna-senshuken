import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/championship.dart';
import '../../../../core/models/enums.dart';
import '../../../../core/providers/championship_providers.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = [
    ChampionshipStatus.recruiting,
    ChampionshipStatus.selecting,
    ChampionshipStatus.announced,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getTabLabel(ChampionshipStatus status) {
    switch (status) {
      case ChampionshipStatus.recruiting:
        return '募集中';
      case ChampionshipStatus.selecting:
        return '選考中';
      case ChampionshipStatus.announced:
        return '発表済み';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('みんなの選手権'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((status) => Tab(text: _getTabLabel(status))).toList(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '選手権を作成',
            onPressed: () => context.push('/championships/create'),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((status) => _ChampionshipListTab(status: status)).toList(),
      ),
    );
  }
}

class _ChampionshipListTab extends ConsumerWidget {
  const _ChampionshipListTab({required this.status});

  final ChampionshipStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final championshipsAsync = ref.watch(championshipListProvider(status));

    return championshipsAsync.when(
      data: (championships) => _ChampionshipListView(
        championships: championships,
        status: status,
      ),
      loading: () => const LoadingView(),
      error: (error, stack) => ErrorView.fromException(
        exception: error,
        onRetry: () => ref.invalidate(championshipListProvider(status)),
      ),
    );
  }
}

class _ChampionshipListView extends ConsumerWidget {
  const _ChampionshipListView({
    required this.championships,
    required this.status,
  });

  final List<Championship> championships;
  final ChampionshipStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (championships.isEmpty) {
      return Center(
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
              '選手権がありません',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(championshipListProvider(status));
        await ref.read(championshipListProvider(status).future);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: championships.length,
        itemBuilder: (context, index) => _ChampionshipCard(
          championship: championships[index],
        ),
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
              // Title and Status Badge
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
              // Description
              Text(
                championship.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Meta information
              Row(
                children: [
                  // Host user
                  CircleAvatar(
                    radius: 12,
                    backgroundImage: championship.user.avatarUrl != null
                        ? NetworkImage(championship.user.avatarUrl!)
                        : null,
                    child: championship.user.avatarUrl == null
                        ? Text(
                            championship.user.displayName.isNotEmpty
                                ? championship.user.displayName[0]
                                : '?',
                            style: theme.textTheme.labelSmall,
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      championship.user.displayName,
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Date range
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
              const SizedBox(height: 8),
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
