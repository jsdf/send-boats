// src/helpers/url.ts
import { Env } from '../types';

/**
 * Gets the correct origin URL for the current request.
 *
 * In development, Cloudflare Workers uses the production hostname from wrangler.toml
 * even though the server is actually running on localhost. This function uses the Host
 * header to get the actual hostname being accessed.
 *
 * In preview mode (deployed previews), the Host header is also set to the production
 * domain. To override this, set the PREVIEW_ORIGIN environment variable to the actual
 * preview URL (e.g., "https://abc123.send-server.workers.dev").
 *
 * @param request The incoming request
 * @param env Environment bindings
 * @returns The correct origin URL (e.g., "http://127.0.0.1:8787" or "https://send.boats")
 */
export function getOriginUrl(request: Request, env: Env): string {
	// If DEV_ORIGIN is explicitly set (for local dev), use it
	if (env.DEV_ORIGIN) {
		return env.DEV_ORIGIN;
	}

	// Get the Host header which has the actual hostname being accessed
	// In local dev: Host = "127.0.0.1:8787" (correct)
	// In preview: Host = "send.boats" (wrong - set PREVIEW_ORIGIN env var instead)
	// In production: Host = "send.boats" (correct)
	const host = request.headers.get('Host');
	if (!host) {
		// Fallback to request.url origin if no Host header (shouldn't happen)
		return new URL(request.url).origin;
	}

	// Determine if we're using HTTPS
	const url = new URL(request.url);
	const isLocalDev = host.includes('localhost') || host.includes('127.0.0.1') || host.includes('0.0.0.0');
	const protocol = isLocalDev ? 'http:' : url.protocol;

	// Build the origin from the Host header and protocol
	return `${protocol}//${host}`;
}

/**
 * Builds a full URL from a path using the correct origin.
 *
 * @param path The path to build the URL for (e.g., "/download/abc123")
 * @param request The incoming request
 * @param env Environment bindings
 * @returns The full URL (e.g., "http://127.0.0.1:8787/download/abc123")
 */
export function buildUrl(path: string, request: Request, env: Env): string {
	const origin = getOriginUrl(request, env);
	return `${origin}${path}`;
}
