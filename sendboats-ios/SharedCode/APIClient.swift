//
//  APIClient.swift
//  sendboats
//
//  Created on 3/23/25.
//

import Foundation
import Combine
import UIKit

enum APIError: Error {
    case invalidURL
    case networkError(Error)
    case serverError(Int)
    case decodingError(Error)
    case unknown
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let statusCode):
            return "Server error with status code: \(statusCode)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

class APIClient: NSObject {
    private var baseURL: URL
    private var username: String
    private var password: String
    private var session: URLSession!
    
    init(baseURL: URL, username: String, password: String) {
        self.baseURL = baseURL
        self.username = username
        self.password = password
        super.init()
        
        // Create a URLSession configuration
        let configuration = URLSessionConfiguration.default
        
        // Create a URLSession with self as the delegate
        self.session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }
    
    func uploadFile(fileURL: URL, previewImageData: Data? = nil, progressHandler: ((Double) -> Void)? = nil) async throws -> UploadResponse {
        // Create the upload URL
        let uploadURL = baseURL.appendingPathComponent("upload")
        
        // Create a multipart form data request
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        
        // Add basic authentication
        let authString = "\(username):\(password)"
        if let authData = authString.data(using: .utf8) {
            let base64Auth = authData.base64EncodedString()
            request.addValue("Basic \(base64Auth)", forHTTPHeaderField: "Authorization")
        }
        
        // Generate boundary string
        let boundary = UUID().uuidString
        
        // Set content type
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Create body
        var body = Data()
        
        // Add file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
        
        // Get file content type
        let fileType = getContentType(for: fileURL)
        body.append("Content-Type: \(fileType)\r\n\r\n".data(using: .utf8)!)
        
        // Add file data using NSFileCoordinator for safe access
        var fileData: Data?
        var fileCoordinatorError: NSError?
        var fileReadingError: Error? // Local variable for reading error
        let coordinator = NSFileCoordinator()

        // Coordinate reading the file
        coordinator.coordinate(readingItemAt: fileURL, options: [], error: &fileCoordinatorError) { (coordinatedURL) in
            do {
                // Read data from the coordinated URL
                fileData = try Data(contentsOf: coordinatedURL)
            } catch {
                // Capture the reading error locally
                fileReadingError = error
                print("Error reading file data inside coordinator: \(error)")
            }
        }

        // Check for errors after coordination completes
        if let error = fileCoordinatorError {
            print("File coordination error: \(error)")
            throw APIError.networkError(error)
        }
        if let error = fileReadingError {
             print("File reading error: \(error)")
             throw APIError.networkError(error)
        }

        // Ensure file data was actually read
        guard let actualFileData = fileData else {
             // Throw an error if data couldn't be read for some reason (should be caught above ideally)
             let readError = NSError(domain: "APIClient", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to read file data using file coordinator, but no specific error was captured."])
             print("Error: File data is nil after coordination block without a captured error.")
             throw APIError.networkError(readError)
        }

        // Append the successfully read file data
        body.append(actualFileData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add preview image data if provided and file is a video
        if let previewData = previewImageData, fileType.starts(with: "video/") {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"preview\"; filename=\"preview.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(previewData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        // Close the form
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        // Set the body
        request.httpBody = body
        
        // Create a task handler to manage the upload task and progress updates
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                // Create the upload task
                let task = self.session.uploadTask(with: request, from: body) { data, response, error in
                    // Handle errors
                    if let error = error {
                        continuation.resume(throwing: APIError.networkError(error))
                        return
                    }
                    
                    // Check response
                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.resume(throwing: APIError.unknown)
                        return
                    }
                    
                    // Check status code
                    guard (200...299).contains(httpResponse.statusCode) else {
                        continuation.resume(throwing: APIError.serverError(httpResponse.statusCode))
                        return
                    }
                    
                    // Ensure we have data
                    guard let data = data else {
                        continuation.resume(throwing: APIError.unknown)
                        return
                    }
                    
                    // Decode the response
                    do {
                        let uploadResponse = try JSONDecoder().decode(UploadResponse.self, from: data)
                        continuation.resume(returning: uploadResponse)
                    } catch {
                        continuation.resume(throwing: APIError.decodingError(error))
                    }
                }
                
                // Store the task and progress handler in the task's userInfo dictionary
                if let progressHandler = progressHandler {
                    // Use associated objects to store the progress handler with the task
                    objc_setAssociatedObject(task, &AssociatedKeys.progressHandler, progressHandler, .OBJC_ASSOCIATION_RETAIN)
                }
                
                // Start the task
                task.resume()
            }
        } onCancel: {
            // Handle cancellation if needed
        }
    }
    
    private func getContentType(for url: URL) -> String {
        let fileExtension = url.pathExtension.lowercased()
        
        switch fileExtension {
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "gif":
            return "image/gif"
        case "pdf":
            return "application/pdf"
        case "doc":
            return "application/msword"
        case "docx":
            return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case "xls":
            return "application/vnd.ms-excel"
        case "xlsx":
            return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        case "mp4":
            return "video/mp4"
        case "mov":
            // For .mov files from iOS camera roll, they're typically in MP4 container format
            // So we'll use video/mp4 instead of video/quicktime for better browser compatibility
            return "video/mp4"
        case "txt":
            return "text/plain"
        default:
            return "application/octet-stream"
        }
    }
    
    func getFullViewURL(for fileKey: String) -> URL {
        return baseURL.appendingPathComponent("full/\(fileKey)")
    }
    
    func getViewURL(for fileKey: String) -> URL {
        return baseURL.appendingPathComponent("file/\(fileKey)")
    }
}

// MARK: - Associated Keys for Objective-C Runtime
private struct AssociatedKeys {
    static var progressHandler = "progressHandler"
}

// MARK: - URLSessionTaskDelegate
extension APIClient: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        // Calculate progress (0.0 to 1.0)
        let progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        
        // Get the progress handler associated with this task
        if let progressHandler = objc_getAssociatedObject(task, &AssociatedKeys.progressHandler) as? (Double) -> Void {
            // Call the progress handler on the main thread
            DispatchQueue.main.async {
                progressHandler(progress)
            }
        }
    }
}
