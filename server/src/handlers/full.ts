// src/handlers/full.ts
import { Env, UploadRecord } from '../types';
import { generateMetaTags } from '../helpers/meta';

export async function handleFull(request: Request, key: string, env: Env): Promise<Response> {
	const record: UploadRecord | null = await env.DB.prepare('SELECT * FROM uploads WHERE id = ?').bind(key).first();
	if (!record) {
		return new Response('File record not found', { status: 404 });
	}

	// Use the request URL for generating meta tags
	const metaTags = generateMetaTags(record, key, request.url);
	let html = '';
	let headers = { 'Content-Type': 'text/html;charset=UTF-8' };

	if (record.filetype.startsWith('video/')) {
		// Inline script: try webkitEnterFullscreen if available.
		const script = `
      <script>
        document.addEventListener("DOMContentLoaded", function() {
          var video = document.querySelector("video");
          if (video) {
            video.addEventListener("play", function() {
              // For iOS Safari, use webkitEnterFullscreen if available.
              if (video.webkitEnterFullscreen) {
                video.webkitEnterFullscreen();
              } else if (video.requestFullscreen) {
                video.requestFullscreen().catch(function(err) {
                  console.log("Failed to enable full screen mode:", err);
                });
              }
            });
          }
        });
      </script>
    `;
		html = `
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8">
    <title>A file on send.boats: ${record.filename}</title>
    ${metaTags}
    ${script}
    <style>
      * { margin: 0; padding: 0; box-sizing: border-box; }
      html, body { width: 100%; height: 100%; overflow: hidden; background: black; }
      video { width: 100vw; height: 100vh; object-fit: contain; display: block; }
    </style>
  </head>
  <body>
    <video controls loop autoplay>
      <source src="/download/${key}" type="${record.filetype}">
      Your browser does not support the video tag.
    </video>
  </body>
</html>`;
	} else if (record.filetype.startsWith('image/')) {
		html = `
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8">
    <title>A file on send.boats: ${record.filename}</title>
    ${metaTags}
    <style>
      * { margin: 0; padding: 0; box-sizing: border-box; }
      html, body { width: 100%; height: 100%; overflow: hidden; background: black; display: flex; justify-content: center; align-items: center; }
      img { max-width: 100vw; max-height: 100vh; object-fit: contain; display: block; }
    </style>
  </head>
  <body>
    <img src="/download/${key}" alt="${record.filename}">
  </body>
</html>`;
	} else if (record.filetype.startsWith('audio/')) {
		html = `
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8">
    <title>A file on send.boats: ${record.filename}</title>
    ${metaTags}
    <style>
      * { margin: 0; padding: 0; box-sizing: border-box; }
      html, body { width: 100%; height: 100%; overflow: hidden; background: #f0f0f0; display: flex; justify-content: center; align-items: center; }
      audio { width: 80%; max-width: 600px; }
    </style>
  </head>
  <body>
    <audio controls autoplay>
      <source src="/download/${key}" type="${record.filetype}">
      Your browser does not support the audio element.
    </audio>
  </body>
</html>`;
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
