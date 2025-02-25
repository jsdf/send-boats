// src/handlers/list.ts
import { Env, UploadRecord } from '../types';

export async function handleList(request: Request, env: Env): Promise<Response> {
	try {
		const result = await env.DB.prepare('SELECT * FROM uploads ORDER BY uploaded_at DESC').all<UploadRecord>();
		const files = result.results || [];
		let listHtml = `<ul>`;
		for (const file of files) {
			listHtml += `<li>
        ${file.filename} 
        (<a href="/file/${file.id}">View</a> | <a href="/full/${file.id}">Full</a>)
        - uploaded at ${file.uploaded_at}
        <form method="POST" action="/delete/${file.id}" style="display:inline;" onsubmit="return confirm('Are you sure you want to delete this file?');">
          <button type="submit">Delete</button>
        </form>
      </li>`;
		}
		listHtml += `</ul>`;

		const html = `
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8">
    <title>Uploaded Files</title>
    <style>
      /* CSS reset */
      * { margin: 0; padding: 0; box-sizing: border-box; }
      body { font-family: Arial, sans-serif; background-color: #f9f9f9; padding: 20px; }
      .list-container { max-width: 800px; margin: 0 auto; }
      ul { list-style: none; }
      li { margin-bottom: 10px; }
      a { color: #007bff; text-decoration: none; }
      a:hover { text-decoration: underline; }
      form { display: inline; }
      button { margin-left: 10px; }
    </style>
  </head>
  <body>
    <div class="list-container">
      <h1>Uploaded Files</h1>
      ${listHtml}
      <hr/>
      <p><a href="/upload-form">Upload a new file</a></p>
    </div>
  </body>
</html>
    `;
		return new Response(html, {
			headers: { 'Content-Type': 'text/html;charset=UTF-8' },
		});
	} catch (err: any) {
		return new Response('Error listing files: ' + err.message, { status: 500 });
	}
}
