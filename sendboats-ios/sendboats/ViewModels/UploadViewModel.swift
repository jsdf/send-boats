//
//  UploadViewModel.swift
//  sendboats
//
//  Created on 3/23/25.
//

import Foundation
import SwiftUI

enum UploadState: Equatable {
    case idle
    case uploading
    case success(URL)
    case error(String)
    
    static func == (lhs: UploadState, rhs: UploadState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
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
            
            // Upload the file
            let response = try await apiClient.uploadFile(fileURL: fileURL)
            
            // Stop accessing the security-scoped resource if needed
            if didStartAccessing {
                fileURL.stopAccessingSecurityScopedResource()
            }
            
            // Get the full view URL
            let fullURL = apiClient.getFullViewURL(for: response.key)
            
            // Update state to success
            await MainActor.run {
                self.fullViewURL = fullURL
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
    
    func reset() {
        selectedFileURL = nil
        selectedFileName = ""
        uploadState = .idle
        fullViewURL = nil
    }
}
