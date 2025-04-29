//
//  UploadViewModel.swift
//  sendboats
//
//  Created on 3/23/25.
//

import Foundation
import SwiftUI
import AVFoundation

// UI flow states
enum UIFlowState {
    case fileSelection
    case previewAndUpload
    case uploading
    case success
}

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
    // Check for shared files when the app launches
    init() {
        // Load configuration from UserDefaults
        let configuration = ConfigurationManager.shared.loadConfiguration()
        self.serverURL = configuration.serverURL
        self.username = configuration.username
        self.password = configuration.password
        
        // Initialize API client with loaded values
        setupAPIClient()
        
        // Check for shared files
        checkForSharedFiles()
    }
    
    // Computed property for UI flow state
    var uiFlowState: UIFlowState {
        // No file selected = file selection state
        if selectedFileURL == nil || selectedFileName.isEmpty {
            return .fileSelection
        }
        
        // Check upload state
        switch uploadState {
        case .uploading:
            return .uploading
        case .success:
            return .success
        case .error, .generatingPreviews, .idle:
            return .previewAndUpload
        }
    }
    
    @Published var serverURL: String
    @Published var username: String
    @Published var password: String
    @Published var selectedFileURL: URL?
    @Published var selectedFileName: String = ""
    @Published var uploadState: UploadState = .idle
    @Published var uploadProgress: Double = 0.0
    @Published var fullViewURL: URL?
    @Published var viewURL: URL?
    
    // Video preview properties
    @Published var isVideo: Bool = false
    @Published var videoThumbnails: [VideoThumbnail] = []
    @Published var selectedThumbnailIndex: Int = 0
    
    private var apiClient: APIClient?
    
    // Check for files shared from the Share Extension
    func checkForSharedFiles() {
        print("DEBUG: UploadViewModel - Checking for shared files")
        
        // Access shared UserDefaults
        let sharedDefaults = UserDefaults(suiteName: "group.jsdf.sendboats")
        
        // Check if there's a shared file
        if let hasSharedFile = sharedDefaults?.bool(forKey: "HasSharedFile") {
            print("DEBUG: UploadViewModel - HasSharedFile: \(hasSharedFile)")
        } else {
            print("DEBUG: UploadViewModel - HasSharedFile key not found in UserDefaults")
        }
        
        if let sharedFilePath = sharedDefaults?.string(forKey: "SharedFilePath") {
            print("DEBUG: UploadViewModel - SharedFilePath: \(sharedFilePath)")
        } else {
            print("DEBUG: UploadViewModel - SharedFilePath key not found in UserDefaults")
        }
        
        if let sharedFileName = sharedDefaults?.string(forKey: "SharedFileName") {
            print("DEBUG: UploadViewModel - SharedFileName: \(sharedFileName)")
        } else {
            print("DEBUG: UploadViewModel - SharedFileName key not found in UserDefaults")
        }
        
        // Check if there's a shared file
        if let hasSharedFile = sharedDefaults?.bool(forKey: "HasSharedFile"), hasSharedFile,
           let sharedFilePath = sharedDefaults?.string(forKey: "SharedFilePath"),
           let sharedFileName = sharedDefaults?.string(forKey: "SharedFileName") {
            
            print("DEBUG: UploadViewModel - Found shared file: \(sharedFileName) at path: \(sharedFilePath)")
            
            // Create a URL from the path
            let sharedFileURL = URL(fileURLWithPath: sharedFilePath)
            
            // Check if the file exists
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: sharedFilePath) {
                print("DEBUG: UploadViewModel - File exists at path")
            } else {
                print("DEBUG: UploadViewModel - WARNING: File does not exist at path: \(sharedFilePath)")
            }
            
            // Handle the shared file
            print("DEBUG: UploadViewModel - Handling file selection")
            handleFileSelection(fileURL: sharedFileURL, fileName: sharedFileName)
            
            // Reset the shared file flag
            print("DEBUG: UploadViewModel - Resetting shared file flags in UserDefaults")
            sharedDefaults?.set(false, forKey: "HasSharedFile")
            sharedDefaults?.removeObject(forKey: "SharedFilePath")
            sharedDefaults?.removeObject(forKey: "SharedFileName")
            sharedDefaults?.synchronize()
            
            // Automatically start the upload process
            print("DEBUG: UploadViewModel - Starting automatic upload")
            Task {
                await uploadFile()
            }
        } else {
            print("DEBUG: UploadViewModel - No shared file found")
        }
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
        print("DEBUG: UploadViewModel - Starting uploadFile")
        
        guard let apiClient = apiClient else {
            print("DEBUG: UploadViewModel - Error: API client not configured")
            uploadState = .error("API client not configured")
            return
        }
        
        guard let fileURL = selectedFileURL else {
            print("DEBUG: UploadViewModel - Error: No file selected")
            uploadState = .error("No file selected")
            return
        }
        
        print("DEBUG: UploadViewModel - File URL: \(fileURL.absoluteString)")
        
        // Check if the file exists
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: fileURL.path) {
            print("DEBUG: UploadViewModel - File exists at path")
        } else {
            print("DEBUG: UploadViewModel - WARNING: File does not exist at path: \(fileURL.path)")
            await MainActor.run {
                uploadState = .error("File does not exist at path: \(fileURL.path)")
            }
            return
        }
        
        // Reset progress and update state to uploading
        await MainActor.run {
            uploadProgress = 0.0
            uploadState = .uploading
        }
        
        do {
            // Start accessing the security-scoped resource
            print("DEBUG: UploadViewModel - Starting to access security-scoped resource")
            let didStartAccessing = fileURL.startAccessingSecurityScopedResource()
            print("DEBUG: UploadViewModel - Did start accessing: \(didStartAccessing)")
            
            // Get preview image data if this is a video
            let previewData = isVideo ? getSelectedThumbnailData() : nil
            print("DEBUG: UploadViewModel - Is video: \(isVideo), Has preview data: \(previewData != nil)")
            
            // Upload the file with preview if available and track progress
            print("DEBUG: UploadViewModel - Starting file upload")
            let response = try await apiClient.uploadFile(
                fileURL: fileURL, 
                previewImageData: previewData,
                progressHandler: { [weak self] progress in
                    // Update progress on main thread
                    Task { @MainActor in
                        self?.uploadProgress = progress
                        print("DEBUG: UploadViewModel - Upload progress: \(progress)")
                    }
                }
            )
            
            print("DEBUG: UploadViewModel - Upload successful, response key: \(response.key)")
            
            // Stop accessing the security-scoped resource if needed
            if didStartAccessing {
                print("DEBUG: UploadViewModel - Stopping access to security-scoped resource")
                fileURL.stopAccessingSecurityScopedResource()
            }
            
            // Get the URLs
            let fullURL = apiClient.getFullViewURL(for: response.key)
            let viewURL = apiClient.getViewURL(for: response.key)
            
            print("DEBUG: UploadViewModel - Full URL: \(fullURL.absoluteString)")
            print("DEBUG: UploadViewModel - View URL: \(viewURL.absoluteString)")
            
            // Update state to success
            await MainActor.run {
                self.fullViewURL = fullURL
                self.viewURL = viewURL
                uploadState = .success(fullURL)
                print("DEBUG: UploadViewModel - State updated to success")
            }
        } catch let error as APIError {
            print("DEBUG: UploadViewModel - API Error: \(error.localizedDescription)")
            await MainActor.run {
                uploadState = .error(error.localizedDescription)
            }
        } catch {
            print("DEBUG: UploadViewModel - Unknown Error: \(error.localizedDescription)")
            await MainActor.run {
                uploadState = .error("An unknown error occurred: \(error.localizedDescription)")
            }
        }
    }
    
    /// Handles the selection of a new file
    /// - Parameters:
    ///   - fileURL: The URL of the selected file
    ///   - fileName: The name of the selected file
    func handleFileSelection(fileURL: URL, fileName: String) {
        print("DEBUG: UploadViewModel - Handling file selection: \(fileName)")
        
        // Reset all state first
        reset()
        
        // Set new file information
        selectedFileURL = fileURL
        selectedFileName = fileName
        
        print("DEBUG: UploadViewModel - File URL set to: \(fileURL.absoluteString)")
        print("DEBUG: UploadViewModel - File name set to: \(fileName)")
        
        // Process the file (check type, generate thumbnails if needed)
        checkFileTypeAndGenerateThumbnails()
    }
    
    /// Resets all state variables to their initial values
    func reset() {
        // Reset file selection
        selectedFileURL = nil
        selectedFileName = ""
        
        // Reset upload state
        uploadState = .idle
        uploadProgress = 0.0
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
