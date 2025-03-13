// src/helpers/auth.ts
import { Env } from '../types';

export async function checkBasicAuth(request: Request, env: Env): Promise<Response | null> {
	const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
	const authKey = 'auth:' + ip;
	const failCountStr = await env.RATE_LIMIT.get(authKey);
	const failCount = failCountStr ? parseInt(failCountStr) : 0;

	// Only impose exponential backoff if there have been at least 4 failed attempts.
	if (failCount >= 4) {
		const delay = Math.pow(2, failCount); // delay in seconds
		return new Response(`Too many failed auth attempts. Please retry after ${delay} seconds.`, {
			status: 429,
			headers: { 'Retry-After': delay.toString() },
		});
	}

	const authHeader = request.headers.get('Authorization');
	const expected = 'Basic ' + btoa(`${env.BASIC_AUTH_USERNAME}:${env.BASIC_AUTH_PASSWORD}`);

	if (authHeader !== expected) {
		// Increment failure counter and set a TTL of 1 day (86400 seconds).
		const newFailCount = failCount + 1;
		await env.RATE_LIMIT.put(authKey, newFailCount.toString(), { expirationTtl: 86400 });
		return new Response('Unauthorized', {
			status: 401,
			headers: { 'WWW-Authenticate': 'Basic realm="Secure Area"' },
		});
	}

	// On successful auth, clear any stored failure count.
	if (failCount > 0) {
		await env.RATE_LIMIT.delete(authKey);
	}

	return null;
}
