import 'dart:io';

import 'package:dio/dio.dart';

import '../api/api_client.dart';

/// アップロードエラー
sealed class UploadException implements Exception {
  String get message;
}

class InvalidFileTypeException extends UploadException {
  @override
  final String message = '許可されていないファイル形式です';
}

class FileTooLargeException extends UploadException {
  @override
  final String message = 'ファイルサイズが10MBを超えています';
}

class UploadFailedException extends UploadException {
  @override
  final String message;
  final bool canRetry;
  UploadFailedException(this.message, {this.canRetry = true});
}

/// 署名付きURLレスポンス
class SignedUrlResponse {
  final String uploadUrl;
  final String publicUrl;

  const SignedUrlResponse({
    required this.uploadUrl,
    required this.publicUrl,
  });

  factory SignedUrlResponse.fromJson(Map<String, dynamic> json) {
    return SignedUrlResponse(
      uploadUrl: json['uploadUrl'] as String,
      publicUrl: json['publicUrl'] as String,
    );
  }
}

/// 画像アップロードサービスのインターフェース
abstract class UploadServiceInterface {
  /// 画像をアップロード
  /// [onProgress]でアップロード進捗（0.0〜1.0）を通知
  Future<String> uploadImage(
    File file, {
    void Function(double progress)? onProgress,
  });
}

/// 画像アップロードサービス
class UploadService implements UploadServiceInterface {
  final ApiClient _apiClient;
  final Dio _uploadDio;

  /// 許可されたファイル拡張子
  static const _allowedExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
  ];

  /// ファイルサイズ上限（10MB）
  static const _maxFileSize = 10 * 1024 * 1024;

  UploadService({
    required ApiClient apiClient,
    Dio? uploadDio,
  })  : _apiClient = apiClient,
        _uploadDio = uploadDio ?? Dio();

  @override
  Future<String> uploadImage(
    File file, {
    void Function(double progress)? onProgress,
  }) async {
    // ファイル検証
    await _validateFile(file);

    // 署名付きURL取得
    final signedUrl = await _getSignedUrl(file);

    // GCSへアップロード
    await _uploadToGcs(file, signedUrl.uploadUrl, onProgress);

    return signedUrl.publicUrl;
  }

  Future<void> _validateFile(File file) async {
    // ファイル存在確認
    if (!await file.exists()) {
      throw UploadFailedException('ファイルが見つかりません', canRetry: false);
    }

    // ファイルサイズ検証
    final fileSize = await file.length();
    if (fileSize > _maxFileSize) {
      throw FileTooLargeException();
    }

    // ファイル形式検証（拡張子）
    final extension = file.path.toLowerCase().substring(
          file.path.lastIndexOf('.'),
        );
    if (!_allowedExtensions.contains(extension)) {
      throw InvalidFileTypeException();
    }
  }

  Future<SignedUrlResponse> _getSignedUrl(File file) async {
    final extension = file.path.toLowerCase().substring(
          file.path.lastIndexOf('.'),
        );

    // MIMEタイプを拡張子から推測
    final mimeType = _getMimeType(extension);

    return _apiClient.post<SignedUrlResponse>(
      '/uploads/signed-url',
      data: {
        'contentType': mimeType,
      },
      fromJson: SignedUrlResponse.fromJson,
    );
  }

  String _getMimeType(String extension) {
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _uploadToGcs(
    File file,
    String uploadUrl,
    void Function(double progress)? onProgress,
  ) async {
    try {
      final fileBytes = await file.readAsBytes();
      final extension = file.path.toLowerCase().substring(
            file.path.lastIndexOf('.'),
          );
      final mimeType = _getMimeType(extension);

      await _uploadDio.put<void>(
        uploadUrl,
        data: Stream.fromIterable([fileBytes]),
        options: Options(
          headers: {
            'Content-Type': mimeType,
            'Content-Length': fileBytes.length,
          },
        ),
        onSendProgress: (sent, total) {
          if (onProgress != null && total > 0) {
            onProgress(sent / total);
          }
        },
      );
    } on DioException catch (e) {
      throw UploadFailedException(
        'アップロードに失敗しました: ${e.message}',
        canRetry: true,
      );
    }
  }
}
