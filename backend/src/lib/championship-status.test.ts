import { describe, it, expect } from 'vitest';
import { ChampionshipStatus } from '@prisma/client';
import {
  computeChampionshipStatus,
  isRecruiting,
  isSelecting,
} from './championship-status';

describe('computeChampionshipStatus', () => {
  const now = new Date('2024-01-15T12:00:00Z');

  describe('ANNOUNCED status', () => {
    it('should return announced regardless of endAt', () => {
      const pastEndAt = new Date('2024-01-10T00:00:00Z');
      const futureEndAt = new Date('2024-01-20T00:00:00Z');

      expect(computeChampionshipStatus(ChampionshipStatus.ANNOUNCED, pastEndAt, now)).toBe('announced');
      expect(computeChampionshipStatus(ChampionshipStatus.ANNOUNCED, futureEndAt, now)).toBe('announced');
    });
  });

  describe('SELECTING status', () => {
    it('should return selecting regardless of endAt', () => {
      const pastEndAt = new Date('2024-01-10T00:00:00Z');
      const futureEndAt = new Date('2024-01-20T00:00:00Z');

      expect(computeChampionshipStatus(ChampionshipStatus.SELECTING, pastEndAt, now)).toBe('selecting');
      expect(computeChampionshipStatus(ChampionshipStatus.SELECTING, futureEndAt, now)).toBe('selecting');
    });
  });

  describe('RECRUITING status', () => {
    it('should return recruiting when endAt is in the future', () => {
      const futureEndAt = new Date('2024-01-20T00:00:00Z');
      expect(computeChampionshipStatus(ChampionshipStatus.RECRUITING, futureEndAt, now)).toBe('recruiting');
    });

    it('should return selecting when endAt is in the past', () => {
      const pastEndAt = new Date('2024-01-10T00:00:00Z');
      expect(computeChampionshipStatus(ChampionshipStatus.RECRUITING, pastEndAt, now)).toBe('selecting');
    });

    it('should return selecting when endAt equals now', () => {
      const exactNow = new Date('2024-01-15T12:00:00Z');
      expect(computeChampionshipStatus(ChampionshipStatus.RECRUITING, exactNow, now)).toBe('selecting');
    });
  });
});

describe('isRecruiting', () => {
  const now = new Date('2024-01-15T12:00:00Z');
  const futureEndAt = new Date('2024-01-20T00:00:00Z');
  const pastEndAt = new Date('2024-01-10T00:00:00Z');

  it('should return true only for RECRUITING with future endAt', () => {
    expect(isRecruiting(ChampionshipStatus.RECRUITING, futureEndAt, now)).toBe(true);
    expect(isRecruiting(ChampionshipStatus.RECRUITING, pastEndAt, now)).toBe(false);
    expect(isRecruiting(ChampionshipStatus.SELECTING, futureEndAt, now)).toBe(false);
    expect(isRecruiting(ChampionshipStatus.ANNOUNCED, futureEndAt, now)).toBe(false);
  });
});

describe('isSelecting', () => {
  const now = new Date('2024-01-15T12:00:00Z');
  const futureEndAt = new Date('2024-01-20T00:00:00Z');
  const pastEndAt = new Date('2024-01-10T00:00:00Z');

  it('should return true for SELECTING or RECRUITING with past endAt', () => {
    expect(isSelecting(ChampionshipStatus.SELECTING, futureEndAt, now)).toBe(true);
    expect(isSelecting(ChampionshipStatus.RECRUITING, pastEndAt, now)).toBe(true);
    expect(isSelecting(ChampionshipStatus.RECRUITING, futureEndAt, now)).toBe(false);
    expect(isSelecting(ChampionshipStatus.ANNOUNCED, futureEndAt, now)).toBe(false);
  });
});
