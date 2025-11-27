/// 選手権のステータス
enum ChampionshipStatus {
  recruiting, // 募集中
  selecting, // 選定中
  announced, // 結果発表済み
}

/// ChampionshipStatusのJSON変換拡張
extension ChampionshipStatusExtension on ChampionshipStatus {
  String toJson() {
    switch (this) {
      case ChampionshipStatus.recruiting:
        return 'recruiting';
      case ChampionshipStatus.selecting:
        return 'selecting';
      case ChampionshipStatus.announced:
        return 'announced';
    }
  }

  static ChampionshipStatus fromJson(String json) {
    switch (json) {
      case 'recruiting':
        return ChampionshipStatus.recruiting;
      case 'selecting':
        return ChampionshipStatus.selecting;
      case 'announced':
        return ChampionshipStatus.announced;
      default:
        throw ArgumentError('Unknown ChampionshipStatus: $json');
    }
  }
}

/// 受賞タイプ
enum AwardType {
  grandPrize, // 大賞
  prize, // 入賞
  specialPrize, // 特別賞
}

/// AwardTypeのJSON変換拡張
extension AwardTypeExtension on AwardType {
  String toJson() {
    switch (this) {
      case AwardType.grandPrize:
        return 'grand_prize';
      case AwardType.prize:
        return 'prize';
      case AwardType.specialPrize:
        return 'special_prize';
    }
  }

  static AwardType fromJson(String json) {
    switch (json) {
      case 'grand_prize':
        return AwardType.grandPrize;
      case 'prize':
        return AwardType.prize;
      case 'special_prize':
        return AwardType.specialPrize;
      default:
        throw ArgumentError('Unknown AwardType: $json');
    }
  }
}

/// 選手権のソート順
enum ChampionshipSort {
  newest, // 新着順
  popular, // 人気順
}

/// ChampionshipSortのJSON変換拡張
extension ChampionshipSortExtension on ChampionshipSort {
  String toJson() {
    switch (this) {
      case ChampionshipSort.newest:
        return 'newest';
      case ChampionshipSort.popular:
        return 'popular';
    }
  }

  static ChampionshipSort fromJson(String json) {
    switch (json) {
      case 'newest':
        return ChampionshipSort.newest;
      case 'popular':
        return ChampionshipSort.popular;
      default:
        throw ArgumentError('Unknown ChampionshipSort: $json');
    }
  }
}

/// 回答のソート順
enum AnswerSort {
  score, // スコア順
  newest, // 新着順
}

/// AnswerSortのJSON変換拡張
extension AnswerSortExtension on AnswerSort {
  String toJson() {
    switch (this) {
      case AnswerSort.score:
        return 'score';
      case AnswerSort.newest:
        return 'newest';
    }
  }

  static AnswerSort fromJson(String json) {
    switch (json) {
      case 'score':
        return AnswerSort.score;
      case 'newest':
        return AnswerSort.newest;
      default:
        throw ArgumentError('Unknown AnswerSort: $json');
    }
  }
}
