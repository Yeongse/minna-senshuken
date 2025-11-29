import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/providers/answer_providers.dart';
import '../../../../core/utils/image_helper.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';

class AnswerEditPage extends ConsumerStatefulWidget {
  const AnswerEditPage({
    required this.championshipId,
    required this.answerId,
    super.key,
  });

  final String championshipId;
  final String answerId;

  @override
  ConsumerState<AnswerEditPage> createState() => _AnswerEditPageState();
}

class _AnswerEditPageState extends ConsumerState<AnswerEditPage> {
  final _textController = TextEditingController();
  bool _isInitialized = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final params = (
      championshipId: widget.championshipId,
      answerId: widget.answerId,
    );
    final state = ref.watch(answerEditNotifierProvider(params));
    final notifier = ref.read(answerEditNotifierProvider(params).notifier);

    // 初期化
    if (!state.isInitialized && !state.isLoading && state.error == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.init();
      });
    }

    // テキストフィールドに初期値を設定
    if (state.isInitialized && !_isInitialized && state.originalAnswer != null) {
      _textController.text = state.originalAnswer!.text;
      _isInitialized = true;
    }

    // 更新成功時の処理
    ref.listen(answerEditNotifierProvider(params), (previous, next) {
      if (next.updatedAnswer != null && previous?.updatedAnswer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('回答を更新しました')),
        );
        notifier.reset();
        context.pop();
      }
      if (next.error != null && previous?.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: ${next.error}')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('回答編集'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            notifier.reset();
            context.pop();
          },
        ),
        actions: [
          if (state.isInitialized)
            TextButton(
              onPressed: state.isLoading
                  ? null
                  : () {
                      notifier.update(text: _textController.text);
                    },
              child: state.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('保存'),
            ),
        ],
      ),
      body: _buildBody(state, notifier),
    );
  }

  Widget _buildBody(AnswerEditState state, AnswerEditNotifier notifier) {
    if (state.isLoading && !state.isInitialized) {
      return const LoadingView();
    }

    if (state.error != null && !state.isInitialized) {
      return ErrorView(
        message: state.error!,
        onRetry: () => notifier.init(),
      );
    }

    if (!state.isInitialized) {
      return const LoadingView();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 回答テキスト
          _TextInputSection(
            controller: _textController,
            errorText: state.validationErrors['text'],
          ),
          const SizedBox(height: 24),
          // 画像選択
          _ImageSection(
            originalImageUrl: state.originalAnswer?.imageUrl,
            selectedImage: state.selectedImage,
            hasNewImage: state.hasNewImage,
            uploadProgress: state.uploadProgress,
            onPickImage: (source) => _pickImage(source, notifier),
            onRemoveImage: () => notifier.setImage(null),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, AnswerEditNotifier notifier) async {
    try {
      final file = await ImageHelper.pickAndCompressImage(source: source);
      if (file != null) {
        notifier.setImage(file);
      }
    } on FileTooLargeException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } on UnsupportedFileTypeException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }
}

class _TextInputSection extends StatelessWidget {
  const _TextInputSection({
    required this.controller,
    this.errorText,
  });

  final TextEditingController controller;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '回答',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'あなたの回答を入力してください',
            border: const OutlineInputBorder(),
            errorText: errorText,
            counterText: '',
          ),
          maxLines: 5,
          maxLength: 300,
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              final length = value.text.length;
              final isOver = length > 300;
              return Text(
                '$length/300',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isOver ? theme.colorScheme.error : theme.colorScheme.outline,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ImageSection extends StatelessWidget {
  const _ImageSection({
    required this.originalImageUrl,
    required this.selectedImage,
    required this.hasNewImage,
    this.uploadProgress,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  final String? originalImageUrl;
  final File? selectedImage;
  final bool hasNewImage;
  final double? uploadProgress;
  final void Function(ImageSource source) onPickImage;
  final VoidCallback onRemoveImage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '画像（任意）',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (hasNewImage && selectedImage != null)
          _SelectedImagePreview(
            image: selectedImage!,
            uploadProgress: uploadProgress,
            onRemove: onRemoveImage,
          )
        else if (!hasNewImage && originalImageUrl != null)
          _ExistingImagePreview(
            imageUrl: originalImageUrl!,
            onReplace: onPickImage,
          )
        else
          _ImagePickerButtons(onPickImage: onPickImage),
        const SizedBox(height: 8),
        Text(
          '対応形式: JPEG, PNG, GIF（最大10MB）',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}

class _ExistingImagePreview extends StatelessWidget {
  const _ExistingImagePreview({
    required this.imageUrl,
    required this.onReplace,
  });

  final String imageUrl;
  final void Function(ImageSource source) onReplace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl,
            width: double.infinity,
            height: 200,
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
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => onReplace(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('画像を変更'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SelectedImagePreview extends StatelessWidget {
  const _SelectedImagePreview({
    required this.image,
    this.uploadProgress,
    required this.onRemove,
  });

  final File image;
  final double? uploadProgress;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            image,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
          ),
        ),
        // アップロード進捗
        if (uploadProgress != null)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(value: uploadProgress),
                    const SizedBox(height: 8),
                    Text(
                      '${(uploadProgress! * 100).toInt()}%',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        // 削除ボタン
        if (uploadProgress == null)
          Positioned(
            top: 8,
            right: 8,
            child: IconButton.filled(
              onPressed: onRemove,
              icon: const Icon(Icons.close),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                foregroundColor: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}

class _ImagePickerButtons extends StatelessWidget {
  const _ImagePickerButtons({required this.onPickImage});

  final void Function(ImageSource source) onPickImage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => onPickImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library),
            label: const Text('ギャラリー'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => onPickImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: const Text('カメラ'),
          ),
        ),
      ],
    );
  }
}
