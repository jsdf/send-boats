// src/helpers/auth.ts
import { Env } from '../types';

export async function checkAuth(request: Request, env: Env): Promise<Response | null> {
	// First check if there's a basic auth header (for iOS app)
	const authHeader = request.headers.get('Authorization');
	if (authHeader) {
		return await validateBasicAuth(request, env);
	}

	// If no basic auth, check for session cookie (for web interface)
	return await checkSessionAuth(request, env);
}

async function validateBasicAuth(request: Request, env: Env): Promise<Response | null> {
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

async function checkSessionAuth(request: Request, env: Env): Promise<Response | null> {
	// Get session token from cookie
	const cookie = request.headers.get('Cookie');
	let sessionToken: string | null = null;

	console.log('checkSessionAuth - Cookie header:', cookie);

	if (cookie) {
		const sessionMatch = cookie.match(/session=([^;]+)/);
		if (sessionMatch) {
			sessionToken = sessionMatch[1];
		}
	}

	console.log('checkSessionAuth - Session token found:', !!sessionToken);

	if (!sessionToken) {
		console.log('checkSessionAuth - No session token, redirecting to login');
		return redirectToLogin(request);
	}

	// Validate session token
	try {
		const sessionData = await env.RATE_LIMIT.get(`session:${sessionToken}`);
		console.log('checkSessionAuth - Session data from KV:', !!sessionData);

		if (!sessionData) {
			console.log('checkSessionAuth - No session data in KV, redirecting to login');
			return redirectToLogin(request);
		}

		const session = JSON.parse(sessionData);
		const isExpired = session.expiresAt < Date.now();
		console.log('checkSessionAuth - Session expired?', isExpired);

		if (isExpired) {
			// Session expired, clean it up
			await env.RATE_LIMIT.delete(`session:${sessionToken}`);
			console.log('checkSessionAuth - Session expired, redirecting to login');
			return redirectToLogin(request);
		}

		// Session is valid
		console.log('checkSessionAuth - Session valid, allowing access');
		return null;
	} catch (error) {
		console.error('Session validation error:', error);
		return redirectToLogin(request);
	}
}

function redirectToLogin(request: Request): Response {
	// Check if this is an API request (has Accept: application/json or similar)
	const acceptHeader = request.headers.get('Accept');
	const userAgent = request.headers.get('User-Agent');

	// If it's clearly an API request, return 401 instead of redirect
	if (
		acceptHeader?.includes('application/json') ||
		userAgent?.includes('APIClient') ||
		userAgent?.includes('curl') ||
		userAgent?.includes('wget')
	) {
		return new Response('Unauthorized', {
			status: 401,
			headers: { 'WWW-Authenticate': 'Cookie realm="Secure Area"' },
		});
	}

	// For browser requests, redirect to login page
	return new Response('', {
		status: 302,
		headers: {
			Location: '/login',
		},
	});
}

// Keep the original function for backward compatibility, but mark it as deprecated
export async function checkBasicAuth(request: Request, env: Env): Promise<Response | null> {
	return await checkAuth(request, env);
}
