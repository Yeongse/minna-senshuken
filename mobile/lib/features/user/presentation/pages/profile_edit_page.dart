import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/providers/user_providers.dart';
import '../../../../core/utils/image_helper.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';

class ProfileEditPage extends ConsumerStatefulWidget {
  const ProfileEditPage({super.key});

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _twitterUrlController = TextEditingController();

  File? _selectedImage;
  String? _currentAvatarUrl;
  bool _isInitialized = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _twitterUrlController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    final profileAsync = ref.read(profileProvider);
    profileAsync.whenData((profile) {
      if (profile != null && !_isInitialized) {
        _displayNameController.text = profile.displayName;
        _bioController.text = profile.bio ?? '';
        _twitterUrlController.text = profile.twitterUrl ?? '';
        _currentAvatarUrl = profile.avatarUrl;
        _isInitialized = true;
      }
    });
  }

  Future<void> _selectImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('ギャラリーから選択'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('カメラで撮影'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final file = await ImageHelper.pickAndCompressImage(source: source);
      if (file != null) {
        setState(() {
          _selectedImage = file;
        });
        ref.read(profileEditNotifierProvider.notifier).setAvatarFile(file);
      }
    } on FileTooLargeException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ファイルサイズが10MBを超えています')),
        );
      }
    } on UnsupportedFileTypeException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('対応していないファイル形式です（JPEG, PNG, GIFのみ）')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(profileEditNotifierProvider.notifier);
    final success = await notifier.updateProfile(
      displayName: _displayNameController.text.trim(),
      bio: _bioController.text.trim().isEmpty
          ? null
          : _bioController.text.trim(),
      twitterUrl: _twitterUrlController.text.trim().isEmpty
          ? null
          : _twitterUrlController.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('プロフィールを更新しました')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final editState = ref.watch(profileEditNotifierProvider);

    // エラーメッセージを表示
    ref.listen(profileEditNotifierProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール編集'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: editState.isLoading ? null : _saveProfile,
            child: editState.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('プロフィールを読み込めません'));
          }
          _initializeForm();
          return _buildForm();
        },
        loading: () => const LoadingView(),
        error: (error, stack) => ErrorView.fromException(
          exception: error,
          onRetry: () => ref.invalidate(profileProvider),
        ),
      ),
    );
  }

  Widget _buildForm() {
    final notifier = ref.read(profileEditNotifierProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // アバター画像
            GestureDetector(
              onTap: _selectImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : (_currentAvatarUrl != null
                            ? NetworkImage(_currentAvatarUrl!)
                            : null) as ImageProvider?,
                    child: _selectedImage == null && _currentAvatarUrl == null
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 20,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _selectImage,
              child: const Text('画像を変更'),
            ),
            const SizedBox(height: 24),

            // 表示名
            TextFormField(
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: '表示名 *',
                hintText: '表示名を入力',
                border: OutlineInputBorder(),
              ),
              validator: notifier.validateDisplayName,
              maxLength: 30,
            ),
            const SizedBox(height: 16),

            // 自己紹介
            TextFormField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: '自己紹介',
                hintText: '自己紹介を入力',
                border: OutlineInputBorder(),
              ),
              validator: notifier.validateBio,
              maxLines: 3,
              maxLength: 200,
            ),
            const SizedBox(height: 16),

            // Twitter URL
            TextFormField(
              controller: _twitterUrlController,
              decoration: const InputDecoration(
                labelText: 'Twitter URL',
                hintText: 'https://twitter.com/username',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
      ),
    );
  }
}
