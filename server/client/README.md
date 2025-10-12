# Client Build System

This directory contains the client-side code for the send.boats server application.

## Structure

- `prerender/` - HTML prerendered pages that are pre-rendered with Vite (formerly `prerendered pages/`)
- `src/styles/` - CSS source files (Tailwind CSS)
- `src/scripts/` - Client-side TypeScript/JavaScript
- `dist/` - Build output (served by Cloudflare Worker via ASSETS binding)

## Commands

- `npm run dev` - Start Vite dev server on port 5173 (hot reloading)
- `npm run build` - Build for production
- `npm run build:watch` - Build in watch mode

## How It Works

### Development Mode
- Vite dev server runs on http://localhost:5173
- Worker fetches prerendered pages from Vite dev server (set via `VITE_DEV_URL` env var)
- Hot reloading enabled for prerendered pages, styles, and scripts
- `absoluteUrlPlugin` rewrites asset URLs to point to Vite dev server

### Production Mode
- Prerendered Pages are pre-rendered and bundled with Vite
- Assets are optimized and hashed
- Worker serves everything from `dist/` via ASSETS binding
- No runtime prerendered page compilation

## Build Output

The `dist/` directory contains:
- `prerender/` - Compiled HTML prerendered pages with injected asset URLs
- `assets/` - Bundled and hashed CSS/JS files

The server's `wrangler.toml` points to `./client/dist` as the assets directory.
