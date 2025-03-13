// src/handlers/list.ts
import { Env, UploadRecord } from '../types';
import { renderTemplate } from '../helpers/template';

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

		// Get version information from environment variables
		const gitSha = env.GIT_SHA || 'development';
		const isDirty = env.GIT_DIRTY === 'true';
		const versionInfo = `${gitSha}${isDirty ? '-dirty' : ''}`;

		// Render the template with our data
		const html = renderTemplate('list', {
			FILE_LIST: listHtml,
			VERSION_INFO: versionInfo,
		});

		return new Response(html, {
			headers: { 'Content-Type': 'text/html;charset=UTF-8' },
		});
	} catch (err: any) {
		return new Response('Error listing files: ' + err.message, { status: 500 });
	}
}
