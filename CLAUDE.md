# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a file sharing service with two main components:
- **iOS native app** (`sendboats-ios/`) - SwiftUI-based client for uploading and sharing files
- **Cloudflare Workers server** (`server/`) - Backend API handling uploads, storage, and file management

## Development Commands

### iOS App (sendboats-ios/)

**Build and Test:**
```bash
cd sendboats-ios
# Build main app
xcodebuild -scheme sendboats -configuration Debug
# Build share extension
xcodebuild -scheme ShareExtension -configuration Debug
# Run tests
xcodebuild test -scheme sendboats
# Build for release
xcodebuild -scheme sendboats -configuration Release
```

**Open in Xcode:**
```bash
open sendboats-ios/sendboats.xcodeproj
```

### Server (server/)

**Development:**
```bash
cd server
npm install
npm run dev        # Local development
npm run deploy     # Deploy to Cloudflare Workers
wrangler deploy    # Alternative deploy command
```

**Database and Storage Setup:**
```bash
wrangler r2 bucket create your-bucket-name
wrangler d1 create your-database-name
wrangler d1 execute your-database-name --file=schema.sql
wrangler kv:namespace create "RATE_LIMIT"
```

## Architecture

### iOS App Structure

**Multi-Target Architecture:**
- **sendboats** - Main application target
- **ShareExtension** - iOS Share Extension for system-wide file sharing
- **SharedCode** - Common code shared between both targets

**Key Patterns:**
- **MVVM with Combine**: `UploadViewModel` as central state manager using `@ObservableObject`
- **SwiftUI + UIKit**: Modern SwiftUI views with UIKit integration for system features
- **App Groups**: Data sharing between main app and extension via `group.jsdf.sendboats`
- **URL Scheme Communication**: Share extension opens main app via `sendboats://` URL scheme

**State Management Flow:**
```
fileSelection → previewAndUpload → uploading → success
```

**Core Services:**
- `APIClient.swift` - Network layer handling server communication
- `UploadService.swift` - File upload logic with progress tracking
- `ConfigurationManager.swift` - Persistent settings via App Groups
- `VideoThumbnailGenerator.swift` - Media processing utilities

### Server Architecture

**Cloudflare Workers Stack:**
- **Workers** - Main application logic
- **R2** - File storage
- **D1** - SQLite database for metadata
- **KV** - Rate limiting storage
- **Durable Objects** - Access counting

## Testing Framework

**iOS Testing:**
- **Unit Tests**: Swift Testing framework (`sendboatsTests/`)
- **UI Tests**: XCTest framework (`sendboatsUITests/`)
- **Build Monitoring**: Automated error tracking with `xclogparser` generating JSON reports

**Test Execution:**
```bash
# Run all tests
xcodebuild test -scheme sendboats
# Run specific test target
xcodebuild test -scheme sendboats -only-testing:sendboatsTests
```

## Share Extension Integration

The iOS app includes a comprehensive Share Extension that:
- Accepts all file types via `TRUEPREDICATE` activation rule
- Processes files through the same upload pipeline as main app
- Uses App Groups for configuration sharing
- Returns to main app via URL scheme after successful upload

**Setup Requirements:**
- App Groups entitlement: `group.jsdf.sendboats`
- URL scheme handler: `sendboats://`
- Share Extension Info.plist configuration for file type support

## Configuration

**iOS App:**
- Server settings persisted via `ConfigurationManager` using App Groups
- Configuration shared between main app and share extension
- Default server endpoint configurable in app settings

**Server:**
- `wrangler.toml` contains Cloudflare Workers configuration
- Environment variables for authentication (`AUTH_USERNAME`, `AUTH_PASSWORD`)
- Dynamic hostname detection (no hardcoded URLs)

## File Upload Flow

1. **File Selection**: Document picker or photo library (main app) / system share (extension)
2. **Preview Generation**: Video thumbnail creation for media files
3. **Upload**: Multipart upload to Cloudflare Workers endpoint
4. **Response Processing**: Extract view URL and full URL from server response
5. **Success Display**: Show URLs with copy/share functionality

## Key Features

- Native iOS file upload with progress tracking
- Video preview generation and thumbnail extraction
- System-wide sharing via iOS Share Extension
- URL copying and native iOS share sheet integration
- Persistent server configuration
- Cross-target code sharing between main app and extension