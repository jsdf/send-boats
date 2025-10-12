// src/index.ts
import { handleUpload } from './handlers/upload';
import { handleUploadForm } from './handlers/uploadForm';
import { handleView } from './handlers/view';
import { handleDownload } from './handlers/download';
import { handleList } from './handlers/list';
import { handleFull } from './handlers/full';
import { handleDelete } from './handlers/delete';
import { handlePreview } from './handlers/preview';
import { Env } from './types';
import { checkAuth } from './helpers/auth';
import { handleLogin, handleLogout } from './handlers/login';
import { checkRateLimit } from './helpers/rateLimit';

export default {
	async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
		// Rate limit all requests.
		const rateLimitResp = await checkRateLimit(request, env);
		if (rateLimitResp) return rateLimitResp;

		const url = new URL(request.url);
		const pathname = url.pathname;
		const method = request.method;

		// PRIORITY 1: Handle dynamic routes FIRST to preempt asset serving

		// Authentication routes (no auth required)
		if (pathname === '/looking-glass') {
			return await handleLogin(request, env);
		}

		if (pathname === '/logout') {
			return await handleLogout(request, env);
		}

		// Server-rendered page routes (with auth)
		if (method === 'GET' && (pathname === '/' || pathname === '/list')) {
			const authResp = await checkAuth(request, env);
			if (authResp) return authResp;
			return await handleList(request, env);
		}

		if (method === 'GET' && pathname === '/upload-form') {
			const authResp = await checkAuth(request, env);
			if (authResp) return authResp;
			return await handleUploadForm(request, env);
		}

		// File upload (with auth)
		if (method === 'POST' && pathname === '/upload') {
			const authResp = await checkAuth(request, env);
			if (authResp) return authResp;
			return await handleUpload(request, env);
		}

		// File deletion (with auth)
		if (method === 'POST' && pathname.startsWith('/delete/')) {
			const authResp = await checkAuth(request, env);
			if (authResp) return authResp;
			const key = pathname.slice('/delete/'.length);
			return await handleDelete(request, env, key);
		}

		// File operations (no auth required)
		if (method === 'GET' && pathname.startsWith('/file/')) {
			const key = pathname.slice('/file/'.length);
			return await handleView(request, key, env);
		}

		if (method === 'GET' && pathname.startsWith('/download/')) {
			const key = pathname.slice('/download/'.length);
			return await handleDownload(key, env);
		}

		if (method === 'GET' && pathname.startsWith('/full/')) {
			const key = pathname.slice('/full/'.length);
			return await handleFull(request, key, env);
		}

		if (method === 'GET' && pathname.startsWith('/preview/')) {
			const key = pathname.slice('/preview/'.length);
			return await handlePreview(key, env);
		}

		// PRIORITY 2: Static assets (CSS, JS, etc.) - but NOT HTML prerenderedPages
		// Don't serve HTML files as static assets - they should be processed by handlers above
		if (pathname.endsWith('.html')) {
			return new Response('Not Found', { status: 404 });
		}

		// In dev mode, proxy to Vite dev server for assets
		if (env.VITE_DEV_URL) {
			// For CSS files, add ?direct query param to get raw CSS instead of JS module
			let targetPath = pathname;
			if (pathname.endsWith('.css')) {
				targetPath = pathname + '?direct';
			}
			const viteUrl = new URL(targetPath, env.VITE_DEV_URL);
			return fetch(viteUrl.toString());
		}

		// In production, serve from ASSETS binding
		return env.ASSETS.fetch(request);
	},
};

// IMPORTANT: Export your Durable Object so Cloudflare can locate it.
export { AccessCounter } from './AccessCounter';
