import 'package:intl/intl.dart';

/// 日付・時刻の変換ユーティリティ
class DateTimeUtils {
  DateTimeUtils._();

  /// ISO 8601文字列をDateTimeに変換
  static DateTime fromIso8601(String isoString) {
    return DateTime.parse(isoString);
  }

  /// DateTimeをISO 8601文字列に変換
  static String toIso8601(DateTime dateTime) {
    return dateTime.toUtc().toIso8601String();
  }

  /// 相対時間表示に変換（「3分前」「2日前」等）
  static String toRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.isNegative) {
      // 未来の日時
      return _toFutureRelativeTime(difference.abs());
    }

    if (difference.inSeconds < 60) {
      return 'たった今';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}時間前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks週間前';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$monthsヶ月前';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years年前';
    }
  }

  static String _toFutureRelativeTime(Duration difference) {
    if (difference.inSeconds < 60) {
      return 'まもなく';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分後';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}時間後';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日後';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks週間後';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$monthsヶ月後';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years年後';
    }
  }

  /// 日本語フォーマットに変換（「2024年1月15日」等）
  static String toJapaneseDate(DateTime dateTime) {
    final formatter = DateFormat('yyyy年M月d日', 'ja_JP');
    return formatter.format(dateTime);
  }

  /// 日本語日時フォーマットに変換（「2024年1月15日 14:30」等）
  static String toJapaneseDateTime(DateTime dateTime) {
    final formatter = DateFormat('yyyy年M月d日 HH:mm', 'ja_JP');
    return formatter.format(dateTime);
  }

  /// 短い日本語フォーマット（「1月15日」等）
  static String toShortJapaneseDate(DateTime dateTime) {
    final formatter = DateFormat('M月d日', 'ja_JP');
    return formatter.format(dateTime);
  }

  /// 時刻のみのフォーマット（「14:30」等）
  static String toTimeOnly(DateTime dateTime) {
    final formatter = DateFormat('HH:mm', 'ja_JP');
    return formatter.format(dateTime);
  }
}
