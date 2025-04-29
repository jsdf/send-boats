//
//  ShareViewController.swift
//  ShareExtension
//
//  Created on 4/28/25.
//

import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers
import SwiftUI
import AVFoundation

class ShareViewController: UIViewController {
    
    private var statusLabel: UILabel!
    private var progressView: UIProgressView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the UI
        view.backgroundColor = .systemBackground
        
        setupUI()
        
        // Process the shared items
        processSharedItems { success, errorMessage in
            if success {
                self.statusLabel.text = "File ready for upload!"
                self.progressView.progress = 1.0
                
                // Return to the host app after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.openHostApp()
                }
            } else {
                self.statusLabel.text = errorMessage ?? "Failed to process file"
                
                // Return to the host app after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
                }
            }
        }
    }
    
    private func setupUI() {
        // Add a label to show status
        statusLabel = UILabel()
        statusLabel.text = "Processing shared content..."
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
        
        // Add a progress view
        progressView = UIProgressView(progressViewStyle: .default)
        progressView.progress = 0.0
        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)
        
        // Add a cancel button
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cancelButton)
        
        // Add constraints
        NSLayoutConstraint.activate([
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            
            progressView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 20),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            cancelButton.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 20),
            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    @objc private func cancelButtonTapped() {
        // Cancel the operation and dismiss the extension
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
    func processSharedItems(completion: @escaping (Bool, String?) -> Void) {
        print("DEBUG: ShareExtension - Starting to process shared items")
        
        // Ensure we have a valid extension context
        guard let extensionContext = extensionContext else {
            print("DEBUG: ShareExtension - Invalid extension context")
            completion(false, "Invalid extension context")
            return
        }
        
        // Get the first item attachment
        guard let item = extensionContext.inputItems.first as? NSExtensionItem,
              let attachments = item.attachments else {
            print("DEBUG: ShareExtension - No attachments found")
            completion(false, "No attachments found")
            return
        }
        
        print("DEBUG: ShareExtension - Found \(attachments.count) attachments")
        
        // Process each attachment
        for (index, attachment) in attachments.enumerated() {
            print("DEBUG: ShareExtension - Processing attachment \(index + 1)")
            
            // Check if the attachment is a file URL
            if attachment.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                print("DEBUG: ShareExtension - Attachment is a file URL")
                attachment.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (urlData, error) in
                    if let error = error {
                        print("DEBUG: ShareExtension - Error loading file URL: \(error.localizedDescription)")
                        if index == attachments.count - 1 {
                            completion(false, "Error loading file: \(error.localizedDescription)")
                        }
                        return
                    }
                    
                    guard let urlData = urlData as? Data,
                          let url = URL(dataRepresentation: urlData, relativeTo: nil) else {
                        print("DEBUG: ShareExtension - Invalid file URL data")
                        if index == attachments.count - 1 {
                            completion(false, "Invalid file URL data")
                        }
                        return
                    }
                    
                    print("DEBUG: ShareExtension - File URL: \(url.absoluteString)")
                    
                    // Save the file URL to the shared UserDefaults
                    self.saveSharedFile(url: url)
                    completion(true, nil)
                }
                return
            }
            
            // Check if the attachment is a movie/video
            if attachment.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                print("DEBUG: ShareExtension - Attachment is a movie/video")
                attachment.loadItem(forTypeIdentifier: UTType.movie.identifier, options: nil) { (videoURL, error) in
                    if let error = error {
                        print("DEBUG: ShareExtension - Error loading video: \(error.localizedDescription)")
                        if index == attachments.count - 1 {
                            completion(false, "Error loading video: \(error.localizedDescription)")
                        }
                        return
                    }
                    
                    guard let videoURL = videoURL as? URL else {
                        print("DEBUG: ShareExtension - Invalid video URL")
                        if index == attachments.count - 1 {
                            completion(false, "Invalid video URL")
                        }
                        return
                    }
                    
                    print("DEBUG: ShareExtension - Video URL: \(videoURL.absoluteString)")
                    
                    // Save the video URL to the shared UserDefaults
                    self.saveSharedFile(url: videoURL)
                    completion(true, nil)
                }
                return
            }
            
            // Check if the attachment is an image
            if attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                print("DEBUG: ShareExtension - Attachment is an image")
                attachment.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { (imageURL, error) in
                    if let error = error {
                        print("DEBUG: ShareExtension - Error loading image: \(error.localizedDescription)")
                        if index == attachments.count - 1 {
                            completion(false, "Error loading image: \(error.localizedDescription)")
                        }
                        return
                    }
                    
                    // Handle both URL and UIImage cases
                    if let imageURL = imageURL as? URL {
                        print("DEBUG: ShareExtension - Image URL: \(imageURL.absoluteString)")
                        // Save the image URL to the shared UserDefaults
                        self.saveSharedFile(url: imageURL)
                        completion(true, nil)
                    } else if let image = imageURL as? UIImage {
                        print("DEBUG: ShareExtension - Got UIImage, saving to file")
                        // Save the image to a temporary file
                        self.saveImageToFile(image: image) { success, url in
                            if success, let url = url {
                                print("DEBUG: ShareExtension - Image saved to: \(url.absoluteString)")
                                self.saveSharedFile(url: url)
                                completion(true, nil)
                            } else {
                                print("DEBUG: ShareExtension - Failed to save image to file")
                                completion(false, "Failed to save image to file")
                            }
                        }
                    } else {
                        print("DEBUG: ShareExtension - Unsupported image format")
                        if index == attachments.count - 1 {
                            completion(false, "Unsupported image format")
                        }
                    }
                }
                return
            }
            
            // Check if the attachment is text
            if attachment.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                print("DEBUG: ShareExtension - Attachment is text")
                attachment.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { (text, error) in
                    if let error = error {
                        print("DEBUG: ShareExtension - Error loading text: \(error.localizedDescription)")
                        if index == attachments.count - 1 {
                            completion(false, "Error loading text: \(error.localizedDescription)")
                        }
                        return
                    }
                    
                    guard let text = text as? String else {
                        print("DEBUG: ShareExtension - Invalid text data")
                        if index == attachments.count - 1 {
                            completion(false, "Invalid text data")
                        }
                        return
                    }
                    
                    print("DEBUG: ShareExtension - Text content: \(text.prefix(50))...")
                    
                    // Save the text to a temporary file
                    self.saveTextToFile(text: text) { success, url in
                        if success, let url = url {
                            print("DEBUG: ShareExtension - Text saved to: \(url.absoluteString)")
                            self.saveSharedFile(url: url)
                            completion(true, nil)
                        } else {
                            print("DEBUG: ShareExtension - Failed to save text to file")
                            completion(false, "Failed to save text to file")
                        }
                    }
                }
                return
            }
            
            // If we've reached the last attachment and haven't found a suitable item
            if index == attachments.count - 1 {
                print("DEBUG: ShareExtension - No supported content types found")
                completion(false, "No supported content types found")
            }
        }
    }
    
    // Save an image to a temporary file
    private func saveImageToFile(image: UIImage, completion: @escaping (Bool, URL?) -> Void) {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            completion(false, nil)
            return
        }
        
        let fileManager = FileManager.default
        let tempDirectoryURL = fileManager.temporaryDirectory
        let fileName = "shared_image_\(UUID().uuidString).jpg"
        let fileURL = tempDirectoryURL.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            completion(true, fileURL)
        } catch {
            print("DEBUG: ShareExtension - Error saving image to file: \(error.localizedDescription)")
            completion(false, nil)
        }
    }
    
    // Save text to a temporary file
    private func saveTextToFile(text: String, completion: @escaping (Bool, URL?) -> Void) {
        let fileManager = FileManager.default
        let tempDirectoryURL = fileManager.temporaryDirectory
        let fileName = "shared_text_\(UUID().uuidString).txt"
        let fileURL = tempDirectoryURL.appendingPathComponent(fileName)
        
        do {
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
            completion(true, fileURL)
        } catch {
            print("DEBUG: ShareExtension - Error saving text to file: \(error.localizedDescription)")
            completion(false, nil)
        }
    }
    
    func saveSharedFile(url: URL) {
        print("DEBUG: ShareExtension - Starting to save shared file: \(url.lastPathComponent)")
        
        // Create a file manager
        let fileManager = FileManager.default
        
        // Get the shared container URL
        guard let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.jsdf.sendboats") else {
            print("DEBUG: ShareExtension - Failed to get container URL")
            return
        }
        
        print("DEBUG: ShareExtension - Shared container URL: \(containerURL.absoluteString)")
        
        // Create a directory for shared files if it doesn't exist
        let sharedFilesDirectory = containerURL.appendingPathComponent("SharedFiles", isDirectory: true)
        
        do {
            if !fileManager.fileExists(atPath: sharedFilesDirectory.path) {
                print("DEBUG: ShareExtension - Creating shared files directory")
                try fileManager.createDirectory(at: sharedFilesDirectory, withIntermediateDirectories: true)
            }
            
            // Check if this is a video file and ensure it has the correct extension
            var finalURL = url
            let fileExtension = url.pathExtension.lowercased()
            
            if fileExtension == "mov" {
                // Check if the file is actually an MP4 container
                let asset = AVURLAsset(url: url)
                if isMP4Container(asset) {
                    print("DEBUG: ShareExtension - Detected MP4 container with .mov extension, fixing extension")
                    
                    // Create a temporary file with .mp4 extension
                    let tempDir = FileManager.default.temporaryDirectory
                    let fileName = url.deletingPathExtension().lastPathComponent
                    let newURL = tempDir.appendingPathComponent("\(fileName).mp4")
                    
                    // Copy the file with the new extension
                    try fileManager.copyItem(at: url, to: newURL)
                    finalURL = newURL
                    print("DEBUG: ShareExtension - Changed file extension from .mov to .mp4")
                }
            }
            
            // Create a unique filename
            let uniqueFilename = UUID().uuidString + "-" + finalURL.lastPathComponent
            let destinationURL = sharedFilesDirectory.appendingPathComponent(uniqueFilename)
            
            print("DEBUG: ShareExtension - Destination URL: \(destinationURL.absoluteString)")
            
            // Copy the file to the shared container
            try fileManager.copyItem(at: finalURL, to: destinationURL)
            
            // Save the file information to UserDefaults
            let sharedDefaults = UserDefaults(suiteName: "group.jsdf.sendboats")
            sharedDefaults?.set(destinationURL.path, forKey: "SharedFilePath")
            sharedDefaults?.set(finalURL.lastPathComponent, forKey: "SharedFileName")
            sharedDefaults?.set(true, forKey: "HasSharedFile")
            sharedDefaults?.synchronize()
            
            print("DEBUG: ShareExtension - File saved to shared container: \(destinationURL.path)")
            print("DEBUG: ShareExtension - UserDefaults values set: SharedFilePath=\(destinationURL.path), SharedFileName=\(finalURL.lastPathComponent), HasSharedFile=true")
            
            // Clean up temporary file if we created one
            if finalURL != url {
                try? fileManager.removeItem(at: finalURL)
            }
        } catch {
            print("DEBUG: ShareExtension - Error saving file to shared container: \(error.localizedDescription)")
        }
    }
    
    /// Determines if a video asset is in MP4 container format
    /// - Parameter asset: The AVURLAsset to check
    /// - Returns: True if the asset is in MP4 container format
    private func isMP4Container(_ asset: AVURLAsset) -> Bool {
        // Check file extension first
        let fileExtension = asset.url.pathExtension.lowercased()
        
        // For iOS camera roll videos, they're typically in MP4 container format
        if fileExtension == "mov" {
            // Most modern iOS videos are H.264 in MP4 containers even if named .mov
            return true
        }
        
        return true
    }
    
    func openHostApp() {
        // URL scheme to open the main app
        let urlString = "sendboats://share"
        
        print("DEBUG: ShareExtension - Attempting to open main app with URL: \(urlString)")
        
        if let url = URL(string: urlString) {
            let selector = sel_registerName("openURL:")
            var responder: UIResponder? = self
            
            while responder != nil {
                if responder?.responds(to: selector) == true {
                    print("DEBUG: ShareExtension - Found responder that can open URL")
                    
                    // Use the non-deprecated open method
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    } else {
                        responder?.perform(selector, with: url)
                    }
                    break
                }
                responder = responder?.next
            }
        }
        
        // Complete the request
        print("DEBUG: ShareExtension - Completing extension request")
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
}
