// src/handlers/full.ts
import { Env, UploadRecord } from '../types';
import { generateMetaTags } from '../helpers/meta';
import { renderTemplate } from '../helpers/template';

export async function handleFull(request: Request, key: string, env: Env): Promise<Response> {
	const record: UploadRecord | null = await env.DB.prepare('SELECT * FROM uploads WHERE id = ?').bind(key).first();
	if (!record) {
		return new Response('File record not found', { status: 404 });
	}

	// Use the request URL for generating meta tags
	const metaTags = generateMetaTags(record, key, request.url);
	const headers = { 'Content-Type': 'text/html;charset=UTF-8' };

	// Escape HTML in filename for safety
	const escapeHtml = (text: string) =>
		text.replace(
			/[&<>"']/g,
			(m) =>
				({
					'&': '&amp;',
					'<': '&lt;',
					'>': '&gt;',
					'"': '&quot;',
					"'": '&#39;',
				}[m] || m)
		);

	let html: string;

	if (record.filetype.startsWith('video/')) {
		html = await renderTemplate(
			'full-video',
			{
				FILENAME: escapeHtml(record.filename),
				META_TAGS: metaTags,
				FILE_ID: key,
				FILETYPE: record.filetype,
			},
			env
		);
	} else if (record.filetype.startsWith('image/')) {
		html = await renderTemplate(
			'full-image',
			{
				FILENAME: escapeHtml(record.filename),
				META_TAGS: metaTags,
				FILE_ID: key,
			},
			env
		);
	} else if (record.filetype.startsWith('audio/')) {
		html = await renderTemplate(
			'full-audio',
			{
				FILENAME: escapeHtml(record.filename),
				META_TAGS: metaTags,
				FILE_ID: key,
				FILETYPE: record.filetype,
			},
			env
		);
	} else {
		// For other file types, redirect to download
		return new Response(null, {
			status: 302,
			headers: {
				Location: `/download/${key}`,
			},
		});
	}

	return new Response(html, { headers });
}
