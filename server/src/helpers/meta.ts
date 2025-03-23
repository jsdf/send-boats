// src/helpers/meta.ts
import { UploadRecord } from '../types';

export function generateMetaTags(record: UploadRecord, key: string, requestUrl: string): string {
	// Extract the origin (protocol + hostname + port) from the request URL
	const origin = new URL(requestUrl).origin;

	const fileUrl = `${origin}/file/${key}`;
	let ogImageTag = '';

	// Determine media type for title
	let mediaType = 'file';
	let articlePrefix = 'A';
	if (record.filetype.startsWith('image/')) {
		mediaType = 'image';
		ogImageTag = `<meta property="og:image" content="${origin}/download/${key}" />`;
	} else if (record.filetype.startsWith('video/') && record.has_preview) {
		mediaType = 'video';
		ogImageTag = `<meta property="og:image" content="${origin}/preview/${key}" />`;
	} else if (record.filetype.startsWith('audio/')) {
		mediaType = 'audio';
		articlePrefix = 'An'; // Use "An" for audio
		ogImageTag = `<meta property="og:image" content="${origin}/default-preview.png" />`;
	} else {
		ogImageTag = `<meta property="og:image" content="${origin}/default-preview.png" />`;
	}

	// Add image dimensions to constrain preview size
	// Using 1200x630 (1.91:1 aspect ratio) which is optimal for most social platforms
	// This ensures consistent display across platforms, especially for vertical videos
	const imageWithDimensions = `${ogImageTag}
    <meta property="og:image:width" content="1200" />
    <meta property="og:image:height" content="630" />
    <meta property="og:image:alt" content="${record.filename}" />`;

	return `
    <!-- Open Graph meta tags -->
    <meta property="og:title" content="${articlePrefix} ${mediaType} on ${new URL(origin).hostname}" />
    <meta property="og:description" content="Check out this file uploaded on ${origin}" />
    <meta property="og:type" content="website" />
    <meta property="og:url" content="${fileUrl}" />
    ${imageWithDimensions}
    
    <!-- Twitter Card meta tags -->
    <meta name="twitter:card" content="summary_large_image" />
    <meta name="twitter:title" content="${articlePrefix} ${mediaType} on ${new URL(origin).hostname}" />
    <meta name="twitter:description" content="Check out this file uploaded on ${origin}" />
    ${imageWithDimensions}
  `;
}
