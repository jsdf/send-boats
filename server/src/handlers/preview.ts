// src/handlers/preview.ts
import { Env, UploadRecord } from '../types';

export async function handlePreview(key: string, env: Env): Promise<Response> {
	console.log(`Preview requested for key: ${key}`);

	// First, look up the file record
	const record: UploadRecord | null = await env.DB.prepare('SELECT * FROM uploads WHERE id = ?').bind(key).first();

	if (!record) {
		console.log(`No record found for key: ${key}`);
		return new Response('File record not found', { status: 404 });
	}

	console.log(`Record found: ${JSON.stringify(record)}`);

	// Check if this file has a preview
	if (!record.has_preview) {
		console.log(`No preview flag for file: ${key}, has_preview: ${record.has_preview}`);
		// Return a 404 if no preview is available
		return new Response('No preview available for this file', { status: 404 });
	}

	// Retrieve the preview from R2
	const previewKey = `${key}-preview`;
	console.log(`Fetching preview from R2 with key: ${previewKey}`);
	const object = await env.R2_BUCKET.get(previewKey);

	if (!object) {
		console.log(`Preview object not found in R2: ${previewKey}`);
		return new Response('Preview not found in storage', { status: 404 });
	}

	console.log(`Preview found, size: ${object.size} bytes, type: ${object.httpMetadata?.contentType}`);
	return new Response(object.body, {
		headers: {
			'Content-Type': 'image/jpeg',
			'Cache-Control': 'public, max-age=86400',
		},
	});
}
