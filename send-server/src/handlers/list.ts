// src/handlers/list.ts
import { Env, UploadRecord } from '../types';

export async function handleList(request: Request, env: Env): Promise<Response> {
	try {
		const result = await env.DB.prepare('SELECT * FROM uploads ORDER BY uploaded_at DESC').all<UploadRecord>();
		const files = result.results || [];
		let listHtml = `<ul class="file-list">`;
		for (const file of files) {
			// Determine if we should show a preview thumbnail and link
			const hasPreview = file.filetype.startsWith('video/') && file.has_preview;
			const previewLink = hasPreview ? `| <a href="/preview/${file.id}" target="_blank">Preview</a> ` : '';

			// Add thumbnail for videos with previews
			const thumbnailHtml = hasPreview ? `<div class="thumbnail"><img src="/preview/${file.id}" alt="Preview" /></div>` : '';

			listHtml += `<li class="file-item ${hasPreview ? 'has-preview' : ''}">
        ${thumbnailHtml}
        <div class="file-info">
          <div class="file-name">${file.filename}</div>
          <div class="file-actions">
            (<a href="/file/${file.id}">View</a> | <a href="/full/${file.id}">Full</a> ${previewLink})
            - uploaded at ${file.uploaded_at}
            <form method="POST" action="/delete/${
							file.id
						}" style="display:inline;" onsubmit="return confirm('Are you sure you want to delete this file?');">
              <button type="submit">Delete</button>
            </form>
          </div>
        </div>
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
      
      /* File list styles */
      .file-list { list-style: none; }
      .file-item { 
        margin-bottom: 15px; 
        padding: 10px;
        border: 1px solid #eee;
        border-radius: 4px;
        background-color: white;
      }
      .file-item.has-preview {
        display: flex;
        align-items: center;
      }
      .thumbnail {
        margin-right: 15px;
        flex-shrink: 0;
      }
      .thumbnail img {
        width: 120px;
        height: 68px;
        object-fit: cover;
        border-radius: 3px;
        border: 1px solid #ddd;
      }
      .file-info {
        flex-grow: 1;
      }
      .file-name {
        font-weight: bold;
        margin-bottom: 5px;
      }
      .file-actions {
        font-size: 0.9em;
        color: #666;
      }
      
      /* General styles */
      a { color: #007bff; text-decoration: none; }
      a:hover { text-decoration: underline; }
      form { display: inline; }
      button { 
        margin-left: 10px;
        padding: 2px 8px;
        background-color: #f44336;
        color: white;
        border: none;
        border-radius: 3px;
        cursor: pointer;
      }
      button:hover {
        background-color: #d32f2f;
      }
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
