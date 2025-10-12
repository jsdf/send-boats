// src/handlers/view.ts
import { Env, UploadRecord } from '../types';
import { generateMetaTags } from '../helpers/meta';
import { renderTemplate } from '../helpers/template';
import { buildUrl, getOriginUrl } from '../helpers/url';
import { escapeHtml } from '../helpers/html';

export async function handleView(request: Request, key: string, env: Env): Promise<Response> {
	const record: UploadRecord | null = await env.DB.prepare('SELECT * FROM uploads WHERE id = ?').bind(key).first();
	if (!record) {
		return new Response('File record not found', { status: 404 });
	}

	// Query the Durable Object for the current access count.
	const counterId = env.FILE_COUNTER.idFromName(key);
	const counterStub = env.FILE_COUNTER.get(counterId);
	const countResp = await counterStub.fetch('https://dummy/?cmd=get');
	const data = (await countResp.json()) as { count: number };
	const count = data.count;

	let mediaContent = '';
	if (record.filetype.startsWith('image/')) {
		mediaContent = `<img src="/download/${key}" alt="${record.filename}" class="max-w-full mx-auto block" />`;
	} else if (record.filetype.startsWith('video/')) {
		mediaContent = `<video controls autoplay loop playsinline class="max-w-full mx-auto block">
                      <source src="/download/${key}" type="${record.filetype}">
                      Your browser does not support the video tag.
                    </video>`;
	} else if (record.filetype.startsWith('audio/')) {
		mediaContent = `<audio controls class="max-w-full mx-auto block">
                      <source src="/download/${key}" type="${record.filetype}">
                      Your browser does not support the audio element.
                    </audio>`;
	} else {
		mediaContent = `<p class="opacity-60">This file type cannot be previewed inline.</p>`;
	}

	// Use the request URL for generating meta tags
	const metaTags = generateMetaTags(record, key, request.url);

	// Build full URLs using correct origin
	const downloadUrl = buildUrl(`/download/${key}`, request, env);
	const originUrl = getOriginUrl(request, env);

	const html = await renderTemplate(
		'view',
		{
			FILENAME: escapeHtml(record.filename),
			META_TAGS: metaTags,
			MEDIA_CONTENT: mediaContent,
			FILETYPE: escapeHtml(record.filetype),
			UPLOADED_AT: record.uploaded_at,
			ACCESS_COUNT: count.toString(),
			DOWNLOAD_URL: downloadUrl,
			ORIGIN_URL: originUrl,
		},
		env
	);

	return new Response(html, {
		headers: { 'Content-Type': 'text/html;charset=UTF-8' },
	});
}
