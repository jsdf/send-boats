// src/helpers/prerenderedPage.ts
import { Env } from '../types';

function getPrerenderedPageFilename(prerenderedPageName: string): string {
	return `prerender/${prerenderedPageName}.html`;
}

/**
 * Fetches a prerenderedPage - from Vite dev server in dev mode, or from ASSETS in production
 */
async function fetchPrerenderedPage(prerenderedPageName: string, env: Env): Promise<string> {
	const filename = getPrerenderedPageFilename(prerenderedPageName);
	if (!filename) {
		throw new Error(`PrerenderedPage "${prerenderedPageName}" not found`);
	}

	// In dev mode, fetch from Vite dev server for hot reloading
	if (env.VITE_DEV_URL) {
		const response = await fetch(`${env.VITE_DEV_URL}/${filename}`);
		if (!response.ok) {
			throw new Error(`Failed to fetch prerenderedPage from Vite dev server: ${response.statusText}`);
		}
		return await response.text();
	}

	// In production, fetch from ASSETS binding (built static files)
	const assetRequest = new Request(`https://placeholder.local/${filename}`);
	const response = await env.ASSETS.fetch(assetRequest);
	if (!response.ok) {
		throw new Error(`Failed to fetch prerenderedPage from assets: ${response.statusText}`);
	}
	return await response.text();
}

/**
 * Processes a prerenderedPage and replaces placeholders with values
 * @param prerenderedPageName The name of the prerenderedPage (without the .html extension)
 * @param replacements An object with placeholder keys and their replacement values
 * @param env The environment bindings
 * @returns The processed prerenderedPage as a string
 */
export async function renderPage(prerenderedPageName: string, replacements: Record<string, string>, env: Env): Promise<string> {
	// Fetch prerenderedPage from appropriate source
	const prerenderedPage = await fetchPrerenderedPage(prerenderedPageName, env);

	// Replace all placeholders with their values
	let result = prerenderedPage;
	for (const [key, value] of Object.entries(replacements)) {
		const regex = new RegExp(`{{${key}}}`, 'g');
		result = result.replace(regex, value);
	}

	return result;
}
