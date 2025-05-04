# send.boats

a simple file sharing service with a server component and an ios client.

## components

*   **[server/](server/)**: contains the cloudflare worker code that powers the backend api. see the [server readme](server/README.md) for setup and deployment instructions.
*   **[sendboats-ios/](sendboats-ios/)**: contains the xcode project for the ios client application. this app allows users to upload files to the send.boats server, and includes sharesheet support.

## overview

this project provides a self-hostable service for quickly sharing files. the server handles uploads, storage (via r2), and provides various endpoints for listing, viewing, downloading, and deleting files. the ios app provides a native interface for interacting with the server, including uploading files directly from the device or via the share sheet.

## license

this project is licensed under the mit license. see the [license](license) file for details.
