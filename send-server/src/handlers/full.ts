// src/handlers/full.ts
import { Env, UploadRecord } from '../types';
import { generateMetaTags } from '../helpers/meta';

export async function handleFull(key: string, env: Env): Promise<Response> {
	const record: UploadRecord | null = await env.DB.prepare('SELECT * FROM uploads WHERE id = ?').bind(key).first();
	if (!record) {
		return new Response('File record not found', { status: 404 });
	}
	if (!record.filetype.startsWith('video/')) {
		return new Response('Full mode is only available for video files', { status: 400 });
	}

	const domain = 'https://send.boats';
	const metaTags = generateMetaTags(record, key, domain);

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

	const html = `
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8">
    <title>A file on send.boats: ${record.filename}</title>
    ${metaTags}
    ${script}
    <style>
      /* CSS reset */
      * { margin: 0; padding: 0; box-sizing: border-box; }
      html, body {
        width: 100%;
        height: 100%;
        overflow: hidden;
        background: black;
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
    <video controls loop>
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
