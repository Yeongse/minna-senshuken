import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/providers/answer_providers.dart';
import '../../../../core/utils/image_helper.dart';

class AnswerCreatePage extends ConsumerStatefulWidget {
  const AnswerCreatePage({
    required this.championshipId,
    super.key,
  });

  final String championshipId;

  @override
  ConsumerState<AnswerCreatePage> createState() => _AnswerCreatePageState();
}

class _AnswerCreatePageState extends ConsumerState<AnswerCreatePage> {
  final _textController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(answerCreateNotifierProvider(widget.championshipId));
    final notifier = ref.read(answerCreateNotifierProvider(widget.championshipId).notifier);

    // 投稿成功時の処理
    ref.listen(answerCreateNotifierProvider(widget.championshipId), (previous, next) {
      if (next.answer != null && previous?.answer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('回答を投稿しました')),
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
        title: const Text('回答投稿'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            notifier.reset();
            context.pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: state.isLoading
                ? null
                : () {
                    notifier.create(text: _textController.text);
                  },
            child: state.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('投稿'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
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
                selectedImage: state.selectedImage,
                uploadProgress: state.uploadProgress,
                onPickImage: (source) => _pickImage(source, notifier),
                onRemoveImage: () => notifier.setImage(null),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, AnswerCreateNotifier notifier) async {
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
    required this.selectedImage,
    this.uploadProgress,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  final File? selectedImage;
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
        if (selectedImage != null)
          _SelectedImagePreview(
            image: selectedImage!,
            uploadProgress: uploadProgress,
            onRemove: onRemoveImage,
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
