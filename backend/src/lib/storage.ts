import { Storage } from '@google-cloud/storage';

let storage: Storage | null = null;

export function getStorage(): Storage {
  if (!storage) {
    storage = new Storage();
  }
  return storage;
}

export interface GenerateUploadUrlOptions {
  fileName: string;
  contentType: string;
  userId: string;
}

export interface UploadUrlResult {
  uploadUrl: string;
  publicUrl: string;
  expiresAt: Date;
}

const UPLOAD_URL_EXPIRY_MS = 15 * 60 * 1000; // 15 minutes

/**
 * Generate a signed URL for uploading a file to Cloud Storage
 */
export async function generateUploadUrl(
  bucketName: string,
  options: GenerateUploadUrlOptions
): Promise<UploadUrlResult> {
  const storage = getStorage();
  const bucket = storage.bucket(bucketName);

  // Generate unique file path: uploads/{userId}/{timestamp}_{fileName}
  const timestamp = Date.now();
  const filePath = `uploads/${options.userId}/${timestamp}_${options.fileName}`;
  const file = bucket.file(filePath);

  const expiresAt = new Date(Date.now() + UPLOAD_URL_EXPIRY_MS);

  // Generate signed URL for PUT operation
  const [uploadUrl] = await file.getSignedUrl({
    version: 'v4',
    action: 'write',
    expires: expiresAt,
    contentType: options.contentType,
  });

  // Public URL for accessing the file after upload
  const publicUrl = `https://storage.googleapis.com/${bucketName}/${filePath}`;

  return {
    uploadUrl,
    publicUrl,
    expiresAt,
  };
}
