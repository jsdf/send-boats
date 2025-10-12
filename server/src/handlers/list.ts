// src/handlers/list.ts
import { Env, UploadRecord } from '../types';
import { renderTemplate } from '../helpers/template';
import { escapeHtml } from '../helpers/html';

function buildPaginationHtml(page: number, hasNextPage: boolean): string {
	if (page === 1 && !hasNextPage) {
		return '';
	}

	let html = '<div class="flex justify-center items-center gap-4 my-6">';
	
	// Previous button
	if (page > 1) {
		html += `<a href="/?page=${page - 1}" class="btn btn-sm">← Previous</a>`;
	} else {
		html += `<button class="btn btn-sm btn-disabled">← Previous</button>`;
	}
	
	// Current page indicator
	html += `<span class="text-sm opacity-70">Page ${page}</span>`;
	
	// Next button
	if (hasNextPage) {
		html += `<a href="/?page=${page + 1}" class="btn btn-sm">Next →</a>`;
	} else {
		html += `<button class="btn btn-sm btn-disabled">Next →</button>`;
	}
	
	html += '</div>';
	return html;
}

export async function handleList(request: Request, env: Env): Promise<Response> {
	try {
		// Parse pagination parameters
		const url = new URL(request.url);
		const page = Math.max(1, parseInt(url.searchParams.get('page') || '1', 10));
		const pageSize = 50;
		const offset = (page - 1) * pageSize;

		// Fetch one extra record to check if there's a next page
		const result = await env.DB.prepare(
			'SELECT * FROM uploads ORDER BY uploaded_at DESC LIMIT ? OFFSET ?'
		)
			.bind(pageSize + 1, offset)
			.all<UploadRecord>();
		const allResults = result.results || [];
		const hasNextPage = allResults.length > pageSize;
		const files = hasNextPage ? allResults.slice(0, pageSize) : allResults;

		let listHtml = '';
		if (files.length === 0) {
			listHtml = `<p class="opacity-60">No files uploaded yet.</p>`;
		} else {
			for (const file of files) {
				// Determine if we should show a preview thumbnail and link
				const hasPreview = file.filetype.startsWith('video/') && file.has_preview;
				const previewLink = hasPreview
					? `<a href="/preview/${file.id}" target="_blank" class="link link-primary">Preview</a> | `
					: '';

				// Add thumbnail for videos with previews
				const thumbnailHtml = hasPreview
					? `<div class="flex-shrink-0 w-full sm:w-32">
							<img src="/preview/${file.id}" alt="Preview" class="w-full h-auto sm:h-18 object-cover rounded-lg border border-base-300" />
						</div>`
					: '';

				listHtml += `
					<div class="card bg-base-100 shadow-sm p-4 ${hasPreview ? 'sm:flex sm:gap-4' : ''}">
						${thumbnailHtml}
						<div class="flex-grow ${hasPreview ? 'mt-3 sm:mt-0' : ''}">
							<div class="font-semibold mb-2 break-words">${escapeHtml(file.filename)}</div>
							<div class="text-sm opacity-70 space-y-1">
								<div class="flex flex-wrap gap-2 items-center">
									${previewLink}
									<a href="/file/${file.id}" class="link link-primary">View</a> |
									<a href="/full/${file.id}" class="link link-primary">Full</a>
								</div>
								<div class="text-xs opacity-60">Uploaded: ${file.uploaded_at}</div>
								<form method="POST" action="/delete/${
									file.id
								}" class="inline-block" onsubmit="return confirm('Are you sure you want to delete this file?');">
									<button type="submit" class="btn btn-error btn-xs">Delete</button>
								</form>
							</div>
						</div>
					</div>
				`;
			}
		}

		// Build pagination controls
		const paginationHtml = buildPaginationHtml(page, hasNextPage);

		// Get version information from environment variables
		const gitSha = env.GIT_SHA || 'development';
		const isDirty = env.GIT_DIRTY === 'true';
		const versionInfo = `${gitSha}${isDirty ? '-dirty' : ''}`;

		// Render the template with our data
		const html = await renderTemplate(
			'list',
			{
				FILE_LIST: listHtml,
				PAGINATION: paginationHtml,
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
