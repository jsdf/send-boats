// src/handlers/full.ts

import { Env, UploadRecord } from '../types';

export async function handleFull(key: string, env: Env): Promise<Response> {
	// Retrieve file metadata from D1.
	const record: UploadRecord | null = await env.DB.prepare('SELECT * FROM uploads WHERE id = ?').bind(key).first();

	if (!record) {
		return new Response('File record not found', { status: 404 });
	}

	// Ensure the file is a video. Full mode is defined for video only.
	if (!record.filetype.startsWith('video/')) {
		return new Response('Full mode is only available for video files', { status: 400 });
	}

	// Generate the full-screen HTML page.
	const html = `
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8">
    <title>${record.filename} - Full Mode</title>
    <style>
      /* Reset CSS */
      * { margin: 0; padding: 0; box-sizing: border-box; }
      html, body {
        width: 100%;
        height: 100%;
        overflow: hidden;
        background: black; /* Ensure the background is black */
      }
      video {
        width: 100vw;
        height: 100vh;
        object-fit: contain;
        display: block;
      }
    </style>
  </head>
  <body>
    <video controls autoplay loop playsinline>
      <source src="/download/${key}" type="${record.filetype}">
      Your browser does not support the video tag.
    </video>
  </body>
</html>
  `;

	return new Response(html, {
		headers: { 'Content-Type': 'text/html;charset=UTF-8' },
	});
}
