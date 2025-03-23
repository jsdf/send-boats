this codebase is a filesharing service. the api is defined in the server/ dir. in the sendboats-ios/ dir we have a blank ios project. in this dir we want to implement a client ios app for uploading files to the api

## API
The server provides these key endpoints:

- /upload (POST): For uploading files with optional preview images for videos
- /list (GET): Lists all uploaded files
- /file/{id} (GET): View a file
- /download/{id} (GET): Download a file
- /preview/{id} (GET): Get a preview image for a video file
- /delete/{id} (POST): Delete a file

The API uses basic authentication for protected routes and has rate limiting.

## iOS App Implementation Plan
### Phase: Core Upload Functionality
- API Client Service
    - Create a basic API client with authentication
    - Implement the upload endpoint only

- Simple UI
    - File selection button
    - Upload button
    - Status indicator
    - Display area for the generated link

- File Upload Flow
    - Select a file using document picker
    - Upload the file to the server
    - Display the full view link (/full/{id}) after successful upload

#### Phase: Easy Copy-to-Clipboard
- Add a copy button next to the generated link
- Implement clipboard functionality
- Add visual feedback when copied

#### Phase: Video Preview Generation
- Detect when uploading video files
- Generate preview images from videos
- Include preview images in the upload request
- Show preview generation progress

### Future Phases (in priority order)

#### Phase: Sharesheet Integration
- Implement a Share Extension
- Handle incoming files from other apps
- Process and upload the shared file
- Return to the main app with the link

## other things to know
- the info.plist of the ios project is generated. if changes are required to it, give a list of steps to update the xcode project config.