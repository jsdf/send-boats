import { Env } from '../types';

import { checkBasicAuth } from '../helpers/auth';

export async function handleDelete(request: Request, env: Env, key: string): Promise<Response> {
	// Protect deletion with HTTP Basic Auth.
	const authResp = checkBasicAuth(request);
	if (authResp) return authResp;

	// Delete record from D1.
	await env.DB.prepare('DELETE FROM uploads WHERE id = ?').bind(key).run();
	// Delete file from R2.
	await env.R2_BUCKET.delete(key);
	// Optionally: signal the Durable Object to clear its counter.
	return new Response('File deleted successfully', { status: 200 });
}
