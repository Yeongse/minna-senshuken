import { describe, it, expect } from 'vitest';
import {
  paginationSchema,
  createPaginatedResult,
  calculateSkip,
} from './pagination';

describe('paginationSchema', () => {
  it('should use default values when not provided', () => {
    const result = paginationSchema.parse({});
    expect(result.page).toBe(1);
    expect(result.limit).toBe(20);
  });

  it('should parse string values to numbers', () => {
    const result = paginationSchema.parse({ page: '2', limit: '50' });
    expect(result.page).toBe(2);
    expect(result.limit).toBe(50);
  });

  it('should reject page less than 1', () => {
    expect(() => paginationSchema.parse({ page: 0 })).toThrow();
    expect(() => paginationSchema.parse({ page: -1 })).toThrow();
  });

  it('should reject limit greater than 100', () => {
    expect(() => paginationSchema.parse({ limit: 101 })).toThrow();
  });

  it('should reject limit less than 1', () => {
    expect(() => paginationSchema.parse({ limit: 0 })).toThrow();
  });
});

describe('createPaginatedResult', () => {
  it('should create paginated result with correct structure', () => {
    const items = [{ id: '1' }, { id: '2' }];
    const result = createPaginatedResult(items, 50, { page: 1, limit: 20 });

    expect(result.items).toEqual(items);
    expect(result.pagination).toEqual({
      page: 1,
      limit: 20,
      total: 50,
      totalPages: 3,
    });
  });

  it('should calculate totalPages correctly', () => {
    const result1 = createPaginatedResult([], 100, { page: 1, limit: 20 });
    expect(result1.pagination.totalPages).toBe(5);

    const result2 = createPaginatedResult([], 101, { page: 1, limit: 20 });
    expect(result2.pagination.totalPages).toBe(6);

    const result3 = createPaginatedResult([], 0, { page: 1, limit: 20 });
    expect(result3.pagination.totalPages).toBe(0);
  });
});

describe('calculateSkip', () => {
  it('should calculate skip value correctly', () => {
    expect(calculateSkip({ page: 1, limit: 20 })).toBe(0);
    expect(calculateSkip({ page: 2, limit: 20 })).toBe(20);
    expect(calculateSkip({ page: 3, limit: 10 })).toBe(20);
    expect(calculateSkip({ page: 5, limit: 50 })).toBe(200);
  });
});
