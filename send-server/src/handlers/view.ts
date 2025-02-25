// src/handlers/view.ts

import { Env, UploadRecord } from '../types';
import { FILE_MAX_ACCESS_COUNT } from './constants';

export async function handleView(key: string, env: Env): Promise<Response> {
	// Retrieve file metadata from D1.
	const record: UploadRecord | null = await env.DB.prepare('SELECT * FROM uploads WHERE id = ?').bind(key).first();

	if (!record) {
		return new Response('File record not found', { status: 404 });
	}

	// Query the Durable Object for the current access count.
	const counterId = env.FILE_COUNTER.idFromName(key);
	const counterStub = env.FILE_COUNTER.get(counterId);
	const countResp = await counterStub.fetch(`https://dummy/?cmd=get`);
	const { count } = await countResp.json();

	// Render inline media based on MIME type.
	let mediaContent = '';
	if (record.filetype.startsWith('image/')) {
		mediaContent = `<img src="/download/${key}" alt="${record.filename}" style="max-width:100%; display:block; margin: 0 auto;" />`;
	} else if (record.filetype.startsWith('video/')) {
		mediaContent = `<video controls autoplay loop playsinline style="max-width:100%; display:block; margin: 0 auto;">
                      <source src="/download/${key}" type="${record.filetype}">
                      Your browser does not support the video tag.
                    </video>`;
	} else if (record.filetype.startsWith('audio/')) {
		mediaContent = `<audio controls style="width:100%; display:block; margin: 0 auto;">
                      <source src="/download/${key}" type="${record.filetype}">
                      Your browser does not support the audio element.
                    </audio>`;
	} else {
		mediaContent = `<p>This file type cannot be previewed inline.</p>`;
	}

	// Build the info box with file metadata and the access count.
	const infoBox = `
    <div class="info-box">
      <h2>${record.filename}</h2>
      <p><strong>Type:</strong> ${record.filetype}</p>
      <p><strong>Uploaded At:</strong> ${record.uploaded_at}</p>
      <p><strong>Access Count:</strong> ${count} / ${FILE_MAX_ACCESS_COUNT}</p>
      <p><a href="/download/${key}">Download File</a></p>
    </div>
  `;

	// Generate the complete HTML with inline CSS.
	const html = `
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8">
    <title>${record.filename}</title>
    <style>
      /* CSS reset */
      * { margin: 0; padding: 0; box-sizing: border-box; }
      body { font-family: Arial, sans-serif; background-color: #f9f9f9; margin: 0; padding: 0; }
      .media-container { text-align: center; }
      .media-container img,
      .media-container video,
      .media-container audio { display: block; margin: 0 auto; max-width: 100%; }
      .info-box {
        background: #fff;
        padding: 20px;
        border: 1px solid #ddd;
        border-radius: 4px;
        max-width: 800px;
        margin: 20px auto;
        text-align: left;
      }
      a { color: #007bff; text-decoration: none; }
      a:hover { text-decoration: underline; }
      .back-link { text-align: center; margin: 20px; }
    </style>
  </head>
  <body>
    <div class="media-container">
      ${mediaContent}
    </div>
    ${infoBox}
    <p class="back-link"><a href="/list">Back to list</a></p>
  </body>
</html>
  `;

	return new Response(html, {
		headers: { 'Content-Type': 'text/html;charset=UTF-8' },
	});
}
