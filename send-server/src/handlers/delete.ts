import { Env, UploadRecord } from '../types';

import { checkBasicAuth } from '../helpers/auth';

export async function handleDelete(request: Request, env: Env, key: string): Promise<Response> {
	// Protect deletion with HTTP Basic Auth.
	const authResp = await checkBasicAuth(request, env);
	if (authResp) return authResp;

	// Get the record to check if it has a preview
	const record = (await env.DB.prepare('SELECT * FROM uploads WHERE id = ?').bind(key).first()) as UploadRecord | null;

	// Delete record from D1.
	await env.DB.prepare('DELETE FROM uploads WHERE id = ?').bind(key).run();

	// Delete file from R2.
	await env.R2_BUCKET.delete(key);

	// If the file had a preview, delete the preview image too
	if (record && record.filetype.startsWith('video/') && record.has_preview) {
		await env.R2_BUCKET.delete(`${key}-preview`);
	}

	// Optionally: signal the Durable Object to clear its counter.
	return new Response('File deleted successfully', { status: 200 });
}
