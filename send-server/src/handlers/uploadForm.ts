import { checkBasicAuth } from '../helpers/auth';
import { Env } from '../types';
import { renderTemplate } from '../helpers/template';

export async function handleUploadForm(request: Request, env: Env): Promise<Response> {
	// Render the template (no replacements needed for this template)
	const html = renderTemplate('upload-form', {});

	return new Response(html, { headers: { 'Content-Type': 'text/html;charset=UTF-8' } });
}
