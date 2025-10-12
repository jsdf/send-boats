import type { R2Bucket, D1Database, DurableObjectNamespace, KVNamespace, Fetcher } from '@cloudflare/workers-types';

export interface Env {
	R2_BUCKET: R2Bucket;
	DB: D1Database;
	FILE_COUNTER: DurableObjectNamespace;
	RATE_LIMIT: KVNamespace; // For rate limiting and auth failure tracking
	ASSETS: Fetcher; // Static assets from Vite build
	BASIC_AUTH_USERNAME: string;
	BASIC_AUTH_PASSWORD: string;
	VITE_DEV_URL?: string; // URL of Vite dev server (development only)
	GIT_SHA?: string; // Current git commit SHA
	GIT_DIRTY?: string; // "true" if there are uncommitted changes
}

export interface UploadRecord {
	id: string;
	filename: string;
	filetype: string;
	uploaded_at: string;
	has_preview: boolean;
}
