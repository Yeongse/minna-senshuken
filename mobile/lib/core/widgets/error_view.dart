import 'package:flutter/material.dart';

import '../api/api_exception.dart';

/// エラー表示ウィジェット
class ErrorView extends StatelessWidget {
  /// エラーメッセージ
  final String message;

  /// 再試行コールバック
  final VoidCallback? onRetry;

  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
  });

  /// ApiExceptionからErrorViewを生成
  factory ErrorView.fromException({
    Key? key,
    required Object exception,
    VoidCallback? onRetry,
  }) {
    final message = _extractErrorMessage(exception);
    return ErrorView(
      key: key,
      message: message,
      onRetry: onRetry,
    );
  }

  /// 例外からエラーメッセージを抽出
  static String _extractErrorMessage(Object exception) {
    if (exception is ApiException) {
      return exception.message;
    }
    return 'エラーが発生しました';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('再試行'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
