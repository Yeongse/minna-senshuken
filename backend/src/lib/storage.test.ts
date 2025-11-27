import { describe, it, expect, vi, beforeEach } from 'vitest';
import { generateUploadUrl, getStorage, type GenerateUploadUrlOptions } from './storage';

// Mock @google-cloud/storage
const mockGetSignedUrl = vi.fn();
const mockFile = vi.fn(() => ({
  getSignedUrl: mockGetSignedUrl,
}));
const mockBucket = vi.fn(() => ({
  file: mockFile,
}));

vi.mock('@google-cloud/storage', () => ({
  Storage: vi.fn(() => ({
    bucket: mockBucket,
  })),
}));

describe('Storage Service', () => {
  const bucketName = 'test-bucket';

  beforeEach(() => {
    vi.clearAllMocks();
    mockGetSignedUrl.mockResolvedValue(['https://signed-url.example.com']);
  });

  describe('generateUploadUrl', () => {
    const options: GenerateUploadUrlOptions = {
      fileName: 'test-image.png',
      contentType: 'image/png',
      userId: 'user-123',
    };

    it('should generate signed upload URL', async () => {
      const result = await generateUploadUrl(bucketName, options);

      expect(result.uploadUrl).toBe('https://signed-url.example.com');
      expect(result.publicUrl).toMatch(
        /^https:\/\/storage\.googleapis\.com\/test-bucket\/uploads\/user-123\/\d+_test-image\.png$/
      );
      expect(result.expiresAt).toBeInstanceOf(Date);
      expect(result.expiresAt.getTime()).toBeGreaterThan(Date.now());
    });

    it('should use correct bucket and file path', async () => {
      await generateUploadUrl(bucketName, options);

      expect(mockBucket).toHaveBeenCalledWith(bucketName);
      expect(mockFile).toHaveBeenCalledWith(
        expect.stringMatching(/^uploads\/user-123\/\d+_test-image\.png$/)
      );
    });

    it('should configure signed URL with correct options', async () => {
      await generateUploadUrl(bucketName, options);

      expect(mockGetSignedUrl).toHaveBeenCalledWith(
        expect.objectContaining({
          version: 'v4',
          action: 'write',
          contentType: 'image/png',
        })
      );
    });

    it('should set expiry to 15 minutes from now', async () => {
      const beforeCall = Date.now();
      const result = await generateUploadUrl(bucketName, options);
      const afterCall = Date.now();

      const fifteenMinutes = 15 * 60 * 1000;
      expect(result.expiresAt.getTime()).toBeGreaterThanOrEqual(beforeCall + fifteenMinutes);
      expect(result.expiresAt.getTime()).toBeLessThanOrEqual(afterCall + fifteenMinutes + 1000);
    });
  });

  describe('getStorage', () => {
    it('should return Storage instance', () => {
      const storage = getStorage();
      expect(storage).toBeDefined();
    });

    it('should return same instance on multiple calls', () => {
      const storage1 = getStorage();
      const storage2 = getStorage();
      expect(storage1).toBe(storage2);
    });
  });
});
