//
//  APIClient.swift
//  sendboats
//
//  Created on 3/23/25.
//

import Foundation
import Combine

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

class APIClient {
    private var baseURL: URL
    private var username: String
    private var password: String
    
    init(baseURL: URL, username: String, password: String) {
        self.baseURL = baseURL
        self.username = username
        self.password = password
    }
    
    func uploadFile(fileURL: URL) async throws -> UploadResponse {
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
        
        // Add file data
        do {
            let fileData = try Data(contentsOf: fileURL)
            body.append(fileData)
            body.append("\r\n".data(using: .utf8)!)
        } catch {
            throw APIError.networkError(error)
        }
        
        // Close the form
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        // Set the body
        request.httpBody = body
        
        // Perform the request
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.unknown
            }
            
            // Check status code
            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.serverError(httpResponse.statusCode)
            }
            
            // Decode the response
            do {
                let uploadResponse = try JSONDecoder().decode(UploadResponse.self, from: data)
                return uploadResponse
            } catch {
                throw APIError.decodingError(error)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
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
            return "video/quicktime"
        case "txt":
            return "text/plain"
        default:
            return "application/octet-stream"
        }
    }
    
    func getFullViewURL(for fileKey: String) -> URL {
        return baseURL.appendingPathComponent("full/\(fileKey)")
    }
}
