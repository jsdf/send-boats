import { dirname, resolve, basename, extname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { defineConfig, Plugin } from 'vite';
import { glob } from 'glob';
const __dirname = dirname(fileURLToPath(import.meta.url));

// Plugin to make asset URLs absolute in dev mode
function absoluteUrlPlugin(): Plugin {
	const viteDevUrl = 'http://localhost:5173';

	return {
		name: 'absolute-url-plugin',
		transformIndexHtml: {
			order: 'post',
			handler(html) {
				// Replace relative URLs with absolute URLs pointing to Vite dev server
				// Only rewrite asset URLs (CSS, JS, images), not navigation links
				return (
					html
						// Rewrite stylesheet links
						.replace(/<link([^>]*)\shref="\/([^"]+\.css[^"]*)"/g, `<link$1 href="${viteDevUrl}/$2"`)
						// Rewrite script sources
						.replace(/<script([^>]*)\ssrc="\/([^"]+)"/g, `<script$1 src="${viteDevUrl}/$2"`)
						// Rewrite image sources
						.replace(/<img([^>]*)\ssrc="\/([^"]+)"/g, `<img$1 src="${viteDevUrl}/$2"`)
				);
			},
		},
	};
}

export default defineConfig(({ mode }) => ({
	server: {
		// Listen on all interfaces so it's accessible from network
		host: '0.0.0.0',
		port: 5173,
		// Allow CORS from Wrangler dev server
		cors: true,
	},
	plugins: mode === 'development' ? [absoluteUrlPlugin()] : [],
	build: {
		rollupOptions: {
			// e.g.
			// input: {
			// 	'prerender/list': resolve(__dirname, 'prerender/list.html'),
			// 	'prerender/upload': resolve(__dirname, 'prerender/upload.html'),
			//   ...
			// },
			input: glob.sync('prerender/*.html', { cwd: __dirname }).reduce((inputs, file) => {
				const name = basename(file, extname(file));
				inputs[name] = resolve(__dirname, file);
				return inputs;
			}, {} as Record<string, string>),
		},
		outDir: 'dist',
	},
}));
