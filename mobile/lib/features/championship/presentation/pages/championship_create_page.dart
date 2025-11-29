import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/championship_providers.dart';

class ChampionshipCreatePage extends ConsumerStatefulWidget {
  const ChampionshipCreatePage({super.key});

  @override
  ConsumerState<ChampionshipCreatePage> createState() =>
      _ChampionshipCreatePageState();
}

class _ChampionshipCreatePageState
    extends ConsumerState<ChampionshipCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _durationDays = 7;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final notifier = ref.read(championshipCreateNotifierProvider.notifier);
    final success = await notifier.create(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      durationDays: _durationDays,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('選手権を作成しました'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(championshipCreateNotifierProvider);
    final theme = Theme.of(context);

    // Show error snackbar if there's an error
    ref.listen<ChampionshipCreateState>(
      championshipCreateNotifierProvider,
      (previous, next) {
        if (next.error != null && previous?.error != next.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.error!),
              backgroundColor: theme.colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('選手権作成'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: state.isLoading ? null : _submit,
            child: state.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('作成'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title field
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'タイトル',
                hintText: '面白いお題を入力してください',
                border: const OutlineInputBorder(),
                counterText: '${_titleController.text.length}/50',
                errorText: state.validationErrors['title'],
              ),
              maxLength: 50,
              textInputAction: TextInputAction.next,
              enabled: !state.isLoading,
              onChanged: (_) => setState(() {}),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'タイトルを入力してください';
                }
                if (value.length > 50) {
                  return 'タイトルは50文字以内で入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Description field
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: '説明',
                hintText: 'お題の詳細や注意事項を入力してください',
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
                counterText: '${_descriptionController.text.length}/500',
                errorText: state.validationErrors['description'],
              ),
              maxLength: 500,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              enabled: !state.isLoading,
              onChanged: (_) => setState(() {}),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '説明を入力してください';
                }
                if (value.length > 500) {
                  return '説明は500文字以内で入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            // Duration selection
            Text(
              '募集期間',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (state.validationErrors['durationDays'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  state.validationErrors['durationDays']!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$_durationDays日間',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Text(
                          _getDurationDescription(_durationDays),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Slider(
                      value: _durationDays.toDouble(),
                      min: 1,
                      max: 14,
                      divisions: 13,
                      label: '$_durationDays日',
                      onChanged: state.isLoading
                          ? null
                          : (value) {
                              setState(() {
                                _durationDays = value.round();
                              });
                            },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '1日',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        Text(
                          '14日',
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
            const SizedBox(height: 24),
            // Info card
            Card(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '選手権を作成すると、すぐに募集が開始されます。募集期間終了後は選考フェーズに移行し、受賞者を選ぶことができます。',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Submit button
            FilledButton.icon(
              onPressed: state.isLoading ? null : _submit,
              icon: state.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add),
              label: Text(state.isLoading ? '作成中...' : '選手権を作成'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDurationDescription(int days) {
    if (days <= 3) {
      return '短期決戦';
    } else if (days <= 7) {
      return 'おすすめ';
    } else if (days <= 10) {
      return 'じっくり募集';
    } else {
      return '長期募集';
    }
  }
}
