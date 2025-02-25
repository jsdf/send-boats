// src/helpers/meta.ts
import { UploadRecord } from '../types';

export function generateMetaTags(record: UploadRecord, key: string, domain: string): string {
	const fileUrl = `${domain}/file/${key}`;
	const downloadUrl = `${domain}/download/${key}`;
	let ogMediaTag = '';
	if (record.filetype.startsWith('image/')) {
		ogMediaTag = `<meta property="og:image" content="${downloadUrl}" />`;
	} else if (record.filetype.startsWith('video/')) {
		ogMediaTag = `<meta property="og:video" content="${downloadUrl}" />`;
	}

	return `
    <!-- Open Graph meta tags -->
    <meta property="og:title" content="${record.filename}" />
    <meta property="og:description" content="Check out this file on send.boats" />
    <meta property="og:type" content="website" />
    <meta property="og:url" content="${fileUrl}" />
    ${ogMediaTag}
    
    <!-- Twitter Card meta tags -->
    <meta name="twitter:card" content="summary_large_image" />
    <meta name="twitter:title" content="${record.filename}" />
    <meta name="twitter:description" content="Check out this file on send.boats" />
    ${ogMediaTag}
  `;
}
