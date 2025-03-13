// src/helpers/template.ts

// Import templates directly
import listTemplate from '../templates/list.html';
import uploadFormTemplate from '../templates/upload-form.html';

// Template mapping
const templates: Record<string, string> = {
	list: listTemplate,
	'upload-form': uploadFormTemplate,
};

/**
 * Processes a template and replaces placeholders with values
 * @param templateName The name of the template (without the .html extension)
 * @param replacements An object with placeholder keys and their replacement values
 * @returns The processed template as a string
 */
export function renderTemplate(templateName: string, replacements: Record<string, string>): string {
	// Get the template
	const template = templates[templateName];
	if (!template) {
		throw new Error(`Template "${templateName}" not found`);
	}

	// Replace all placeholders with their values
	let result = template;
	for (const [key, value] of Object.entries(replacements)) {
		result = result.replace(new RegExp(`{{${key}}}`, 'g'), value);
	}

	return result;
}
