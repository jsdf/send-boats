import { checkBasicAuth } from '../helpers/auth';
import { Env } from '../types';
import { renderPage } from '../helpers/prerenderedPage';

export async function handleUploadForm(request: Request, env: Env): Promise<Response> {
	// Render the prerenderedPage (no replacements needed for this prerenderedPage)
	const html = await renderPage('upload-form', {}, env);

	return new Response(html, { headers: { 'Content-Type': 'text/html;charset=UTF-8' } });
}
