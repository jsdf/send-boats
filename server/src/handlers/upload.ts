import { Env } from '../types';

export async function handleUpload(request: Request, env: Env): Promise<Response> {
	try {
		const formData = await request.formData();
		const file = formData.get('file') as File | null;
		const previewImage = formData.get('preview') as File | null;

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

		let hasPreview = false;

		// If we have a preview image and the file is a video, save the preview
		if (previewImage && filetype.startsWith('video/')) {
			console.log(`Saving preview for video ${key}, preview size: ${previewImage.size} bytes`);
			const previewBuffer = await previewImage.arrayBuffer();
			await env.R2_BUCKET.put(`${key}-preview`, previewBuffer, {
				httpMetadata: { contentType: 'image/jpeg' },
			});
			hasPreview = true;
			console.log(`Preview saved, has_preview set to ${hasPreview}`);
		} else {
			console.log(`No preview for ${key}, previewImage: ${!!previewImage}, filetype: ${filetype}`);
		}

		// Save metadata to D1 with has_preview flag
		await env.DB.prepare('INSERT INTO uploads (id, filename, filetype, uploaded_at, has_preview) VALUES (?, ?, ?, CURRENT_TIMESTAMP, ?)')
			.bind(key, filename, filetype, hasPreview ? 1 : 0)
			.run();

		const responseData = { key, filename, filetype, hasPreview };
		return new Response(JSON.stringify(responseData), {
			headers: { 'Content-Type': 'application/json' },
		});
	} catch (err: any) {
		return new Response('Error processing upload: ' + err.message, { status: 500 });
	}
}
