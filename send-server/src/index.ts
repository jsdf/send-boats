// src/index.ts
import { handleUpload } from './handlers/upload';
import { handleUploadForm } from './handlers/uploadForm';
import { handleView } from './handlers/view';
import { handleDownload } from './handlers/download';
import { handleList } from './handlers/list';
import { handleFull } from './handlers/full';
import { handleDelete } from './handlers/delete';
import { Env } from './types';
import { checkBasicAuth } from './helpers/auth';
import { checkRateLimit } from './helpers/rateLimit';

export default {
	async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
		// Rate limit all requests.
		const rateLimitResp = await checkRateLimit(request, env);
		if (rateLimitResp) return rateLimitResp;

		const url = new URL(request.url);
		const pathname = url.pathname;
		const method = request.method;

		// Protected routes: /upload, /upload-form, /list (or /), and /delete/*
		if (
			(method === 'POST' && pathname === '/upload') ||
			(method === 'GET' && pathname === '/upload-form') ||
			(method === 'GET' && (pathname === '/' || pathname === '/list')) ||
			(method === 'POST' && pathname.startsWith('/delete/'))
		) {
			const authResp = await checkBasicAuth(request, env);
			if (authResp) return authResp;
		}

		if (method === 'POST' && pathname === '/upload') {
			return await handleUpload(request, env);
		} else if (method === 'GET' && pathname === '/upload-form') {
			return await handleUploadForm(request, env);
		} else if (method === 'GET' && (pathname === '/' || pathname === '/list')) {
			return await handleList(request, env);
		} else if (method === 'POST' && pathname.startsWith('/delete/')) {
			const key = pathname.slice('/delete/'.length);
			return await handleDelete(request, env, key);
		} else if (method === 'GET' && pathname.startsWith('/file/')) {
			const key = pathname.slice('/file/'.length);
			return await handleView(key, env);
		} else if (method === 'GET' && pathname.startsWith('/download/')) {
			const key = pathname.slice('/download/'.length);
			return await handleDownload(key, env);
		} else if (method === 'GET' && pathname.startsWith('/full/')) {
			const key = pathname.slice('/full/'.length);
			return await handleFull(key, env);
		} else {
			return new Response('Not Found', { status: 404 });
		}
	},
};

// IMPORTANT: Export your Durable Object so Cloudflare can locate it.
export { AccessCounter } from './AccessCounter';
