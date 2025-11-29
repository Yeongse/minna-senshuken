import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/auth/auth_provider.dart';
import '../../../../core/models/answer.dart';
import '../../../../core/models/comment.dart';
import '../../../../core/models/enums.dart';
import '../../../../core/providers/answer_providers.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';

class AnswerDetailPage extends ConsumerStatefulWidget {
  const AnswerDetailPage({
    required this.championshipId,
    required this.answerId,
    super.key,
  });

  final String championshipId;
  final String answerId;

  @override
  ConsumerState<AnswerDetailPage> createState() => _AnswerDetailPageState();
}

class _AnswerDetailPageState extends ConsumerState<AnswerDetailPage> {
  final _commentController = TextEditingController();
  final _commentFocusNode = FocusNode();

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final answerAsync = ref.watch(answerDetailProvider((
      championshipId: widget.championshipId,
      answerId: widget.answerId,
    )));

    // コメント投稿成功時の処理
    ref.listen(commentCreateNotifierProvider(widget.answerId), (previous, next) {
      if (next.comment != null && previous?.comment == null) {
        _commentController.clear();
        _commentFocusNode.unfocus();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('コメントを投稿しました')),
        );
        ref.read(commentCreateNotifierProvider(widget.answerId).notifier).reset();
      }
      if (next.error != null && previous?.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: ${next.error}')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('回答詳細'),
        actions: answerAsync.whenOrNull(
          data: (answer) {
            final currentUser = ref.watch(currentUserProvider);
            if (currentUser != null && answer.userId == currentUser.uid) {
              return [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => context.push(
                    '/championships/${widget.championshipId}/answers/${widget.answerId}/edit',
                  ),
                ),
              ];
            }
            return null;
          },
        ),
      ),
      body: answerAsync.when(
        data: (answer) => _AnswerDetailContent(
          answer: answer,
          championshipId: widget.championshipId,
          commentController: _commentController,
          commentFocusNode: _commentFocusNode,
        ),
        loading: () => const LoadingView(),
        error: (error, stack) => ErrorView.fromException(
          exception: error,
          onRetry: () => ref.invalidate(answerDetailProvider((
            championshipId: widget.championshipId,
            answerId: widget.answerId,
          ))),
        ),
      ),
    );
  }
}

class _AnswerDetailContent extends ConsumerStatefulWidget {
  const _AnswerDetailContent({
    required this.answer,
    required this.championshipId,
    required this.commentController,
    required this.commentFocusNode,
  });

  final Answer answer;
  final String championshipId;
  final TextEditingController commentController;
  final FocusNode commentFocusNode;

  @override
  ConsumerState<_AnswerDetailContent> createState() =>
      _AnswerDetailContentState();
}

class _AnswerDetailContentState extends ConsumerState<_AnswerDetailContent> {
  @override
  void initState() {
    super.initState();
    // いいね状態を初期化（isLikedは初期値false、APIからは取得しない）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(likeNotifierProvider((
        championshipId: widget.championshipId,
        answerId: widget.answer.id,
      )).notifier).initialize(
        likeCount: widget.answer.likeCount,
        isLiked: false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(commentListProvider(widget.answer.id));
    final likeState = ref.watch(likeNotifierProvider((
      championshipId: widget.championshipId,
      answerId: widget.answer.id,
    )));
    final commentState = ref.watch(commentCreateNotifierProvider(widget.answer.id));

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(answerDetailProvider((
                championshipId: widget.championshipId,
                answerId: widget.answer.id,
              )));
              ref.invalidate(commentListProvider(widget.answer.id));
              await Future.wait([
                ref.read(answerDetailProvider((
                  championshipId: widget.championshipId,
                  answerId: widget.answer.id,
                )).future),
                ref.read(commentListProvider(widget.answer.id).future),
              ]);
            },
            child: CustomScrollView(
              slivers: [
                // 回答ヘッダー
                SliverToBoxAdapter(
                  child: _AnswerHeader(
                    answer: widget.answer,
                    likeState: likeState,
                    onLike: () {
                      ref.read(likeNotifierProvider((
                        championshipId: widget.championshipId,
                        answerId: widget.answer.id,
                      )).notifier).addLike();
                    },
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Divider(height: 32),
                ),
                // コメントセクション
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'コメント',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                commentsAsync.when(
                  data: (comments) => comments.isEmpty
                      ? SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: Text(
                                'まだコメントがありません',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                              ),
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _CommentCard(comment: comments[index]),
                              childCount: comments.length,
                            ),
                          ),
                        ),
                  loading: () => const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, stack) => SliverToBoxAdapter(
                    child: ErrorView.fromException(
                      exception: error,
                      onRetry: () => ref.invalidate(commentListProvider(widget.answer.id)),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),
        ),
        // コメント入力フィールド
        _CommentInputField(
          controller: widget.commentController,
          focusNode: widget.commentFocusNode,
          isLoading: commentState.isLoading,
          errorText: commentState.validationErrors['text'],
          onSubmit: () {
            ref.read(commentCreateNotifierProvider(widget.answer.id).notifier).create(
                  text: widget.commentController.text,
                );
          },
        ),
      ],
    );
  }
}

