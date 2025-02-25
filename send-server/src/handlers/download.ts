// src/handlers/download.ts

import { Env, UploadRecord } from '../types';
import { FILE_MAX_ACCESS_COUNT } from './constants';

export async function handleDownload(key: string, env: Env): Promise<Response> {
	// First, look up the file record from D1 (for metadata like filename and filetype)
	const record: UploadRecord | null = await env.DB.prepare('SELECT * FROM uploads WHERE id = ?').bind(key).first();

	if (!record) {
		return new Response('File record not found', { status: 404 });
	}

	// Use the Durable Object to check the current access count.
	const id = env.FILE_COUNTER.idFromName(key);
	const counterStub = env.FILE_COUNTER.get(id);

	// Get the current count.
	const getResp = await counterStub.fetch(`https://dummy/?cmd=get`);
	const { count } = await getResp.json();

	// If the file has been accessed FILE_MAX_ACCESS_COUNT times or more, return an error.
	if (count >= FILE_MAX_ACCESS_COUNT) {
		return new Response('File access limit reached', { status: 403 });
	}

	// Increment the counter.
	await counterStub.fetch(`https://dummy/?cmd=increment`);

	// Retrieve the file from R2.
	const object = await env.R2_BUCKET.get(key);
	if (!object) {
		return new Response('File not found in storage', { status: 404 });
	}

	return new Response(object.body, {
		headers: {
			'Content-Type': record.filetype,
			'Content-Disposition': `attachment; filename="${record.filename}"`,
		},
	});
}
