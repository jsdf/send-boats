import type { R2Bucket, D1Database, DurableObjectNamespace, KVNamespace } from '@cloudflare/workers-types';

export interface Env {
	R2_BUCKET: R2Bucket;
	DB: D1Database;
	FILE_COUNTER: DurableObjectNamespace;
	RATE_LIMIT: KVNamespace; // For rate limiting and auth failure tracking
	BASIC_AUTH_USERNAME: string;
	BASIC_AUTH_PASSWORD: string;
}

export interface UploadRecord {
	id: string;
	filename: string;
	filetype: string;
	uploaded_at: string;
	has_preview: boolean;
}
