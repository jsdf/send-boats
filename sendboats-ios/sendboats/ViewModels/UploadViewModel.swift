//
//  UploadViewModel.swift
//  sendboats
//
//  Created on 3/23/25.
//

import Foundation
import SwiftUI
import AVFoundation

enum UploadState: Equatable {
    case idle
    case generatingPreviews
    case uploading
    case success(URL)
    case error(String)
    
    static func == (lhs: UploadState, rhs: UploadState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.generatingPreviews, .generatingPreviews):
            return true
        case (.uploading, .uploading):
            return true
        case (.success(let lhsURL), .success(let rhsURL)):
            return lhsURL == rhsURL
        case (.error(let lhsMessage), .error(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

class UploadViewModel: ObservableObject {
    @Published var serverURL: String
    @Published var username: String
    @Published var password: String
    @Published var selectedFileURL: URL?
    @Published var selectedFileName: String = ""
    @Published var uploadState: UploadState = .idle
    @Published var fullViewURL: URL?
    @Published var viewURL: URL?
    
    // Video preview properties
    @Published var isVideo: Bool = false
    @Published var videoThumbnails: [VideoThumbnail] = []
    @Published var selectedThumbnailIndex: Int = 0
    
    private var apiClient: APIClient?
    
    init() {
        // Load configuration from UserDefaults
        let configuration = ConfigurationManager.shared.loadConfiguration()
        self.serverURL = configuration.serverURL
        self.username = configuration.username
        self.password = configuration.password
        
        // Initialize API client with loaded values
        setupAPIClient()
    }
    
    func saveConfiguration() {
        let configuration = APIConfiguration(
            serverURL: serverURL,
            username: username,
            password: password
        )
        ConfigurationManager.shared.saveConfiguration(configuration)
        setupAPIClient()
    }
    
    func setupAPIClient() {
        guard let url = URL(string: serverURL) else {
            uploadState = .error("Invalid server URL")
            return
        }
        
        apiClient = APIClient(baseURL: url, username: username, password: password)
    }
    
    func uploadFile() async {
        guard let apiClient = apiClient else {
            uploadState = .error("API client not configured")
            return
        }
        
        guard let fileURL = selectedFileURL else {
            uploadState = .error("No file selected")
            return
        }
        
        // Update state to uploading
        await MainActor.run {
            uploadState = .uploading
        }
        
        do {
            // Start accessing the security-scoped resource
            let didStartAccessing = fileURL.startAccessingSecurityScopedResource()
            
            // Get preview image data if this is a video
            let previewData = isVideo ? getSelectedThumbnailData() : nil
            
            // Upload the file with preview if available
            let response = try await apiClient.uploadFile(fileURL: fileURL, previewImageData: previewData)
            
            // Stop accessing the security-scoped resource if needed
            if didStartAccessing {
                fileURL.stopAccessingSecurityScopedResource()
            }
            
            // Get the URLs
            let fullURL = apiClient.getFullViewURL(for: response.key)
            let viewURL = apiClient.getViewURL(for: response.key)
            
            // Update state to success
            await MainActor.run {
                self.fullViewURL = fullURL
                self.viewURL = viewURL
                uploadState = .success(fullURL)
            }
        } catch let error as APIError {
            await MainActor.run {
                uploadState = .error(error.localizedDescription)
            }
        } catch {
            await MainActor.run {
                uploadState = .error("An unknown error occurred")
            }
        }
    }
    
    /// Resets all state variables to their initial values
    func reset() {
        // Reset file selection
        selectedFileURL = nil
        selectedFileName = ""
        
        // Reset upload state
        uploadState = .idle
        fullViewURL = nil
        viewURL = nil
        
        // Reset video-related properties
        isVideo = false
        videoThumbnails = []
        selectedThumbnailIndex = 0
    }
    
    /// Checks if the selected file is a video and generates thumbnails if it is
    func checkFileTypeAndGenerateThumbnails() {
        guard let fileURL = selectedFileURL else { return }
        
        // Reset video-related properties
        isVideo = false
        videoThumbnails = []
        selectedThumbnailIndex = 0
        
        // Check if the file is a video based on UTI or file extension
        let fileExtension = fileURL.pathExtension.lowercased()
        let videoExtensions = ["mp4", "mov", "m4v", "avi", "mkv"]
        
        if videoExtensions.contains(fileExtension) {
            isVideo = true
            generateVideoThumbnails()
        }
    }
    
    /// Generates thumbnails for the selected video file
    private func generateVideoThumbnails() {
        guard let videoURL = selectedFileURL, isVideo else { return }
        
        // Update state to show we're generating previews
        uploadState = .generatingPreviews
        
        Task {
            do {
                // Generate thumbnails
                let thumbnails = try await VideoThumbnailGenerator.generateThumbnails(from: videoURL)
                
                await MainActor.run {
                    self.videoThumbnails = thumbnails
                    self.selectedThumbnailIndex = 0
                    self.uploadState = .idle
                }
            } catch {
                await MainActor.run {
                    self.uploadState = .error("Failed to generate video previews: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Gets the JPEG data for the selected thumbnail
    func getSelectedThumbnailData() -> Data? {
        guard isVideo && !videoThumbnails.isEmpty && selectedThumbnailIndex < videoThumbnails.count else {
            return nil
        }
        
        let selectedThumbnail = videoThumbnails[selectedThumbnailIndex]
        return VideoThumbnailGenerator.imageToJPEGData(selectedThumbnail.image)
    }
    
    func copyURLToClipboard(_ url: URL?) {
        guard let url = url else { return }
        UIPasteboard.general.string = url.absoluteString
    }
}
