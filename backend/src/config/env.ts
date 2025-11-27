import { z } from 'zod';

const envSchema = z.object({
  DATABASE_URL: z.string().min(1),
  FIREBASE_PROJECT_ID: z.string().min(1),
  GCS_BUCKET_NAME: z.string().min(1),
  PORT: z.string().default('8080'),
});

export type Env = z.infer<typeof envSchema>;

export function loadEnv(): Env {
  const result = envSchema.safeParse(process.env);

  if (!result.success) {
    console.error('Environment validation failed:');
    console.error(result.error.format());
    throw new Error('Invalid environment variables');
  }

  return result.data;
}

export const env = loadEnv();