class _AnswerHeader extends StatelessWidget {
  const _AnswerHeader({
    required this.answer,
    required this.likeState,
    required this.onLike,
  });

  final Answer answer;
  final LikeState likeState;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 受賞バッジ
          if (answer.awardType != null) ...[
            _AwardBadge(awardType: answer.awardType!),
            const SizedBox(height: 12),
          ],
          // ユーザー情報
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: answer.user.avatarUrl != null
                    ? NetworkImage(answer.user.avatarUrl!)
                    : null,
                child: answer.user.avatarUrl == null
                    ? Text(
                        answer.user.displayName.isNotEmpty
                            ? answer.user.displayName[0]
                            : '?',
                        style: theme.textTheme.titleMedium,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      answer.user.displayName,
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      dateFormat.format(answer.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 回答テキスト
          Text(
            answer.text,
            style: theme.textTheme.bodyLarge,
          ),
          // 画像
          if (answer.imageUrl != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                answer.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Center(
                    child: Icon(Icons.broken_image, size: 48),
                  ),
                ),
              ),
            ),
          ],
          // 受賞コメント
          if (answer.awardType != null && answer.awardComment != null) ...[
            const SizedBox(height: 16),
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.message,
                          size: 16,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '主催者コメント',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      answer.awardComment!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          // いいね・コメント数
          Row(
            children: [
              // いいねボタン
              InkWell(
                onTap: likeState.isLiked ? null : onLike,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: likeState.isLiked
                          ? theme.colorScheme.error
                          : theme.colorScheme.outline,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    color: likeState.isLiked
                        ? theme.colorScheme.error.withValues(alpha: 0.1)
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (likeState.isLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(
                          likeState.isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: likeState.isLiked
                              ? theme.colorScheme.error
                              : theme.colorScheme.outline,
                        ),
                      const SizedBox(width: 4),
                      Text(
                        '${likeState.likeCount}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: likeState.isLiked
                              ? theme.colorScheme.error
                              : theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // コメント数
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outline),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.comment_outlined,
                      size: 16,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${answer.commentCount}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.comment});

  final Comment comment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MM/dd HH:mm');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: comment.user.avatarUrl != null
                ? NetworkImage(comment.user.avatarUrl!)
                : null,
            child: comment.user.avatarUrl == null
                ? Text(
                    comment.user.displayName.isNotEmpty
                        ? comment.user.displayName[0]
                        : '?',
                    style: theme.textTheme.labelSmall,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.user.displayName,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateFormat.format(comment.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.text,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentInputField extends StatelessWidget {
  const _CommentInputField({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    this.errorText,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final String? errorText;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                errorText!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: 'コメントを入力...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  maxLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSubmit(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: isLoading ? null : onSubmit,
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
