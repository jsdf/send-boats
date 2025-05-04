//
//  PhotoPicker.swift
//  sendboats
//
//  Created on 3/23/25.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import AVFoundation

struct PhotoPicker: UIViewControllerRepresentable {
    // Completion handler that returns the selected file URL and name
    var onFilePicked: ((URL, String) -> Void)
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .any(of: [.images, .videos])
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // Nothing to update
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let result = results.first else { return }
            
            // Variable to store the file name
            var fileName = ""
            
            // Get file name from the item provider
            if let assetIdentifier = result.assetIdentifier,
               let assetResults = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil).firstObject {
                
                // Get file name from asset
                let resources = PHAssetResource.assetResources(for: assetResults)
                if let resource = resources.first {
                    fileName = resource.originalFilename
                }
            }
            
            // Load the item provider's data
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) && fileName.isEmpty {
                // If we couldn't get the filename but it's an image, use a default name
                fileName = "image_\(Date().timeIntervalSince1970).jpg"
            } else if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) && fileName.isEmpty {
                // If we couldn't get the filename but it's a video, use a default name with mp4 extension
                fileName = "video_\(Date().timeIntervalSince1970).mp4"
            }
            
            // Get the file URL by copying to a temporary location
            result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.item.identifier) { [weak self] url, error in
                guard let url = url, error == nil else {
                    print("Error loading file representation: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                // For video files, ensure we're using the correct extension based on the container format
                var finalFileName = fileName
                if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                    // Check if the file is actually an MP4
                    let asset = AVURLAsset(url: url)
                    let fileFormat = self?.determineVideoFormat(asset)
                    
                    // If the file is an MP4 but has a .mov extension, fix it
                    if fileFormat == "mp4" && finalFileName.lowercased().hasSuffix(".mov") {
                        finalFileName = finalFileName.replacingOccurrences(of: ".mov", with: ".mp4", options: [.caseInsensitive, .anchored])
                        print("Corrected video file extension from .mov to .mp4")
                    } else if fileFormat == "mp4" && !finalFileName.lowercased().hasSuffix(".mp4") {
                        // If it doesn't have any extension, add .mp4
                        finalFileName = finalFileName + ".mp4"
                        print("Added .mp4 extension to video file")
                    }
                }
                
                // Create a temporary file URL
                let tempDirectoryURL = FileManager.default.temporaryDirectory
                let tempFileURL = tempDirectoryURL.appendingPathComponent(finalFileName.isEmpty ? "file_\(Date().timeIntervalSince1970)" : finalFileName)
                let fileManager = FileManager.default
                
                // Ensure the destination doesn't exist already
                if fileManager.fileExists(atPath: tempFileURL.path) {
                    do {
                        try fileManager.removeItem(at: tempFileURL)
                        print("DEBUG: PhotoPicker - Removed existing item at temporary path: \(tempFileURL.path)")
                    } catch {
                        print("Error removing existing temporary file: \(error.localizedDescription)")
                        // Decide if we should return or continue
                        return // Let's return an error for now
                    }
                }

                // Determine the correct source URL (file or file within directory)
                var sourceURLToCopy: URL?
                var isDirectory: ObjCBool = false
                if fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) {
                    if isDirectory.boolValue {
                        // Source URL is a directory, find the file inside
                        print("DEBUG: PhotoPicker - Source URL is a directory: \(url.path). Searching for file inside.")
                        do {
                            let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])
                            // Assuming the first item is the file we want
                            if let firstFile = contents.first {
                                sourceURLToCopy = firstFile
                                print("DEBUG: PhotoPicker - Found file inside directory: \(sourceURLToCopy!.path)")
                            } else {
                                print("Error: Source directory is empty.")
                                return
                            }
                        } catch {
                            print("Error reading contents of source directory: \(error.localizedDescription)")
                            return
                        }
                    } else {
                        // Source URL is already a file
                        sourceURLToCopy = url
                        print("DEBUG: PhotoPicker - Source URL is a file: \(url.path)")
                    }
                } else {
                     print("Error: Source URL does not exist: \(url.path)")
                     return
                }

                // Proceed with copying if we found a valid source file
                guard let finalSourceURL = sourceURLToCopy else {
                    print("Error: Could not determine the final source URL to copy.")
                    return
                }

                do {
                    // Copy the *actual file* to our temporary location
                    try fileManager.copyItem(at: finalSourceURL, to: tempFileURL)
                    print("DEBUG: PhotoPicker - Successfully copied file to: \(tempFileURL.path)")
                    
                    // Call the completion handler on the main thread
                    DispatchQueue.main.async {
                        self?.parent.onFilePicked(tempFileURL, finalFileName)
                    }
                } catch {
                    print("Error copying file: \(error.localizedDescription)")
                }
            }
        }
        
        /// Determines the actual container format of a video file
        /// - Parameter asset: The AVURLAsset to check
        /// - Returns: String indicating the format ("mp4", "mov", or "unknown")
        private func determineVideoFormat(_ asset: AVURLAsset) -> String {
            // Check file extension first
            let fileExtension = asset.url.pathExtension.lowercased()
            
            // For iOS camera roll videos, they're typically in MP4 container format
            if fileExtension == "mov" {
                // Most modern iOS videos are H.264 in MP4 containers even if named .mov
                return "mp4"
            } else if fileExtension == "mp4" {
                return "mp4"
            }
            
            // Default to the file extension or unknown
            return fileExtension.isEmpty ? "unknown" : fileExtension
        }
    }
}
