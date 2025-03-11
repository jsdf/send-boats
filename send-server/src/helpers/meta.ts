// src/helpers/meta.ts
import { UploadRecord } from '../types';

export function generateMetaTags(record: UploadRecord, key: string, requestUrl: string): string {
	// Extract the origin (protocol + hostname + port) from the request URL
	const origin = new URL(requestUrl).origin;

	const fileUrl = `${origin}/file/${key}`;
	let ogImageTag = '';

	// For images, use the file directly.
	// For videos with previews, use the preview endpoint.
	if (record.filetype.startsWith('image/')) {
		ogImageTag = `<meta property="og:image" content="${origin}/download/${key}" />`;
	} else if (record.filetype.startsWith('video/') && record.has_preview) {
		ogImageTag = `<meta property="og:image" content="${origin}/preview/${key}" />`;
	} else {
		// Optionally, you can provide a default preview image.
		ogImageTag = `<meta property="og:image" content="${origin}/default-preview.png" />`;
	}

	return `
    <!-- Open Graph meta tags -->
    <meta property="og:title" content="${record.filename}" />
    <meta property="og:description" content="Check out this file uploaded on ${origin}" />
    <meta property="og:type" content="website" />
    <meta property="og:url" content="${fileUrl}" />
    ${ogImageTag}
    
    <!-- Twitter Card meta tags -->
    <meta name="twitter:card" content="summary_large_image" />
    <meta name="twitter:title" content="${record.filename}" />
    <meta name="twitter:description" content="Check out this file uploaded on ${origin}" />
    ${ogImageTag}
  `;
}
