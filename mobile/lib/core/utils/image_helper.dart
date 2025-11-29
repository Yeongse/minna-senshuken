import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

import '../services/upload_service.dart';

// FileTooLargeExceptionを再エクスポート（upload_service.dartで定義）
export '../services/upload_service.dart' show FileTooLargeException;

/// 対応していないファイル形式の例外
class UnsupportedFileTypeException implements Exception {
  final String message;

  const UnsupportedFileTypeException([
    this.message = '対応していないファイル形式です（JPEG, PNG, GIFのみ）',
  ]);

  @override
  String toString() => 'UnsupportedFileTypeException: $message';
}

/// 画像選択・圧縮ヘルパー
class ImageHelper {
  /// 最大ファイルサイズ（10MB）
  static const int maxFileSizeBytes = 10 * 1024 * 1024;

  /// 最大幅
  static const int maxWidth = 1024;

  /// 最大高さ
  static const int maxHeight = 1024;

  /// 圧縮品質（1-100）
  static const int quality = 85;

  /// 対応ファイル形式
  static const List<String> supportedExtensions = [
    'jpg',
    'jpeg',
    'png',
    'gif',
  ];

  /// ファイル形式が対応しているかチェック
  static bool isValidFileType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    return supportedExtensions.contains(extension);
  }

  /// ギャラリーまたはカメラから画像を選択し、圧縮して返す
  ///
  /// [source] - 画像ソース（ギャラリーまたはカメラ）
  ///
  /// Returns: 圧縮済みのファイル、またはnull（キャンセル時）
  ///
  /// Throws:
  /// - [FileTooLargeException] - ファイルサイズが10MBを超える場合
  /// - [UnsupportedFileTypeException] - 対応していないファイル形式の場合
  static Future<File?> pickAndCompressImage({
    required ImageSource source,
  }) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile == null) {
      return null;
    }

    final file = File(pickedFile.path);

    // ファイル形式チェック
    if (!isValidFileType(pickedFile.path)) {
      throw const UnsupportedFileTypeException();
    }

    // ファイルサイズチェック
    final fileSize = await file.length();
    if (fileSize > maxFileSizeBytes) {
      throw FileTooLargeException();
    }

    // 圧縮
    final compressedFile = await _compressImage(file);
    return compressedFile;
  }

  /// 画像を圧縮
  static Future<File?> _compressImage(File file) async {
    final filePath = file.absolute.path;
    final lastIndex = filePath.lastIndexOf('.');
    final targetPath = lastIndex != -1
        ? '${filePath.substring(0, lastIndex)}_compressed.jpg'
        : '${filePath}_compressed.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      filePath,
      targetPath,
      minWidth: maxWidth,
      minHeight: maxHeight,
      quality: quality,
    );

    if (result == null) {
      return null;
    }

    return File(result.path);
  }

  /// 画像ソース選択のオプションを表示するためのヘルパー
  /// UIレイヤーで使用する選択肢
  static List<ImageSourceOption> get sourceOptions => const [
        ImageSourceOption(
          source: ImageSource.gallery,
          label: 'ギャラリーから選択',
        ),
        ImageSourceOption(
          source: ImageSource.camera,
          label: 'カメラで撮影',
        ),
      ];
}

/// 画像ソース選択オプション
class ImageSourceOption {
  final ImageSource source;
  final String label;

  const ImageSourceOption({
    required this.source,
    required this.label,
  });
}
