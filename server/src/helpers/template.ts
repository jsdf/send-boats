// src/helpers/template.ts
import { Env } from '../types';

// Template filename mapping
const templateFiles: Record<string, string> = {
	list: 'templates/list.html',
	'upload-form': 'templates/upload.html',
	view: 'templates/view.html',
	'full-video': 'templates/full-video.html',
	'full-image': 'templates/full-image.html',
	'full-audio': 'templates/full-audio.html',
	login: 'templates/login.html',
};

/**
 * Fetches a template - from Vite dev server in dev mode, or from ASSETS in production
 */
async function fetchTemplate(templateName: string, env: Env): Promise<string> {
	const filename = templateFiles[templateName];
	if (!filename) {
		throw new Error(`Template "${templateName}" not found`);
	}

	// In dev mode, fetch from Vite dev server for hot reloading
	if (env.VITE_DEV_URL) {
		const response = await fetch(`${env.VITE_DEV_URL}/${filename}`);
		if (!response.ok) {
			throw new Error(`Failed to fetch template from Vite dev server: ${response.statusText}`);
		}
		return await response.text();
	}

	// In production, fetch from ASSETS binding (built static files)
	const assetRequest = new Request(`https://placeholder.local/${filename}`);
	const response = await env.ASSETS.fetch(assetRequest);
	if (!response.ok) {
		throw new Error(`Failed to fetch template from assets: ${response.statusText}`);
	}
	return await response.text();
}

/**
 * Processes a template and replaces placeholders with values
 * @param templateName The name of the template (without the .html extension)
 * @param replacements An object with placeholder keys and their replacement values
 * @param env The environment bindings
 * @returns The processed template as a string
 */
export async function renderTemplate(templateName: string, replacements: Record<string, string>, env: Env): Promise<string> {
	// Fetch template from appropriate source
	const template = await fetchTemplate(templateName, env);

	// Replace all placeholders with their values
	let result = template;
	for (const [key, value] of Object.entries(replacements)) {
		const regex = new RegExp(`{{${key}}}`, 'g');
		result = result.replace(regex, value);
	}

	return result;
}
