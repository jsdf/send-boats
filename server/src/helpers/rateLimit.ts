// src/helpers/rateLimit.ts
import { Env } from '../types';

export async function checkRateLimit(request: Request, env: Env): Promise<Response | null> {
	// Use the CF-Connecting-IP header to determine the client IP.
	const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
	const key = 'rate:' + ip;
	const currentCountStr = await env.RATE_LIMIT.get(key);
	let count = currentCountStr ? parseInt(currentCountStr) : 0;
	count++;
	// Set a TTL for the rate limit window (60 seconds)
	await env.RATE_LIMIT.put(key, count.toString(), { expirationTtl: 60 });
	if (count > 100) {
		return new Response('Rate limit exceeded', { status: 429 });
	}
	return null;
}
