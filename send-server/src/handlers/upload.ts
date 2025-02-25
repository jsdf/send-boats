import { Env } from '../types';

export async function handleUpload(request: Request, env: Env): Promise<Response> {
	try {
		const formData = await request.formData();
		const file = formData.get('file') as File | null;
		if (!file) {
			return new Response('File not found in form data', { status: 400 });
		}
		const key = crypto.randomUUID();
		const filename = file.name || 'unknown';
		const filetype = file.type || 'application/octet-stream';
		const arrayBuffer = await file.arrayBuffer();

		// Save file to R2.
		await env.R2_BUCKET.put(key, arrayBuffer, {
			httpMetadata: { contentType: filetype },
			customMetadata: { filename },
		});

		// Save metadata to D1.
		await env.DB.prepare('INSERT INTO uploads (id, filename, filetype, uploaded_at) VALUES (?, ?, ?, CURRENT_TIMESTAMP)')
			.bind(key, filename, filetype)
			.run();

		const responseData = { key, filename, filetype };
		return new Response(JSON.stringify(responseData), {
			headers: { 'Content-Type': 'application/json' },
		});
	} catch (err: any) {
		return new Response('Error processing upload: ' + err.message, { status: 500 });
	}
}
