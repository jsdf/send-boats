// src/handlers/login.ts
import { Env } from '../types';
import { renderPage } from '../helpers/prerenderedPage';

export async function handleLogin(request: Request, env: Env): Promise<Response> {
	// Handle GET request - show login form
	if (request.method === 'GET') {
		return await showLoginForm(env);
	}

	// Handle POST request - process login
	if (request.method === 'POST') {
		return await processLogin(request, env);
	}

	return new Response('Method not allowed', { status: 405 });
}

async function showLoginForm(env: Env, error?: string): Promise<Response> {
	const errorHtml = error ? `<div class="alert alert-error mb-4">${error}</div>` : '<!-- no error -->';

	if (error) {
		console.log('Showing login form with error:', error);
	}

	const html = await renderPage('login', { error: errorHtml }, env);

	return new Response(html, {
		headers: { 'Content-Type': 'text/html; charset=utf-8' },
	});
}

async function processLogin(request: Request, env: Env): Promise<Response> {
	try {
		const formData = await request.formData();
		const username = formData.get('username') as string;
		const password = formData.get('password') as string;

		console.log('Login attempt:', { username, hasPassword: !!password });
		console.log('Expected credentials:', {
			expectedUsername: env.BASIC_AUTH_USERNAME,
			hasExpectedPassword: !!env.BASIC_AUTH_PASSWORD,
		});

		if (!username || !password) {
			console.log('Missing username or password');
			return await showLoginForm(env, 'Please enter both username and password');
		}

		// Validate credentials
		if (username !== env.BASIC_AUTH_USERNAME || password !== env.BASIC_AUTH_PASSWORD) {
			console.log('Invalid credentials provided');
			return await showLoginForm(env, 'Invalid username or password');
		}

		console.log('Login successful, creating session'); // Generate session token
		const sessionToken = generateSessionToken();
		const expiresAt = Date.now() + 24 * 60 * 60 * 1000; // 24 hours

		// Store session in KV
		await env.RATE_LIMIT.put(
			`session:${sessionToken}`,
			JSON.stringify({
				username,
				expiresAt,
			}),
			{ expirationTtl: 24 * 60 * 60 }
		); // 24 hours TTL

		// Set cookie with plain server-side redirect
		// Check the actual Host header to detect localhost/dev environment
		const host = request.headers.get('Host') || '';
		const url = new URL(request.url);

		// Consider it localhost if Host header contains localhost/127.0.0.1/0.0.0.0 or if using DEV_ORIGIN
		const isLocalDev = host.includes('localhost') || host.includes('127.0.0.1') || host.includes('0.0.0.0') || !!env.DEV_ORIGIN;
		const isHttps = url.protocol === 'https:';

		// Only use Secure flag with HTTPS, use Lax for local development
		const cookieOptions =
			isLocalDev || !isHttps
				? `session=${sessionToken}; HttpOnly; SameSite=Lax; Max-Age=${24 * 60 * 60}; Path=/`
				: `session=${sessionToken}; HttpOnly; Secure; SameSite=Strict; Max-Age=${24 * 60 * 60}; Path=/`;

		console.log('Host header:', host, 'isLocalDev:', isLocalDev, 'protocol:', url.protocol);
		console.log('Cookie options:', cookieOptions);

		return new Response('', {
			status: 302,
			headers: {
				Location: '/',
				'Set-Cookie': cookieOptions,
			},
		});
	} catch (error) {
		console.error('Login error:', error);
		return await showLoginForm(env, 'An error occurred during login');
	}
}

export async function handleLogout(request: Request, env: Env): Promise<Response> {
	// Get session token from cookie
	const cookie = request.headers.get('Cookie');
	if (cookie) {
		const sessionMatch = cookie.match(/session=([^;]+)/);
		if (sessionMatch) {
			const sessionToken = sessionMatch[1];
			// Delete session from KV
			await env.RATE_LIMIT.delete(`session:${sessionToken}`);
		}
	}

	// Clear cookie and redirect to login
	const host = request.headers.get('Host') || '';
	const url = new URL(request.url);

	const isLocalDev = host.includes('localhost') || host.includes('127.0.0.1') || host.includes('0.0.0.0') || !!env.DEV_ORIGIN;
	const isHttps = url.protocol === 'https:';

	const cookieOptions =
		isLocalDev || !isHttps
			? 'session=; HttpOnly; SameSite=Lax; Max-Age=0; Path=/'
			: 'session=; HttpOnly; Secure; SameSite=Strict; Max-Age=0; Path=/';

	return new Response('', {
		status: 302,
		headers: {
			Location: '/looking-glass',
			'Set-Cookie': cookieOptions,
		},
	});
}

function generateSessionToken(): string {
	// Generate a cryptographically secure random token
	const array = new Uint8Array(32);
	crypto.getRandomValues(array);
	return Array.from(array, (byte) => byte.toString(16).padStart(2, '0')).join('');
}
