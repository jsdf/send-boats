//
//  UploadService.swift
//  sendboats
//
//  Created on 4/30/25.
//

import Foundation
import AVFoundation // For AVURLAsset if needed for type checking, keep minimal dependencies

// Define potential errors for the service
enum UploadServiceError: Error, LocalizedError {
    case apiClientNotConfigured
    case fileNotFound(String)
    case uploadFailed(Error)
    case previewGenerationFailed(Error)
    case invalidConfiguration(String)
    case unknownError(Error)
    
    var errorDescription: String? {
        switch self {
        case .apiClientNotConfigured:
            return "API client is not configured. Please check server settings."
        case .fileNotFound(let path):
            return "The selected file could not be found at path: \(path)."
        case .uploadFailed(let underlyingError):
            return "Upload failed: \(underlyingError.localizedDescription)"
        case .previewGenerationFailed(let underlyingError):
            return "Failed to generate video preview: \(underlyingError.localizedDescription)"
        case .invalidConfiguration(let message):
            return "Invalid configuration: \(message)"
        case .unknownError(let underlyingError):
            return "An unknown error occurred: \(underlyingError.localizedDescription)"
        }
    }
}

// Define the result structure
public struct UploadResult {
    let key: String
    let fullViewURL: URL
    let viewURL: URL
}

// Define progress types
enum UploadProgressPhase {
    case generatingPreview
    case uploading(Double) // Progress value 0.0 to 1.0
}

class UploadService {
    
    private var apiClient: APIClient?
    private let configurationManager = ConfigurationManager.shared
    
    init() {
        print("DEBUG: UploadService - init()")
        setupAPIClient()
    }
    
    // Function to re-setup API client if configuration changes
    func setupAPIClient() {
        print("DEBUG: UploadService - setupAPIClient()")
        let config = configurationManager.loadConfiguration()
        guard let url = URL(string: config.serverURL), !config.serverURL.isEmpty else {
            print("DEBUG: UploadService - Invalid or empty server URL in configuration. Setting apiClient to nil.")
            self.apiClient = nil
            return
        }
        self.apiClient = APIClient(baseURL: url, username: config.username, password: config.password)
        print("DEBUG: UploadService - APIClient configured with URL: \(config.serverURL). APIClient is nil: \(self.apiClient == nil)")
    }
    
    // Public method to check if apiClient is configured
    func isAPIClientConfigured() -> Bool {
        return apiClient != nil
    }
    
    func uploadFile(
        fileURL: URL,
        progressHandler: @escaping (UploadProgressPhase) -> Void
    ) async -> Result<UploadResult, UploadServiceError> {
        
        print("DEBUG: UploadService - Starting upload for file: \(fileURL.lastPathComponent). APIClient is nil: \(apiClient == nil)")
        
        // Ensure API client is configured
        guard let apiClient = apiClient else {
            print("DEBUG: UploadService - Error: API client not configured")
            return .failure(.apiClientNotConfigured)
        }
        
        // Check if the file exists
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("DEBUG: UploadService - Error: File does not exist at path: \(fileURL.path)")
            return .failure(.fileNotFound(fileURL.path))
        }
        
        // Determine if it's a video and generate preview
        var previewData: Data? = nil
        let isVideo = isVideoFile(url: fileURL)
        
        if isVideo {
            print("DEBUG: UploadService - File is a video. Generating preview.")
            progressHandler(.generatingPreview)
            do {
                // Assuming VideoThumbnailGenerator is available and moved to SharedCode
                // We only need one representative thumbnail for upload.
                let thumbnails = try await VideoThumbnailGenerator.generateThumbnails(from: fileURL, count: 1)
                if let firstThumbnail = thumbnails.first {
                    previewData = VideoThumbnailGenerator.imageToJPEGData(firstThumbnail.image)
                    print("DEBUG: UploadService - Preview generated successfully. Data size: \(previewData?.count ?? 0) bytes.")
                } else {
                     print("DEBUG: UploadService - Warning: Thumbnail generation returned no images.")
                }
            } catch {
                print("DEBUG: UploadService - Error generating video preview: \(error.localizedDescription)")
                // Decide if preview failure should halt the upload or just proceed without it.
                // For now, let's return an error.
                 return .failure(.previewGenerationFailed(error))
                // Alternatively, log the error and continue without preview:
                // print("Proceeding without preview due to error: \(error.localizedDescription)")
            }
        } else {
             print("DEBUG: UploadService - File is not a video. Skipping preview generation.")
        }
        
        // Perform the upload
        do {
            // Start accessing security-scoped resource if necessary
            let didStartAccessing = fileURL.startAccessingSecurityScopedResource()
            if didStartAccessing {
                print("DEBUG: UploadService - Started accessing security-scoped resource.")
            } else {
                print("DEBUG: UploadService - Did not start accessing security-scoped resource (not needed or failed).")
            }

            defer {
                if didStartAccessing {
                    fileURL.stopAccessingSecurityScopedResource()
                    print("DEBUG: UploadService - Stopped accessing security-scoped resource.")
                }
            }

            print("DEBUG: UploadService - Calling APIClient.uploadFile")
            let response = try await apiClient.uploadFile(
                fileURL: fileURL,
                previewImageData: previewData,
                progressHandler: { progressValue in
                    progressHandler(.uploading(progressValue))
                    print("DEBUG: UploadService - Upload progress: \(progressValue)")
                }
            )
            
            print("DEBUG: UploadService - Upload successful. Response key: \(response.key)")
            
            // Construct result URLs
            let fullURL = apiClient.getFullViewURL(for: response.key)
            let viewURL = apiClient.getViewURL(for: response.key)
            
            print("DEBUG: UploadService - Full URL: \(fullURL.absoluteString)")
            print("DEBUG: UploadService - View URL: \(viewURL.absoluteString)")
            
            let result = UploadResult(key: response.key, fullViewURL: fullURL, viewURL: viewURL)
            return .success(result)
            
        } catch let error as APIError {
            print("DEBUG: UploadService - API Error during upload: \(error.localizedDescription)")
            return .failure(.uploadFailed(error))
        } catch {
            print("DEBUG: UploadService - Unknown error during upload: \(error.localizedDescription)")
            return .failure(.unknownError(error))
        }
    }
    
    /// Checks if the file at the given URL is a video based on its extension.
    /// Note: This is a basic check. More robust checking might involve UTIs if needed.
    private func isVideoFile(url: URL) -> Bool {
        let fileExtension = url.pathExtension.lowercased()
        let videoExtensions = ["mp4", "mov", "m4v", "avi", "mkv"] // Add more as needed
        return videoExtensions.contains(fileExtension)
    }
    
    // Helper to copy URL to clipboard (can be called from UI layer)
    static func copyURLToClipboard(_ url: URL?) {
        guard let url = url else { return }
        #if canImport(UIKit)
        UIPasteboard.general.string = url.absoluteString
        print("DEBUG: UploadService - Copied URL to clipboard: \(url.absoluteString)")
        #else
        // Handle clipboard for other platforms if necessary (e.g., macOS)
        print("DEBUG: UploadService - Clipboard copy not implemented for this platform.")
        #endif
    }
}

// Make sure VideoThumbnailGenerator is accessible here (move it to SharedCode)
// Make sure APIClient is accessible here (ensure target membership)
// Make sure ConfigurationManager is accessible here (ensure target membership)

#if canImport(UIKit)
import UIKit // Import UIKit conditionally for UIPasteboard
#endif
