# Share Extension Setup Instructions

This document provides instructions for setting up the Share Extension in Xcode to enable sharing files from other apps to the sendboats app.

## 1. Add the Share Extension Target

1. Open the sendboats Xcode project
2. Click on the project in the Project Navigator
3. Click the "+" button at the bottom of the Targets list
4. Select "Share Extension" from the iOS Application Extension section
5. Name it "ShareExtension"
6. Make sure "Embed in Application" is set to "sendboats"
7. Click "Finish"

## 2. Configure the Share Extension

1. Replace the default `ShareViewController.swift` with the custom implementation provided
2. Add the `MainInterface.storyboard` file to the ShareExtension target
3. Add the `Info.plist` file to the ShareExtension target

## 3. Set Up App Groups

1. Select the sendboats project in the Project Navigator
2. Select the sendboats target
3. Go to the "Signing & Capabilities" tab
4. Click the "+" button to add a capability
5. Select "App Groups"
6. Click the "+" button under App Groups
7. Enter a group identifier: "group.jsdf.sendboats"
   - This matches the bundle identifier of the main app (jsdf.sendboats)
8. Repeat steps 1-7 for the ShareExtension target

## 4. Add Entitlements Files

1. Add the `sendboats.entitlements` file to the main app target
2. Add the `ShareExtension.entitlements` file to the ShareExtension target
3. Make sure both files reference the same App Group identifier

## 5. Configure URL Scheme

1. Ensure the main app's Info.plist has the URL scheme "sendboats" configured
2. This allows the Share Extension to open the main app after processing a shared file

## 6. Build and Run

1. Build and run the app on a device or simulator
2. Test the Share Extension by sharing a file from another app (e.g., Photos)
3. The file should be automatically processed and loaded into the sendboats app for upload

## Troubleshooting

- If the Share Extension doesn't appear in the share sheet, try restarting the device
- Make sure the App Group identifiers match exactly in both targets
- Check that the URL scheme is correctly configured
- Verify that the entitlements files are properly added to their respective targets
