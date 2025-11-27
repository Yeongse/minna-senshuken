import { ChampionshipStatus } from '@prisma/client';

export type ComputedStatus = 'recruiting' | 'selecting' | 'announced';

/**
 * 選手権のステータスを動的に計算する
 *
 * - ANNOUNCED: 結果発表済み → そのまま 'announced'
 * - SELECTING: 選定中 → そのまま 'selecting'
 * - RECRUITING + end_at が過去 → 'selecting' (自動遷移)
 * - RECRUITING + end_at が未来 → 'recruiting'
 */
export function computeChampionshipStatus(
  dbStatus: ChampionshipStatus,
  endAt: Date,
  now: Date = new Date()
): ComputedStatus {
  if (dbStatus === ChampionshipStatus.ANNOUNCED) {
    return 'announced';
  }

  if (dbStatus === ChampionshipStatus.SELECTING) {
    return 'selecting';
  }

  // RECRUITING の場合、end_at をチェック
  if (endAt <= now) {
    return 'selecting';
  }

  return 'recruiting';
}

/**
 * ステータスが募集中かどうか
 */
export function isRecruiting(
  dbStatus: ChampionshipStatus,
  endAt: Date,
  now: Date = new Date()
): boolean {
  return computeChampionshipStatus(dbStatus, endAt, now) === 'recruiting';
}

/**
 * ステータスが選定中かどうか
 */
export function isSelecting(
  dbStatus: ChampionshipStatus,
  endAt: Date,
  now: Date = new Date()
): boolean {
  return computeChampionshipStatus(dbStatus, endAt, now) === 'selecting';
}
