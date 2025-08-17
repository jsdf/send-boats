# send.boats - File Sharing Service

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Working Effectively

### Bootstrap the Server Component
- `cd server`
- `npm install` -- takes 20 seconds. NEVER CANCEL. Set timeout to 60+ seconds.
- Create `.dev.vars` file with authentication credentials:
  ```
  BASIC_AUTH_USERNAME=test
  BASIC_AUTH_PASSWORD=test123
  ```
- Initialize database schema: `npx wrangler d1 execute send-boats --local --file=schema.sql` -- takes 1-2 seconds.
- `npm run dev` -- starts in 10 seconds. NEVER CANCEL. Set timeout to 30+ seconds.
- Server runs on http://127.0.0.1:8787

### Test Server Functionality
- Always test endpoints with authentication: `curl -u "test:test123" http://127.0.0.1:8787/`
- Upload form: `curl -u "test:test123" http://127.0.0.1:8787/upload-form`
- File list: `curl -u "test:test123" http://127.0.0.1:8787/`
- Without auth, endpoints return 401 Unauthorized

### iOS Component
- **CANNOT BUILD ON LINUX**: iOS app requires macOS and Xcode. This environment is Linux.
- Located in `sendboats-ios/` directory
- Xcode project: `sendboats-ios/sendboats.xcodeproj`
- Includes ShareExtension for file sharing from other iOS apps
- Has UI tests in `sendboatsUITests/`

## Validation

### Server Validation Steps
ALWAYS run through these scenarios after making server changes:
1. Start development server: `cd server && npm run dev`
2. Test unauthenticated access returns 401: `curl -w "Status: %{http_code}\n" http://127.0.0.1:8787/`
3. Test authenticated file list: `curl -u "test:test123" -w "Status: %{http_code}\n" http://127.0.0.1:8787/`
4. Test upload form loads: `curl -u "test:test123" -w "Status: %{http_code}\n" http://127.0.0.1:8787/upload-form`
5. Verify HTML responses contain expected content (forms, file lists)

### iOS Validation Steps
- Cannot validate iOS builds in this environment (Linux)
- iOS testing requires macOS with Xcode installed
- ShareExtension setup instructions in `sendboats-ios/ShareExtension/README.md`

## Critical Timing and Cancellation Warnings

- **npm install**: 20 seconds. NEVER CANCEL. Set timeout to 60+ seconds.
- **npm run dev**: 10 seconds startup. NEVER CANCEL. Set timeout to 30+ seconds.
- **Database operations**: 1-2 seconds. Set timeout to 30+ seconds.
- **npm test**: Currently broken due to vitest configuration issues with template imports.

## Known Issues and Limitations

### Server Issues
- **Tests are broken**: npm test fails due to vitest configuration expecting wrangler.json instead of wrangler.toml, and template import issues.
- **No working linters**: No ESLint or other linters installed. Prettier config exists but prettier package not installed.
- **Database must be initialized**: First-time setup requires running schema.sql against local D1 database.

### Environment Limitations
- **iOS builds impossible**: This is a Linux environment. iOS development requires macOS.
- **No GitHub Actions**: No CI/CD workflows configured.

## Required Dependencies and URLs

### Server Prerequisites
- Node.js (current: v20.19.4)
- npm (current: v10.8.2)
- Wrangler CLI (current: 4.14.1, available via npx)

### Cloudflare Resources Required for Deployment
- R2 bucket for file storage
- D1 database for metadata
- KV namespace for rate limiting
- Durable Objects for access counting
- Account ID and authentication credentials

## Project Structure

### Server (`server/`)
- `src/index.ts` - Main worker entry point
- `src/handlers/` - Request handlers (upload, download, list, etc.)
- `src/helpers/` - Auth, rate limiting, templates
- `src/templates/` - HTML templates for web interface
- `schema.sql` - Database schema
- `wrangler.toml` - Cloudflare Workers configuration
- `package.json` - Dependencies and scripts

### iOS (`sendboats-ios/`)
- `sendboats.xcodeproj` - Main Xcode project
- `sendboats/` - Main iOS app source
- `ShareExtension/` - Share extension for receiving files
- `SharedCode/` - Code shared between targets
- `sendboatsTests/` - Unit tests
- `sendboatsUITests/` - UI tests

## Common Commands Reference

### Development
```bash
# Server development
cd server
npm install
npm run dev  # Start local server

# Database setup (first time only)
npx wrangler d1 execute send-boats --local --file=schema.sql

# Deployment
npm run deploy  # Runs deploy-with-version.sh script
```

### Testing
```bash
# Server testing (currently broken)
cd server
npm test  # FAILS: vitest configuration issues

# Manual server validation
curl -u "test:test123" http://127.0.0.1:8787/
curl -u "test:test123" http://127.0.0.1:8787/upload-form
```

## Frequently Accessed Files

### Server Configuration
- `server/wrangler.toml` - Cloudflare Workers config with bindings
- `server/package.json` - Node.js dependencies and scripts
- `server/.dev.vars` - Local development environment variables (create manually)

### Key Source Files
- `server/src/index.ts` - Main request router
- `server/src/helpers/auth.ts` - Authentication logic
- `server/README.md` - Detailed setup and deployment instructions
- `sendboats-ios/ShareExtension/README.md` - iOS ShareExtension setup

Always validate your changes by running the development server and testing the endpoints manually before committing changes.