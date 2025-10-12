// src/handlers/list.ts
import { Env, UploadRecord } from '../types';
import { renderTemplate } from '../helpers/template';

export async function handleList(request: Request, env: Env): Promise<Response> {
	try {
		const result = await env.DB.prepare('SELECT * FROM uploads ORDER BY uploaded_at DESC').all<UploadRecord>();
		const files = result.results || [];

		let listHtml = '';
		if (files.length === 0) {
			listHtml = `<p class="text-gray-600">No files uploaded yet.</p>`;
		} else {
			for (const file of files) {
				// Determine if we should show a preview thumbnail and link
				const hasPreview = file.filetype.startsWith('video/') && file.has_preview;
				const previewLink = hasPreview
					? `<a href="/preview/${file.id}" target="_blank" class="text-blue-600 hover:underline">Preview</a> | `
					: '';

				// Add thumbnail for videos with previews
				const thumbnailHtml = hasPreview
					? `<div class="flex-shrink-0 w-full sm:w-32">
							<img src="/preview/${file.id}" alt="Preview" class="w-full h-auto sm:h-18 object-cover rounded-lg border border-gray-200" />
						</div>`
					: '';

				// Escape HTML in filename
				const escapeHtml = (text: string) =>
					text.replace(
						/[&<>"']/g,
						(m) =>
							({
								'&': '&amp;',
								'<': '&lt;',
								'>': '&gt;',
								'"': '&quot;',
								"'": '&#39;',
							}[m] || m)
					);

				listHtml += `
					<div class="bg-white rounded-lg shadow-sm p-4 ${hasPreview ? 'sm:flex sm:gap-4' : ''}">
						${thumbnailHtml}
						<div class="flex-grow ${hasPreview ? 'mt-3 sm:mt-0' : ''}">
							<div class="font-semibold text-gray-900 mb-2 break-words">${escapeHtml(file.filename)}</div>
							<div class="text-sm text-gray-600 space-y-1">
								<div class="flex flex-wrap gap-2 items-center">
									${previewLink}
									<a href="/file/${file.id}" class="text-blue-600 hover:underline">View</a> |
									<a href="/full/${file.id}" class="text-blue-600 hover:underline">Full</a>
								</div>
								<div class="text-xs text-gray-500">Uploaded: ${file.uploaded_at}</div>
								<form method="POST" action="/delete/${
									file.id
								}" class="inline-block" onsubmit="return confirm('Are you sure you want to delete this file?');">
									<button type="submit" class="text-xs px-3 py-1 bg-red-600 text-white rounded hover:bg-red-700 transition-colors">Delete</button>
								</form>
							</div>
						</div>
					</div>
				`;
			}
		}

		// Get version information from environment variables
		const gitSha = env.GIT_SHA || 'development';
		const isDirty = env.GIT_DIRTY === 'true';
		const versionInfo = `${gitSha}${isDirty ? '-dirty' : ''}`;

		// Render the template with our data
		const html = await renderTemplate(
			'list',
			{
				FILE_LIST: listHtml,
				VERSION_INFO: versionInfo,
			},
			env
		);

		return new Response(html, {
			headers: {
				'Content-Type': 'text/html;charset=UTF-8',
				'Cache-Control': 'no-cache, no-store, must-revalidate',
				Pragma: 'no-cache',
				Expires: '0',
			},
		});
	} catch (err: any) {
		return new Response('Error listing files: ' + err.message, { status: 500 });
	}
}
