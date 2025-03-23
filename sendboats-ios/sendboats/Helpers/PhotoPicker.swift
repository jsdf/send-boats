//
//  PhotoPicker.swift
//  sendboats
//
//  Created on 3/23/25.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var fileURL: URL?
    @Binding var fileName: String
    
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
            
            // Get file name from the item provider
            if let assetIdentifier = result.assetIdentifier,
               let assetResults = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil).firstObject {
                
                // Get file name from asset
                let resources = PHAssetResource.assetResources(for: assetResults)
                if let resource = resources.first {
                    parent.fileName = resource.originalFilename
                }
            }
            
            // Load the item provider's data
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) && parent.fileName.isEmpty {
                // If we couldn't get the filename but it's an image, use a default name
                parent.fileName = "image_\(Date().timeIntervalSince1970).jpg"
            } else if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) && parent.fileName.isEmpty {
                // If we couldn't get the filename but it's a video, use a default name
                parent.fileName = "video_\(Date().timeIntervalSince1970).mov"
            }
            
            // Get the file URL by copying to a temporary location
            result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.item.identifier) { [weak self] url, error in
                guard let url = url, error == nil else {
                    print("Error loading file representation: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                // Create a temporary file URL
                let tempDirectoryURL = FileManager.default.temporaryDirectory
                let tempFileURL = tempDirectoryURL.appendingPathComponent(self?.parent.fileName ?? "file_\(Date().timeIntervalSince1970)")
                
                do {
                    // Copy the file to our temporary location
                    try FileManager.default.copyItem(at: url, to: tempFileURL)
                    
                    // Update the file URL on the main thread
                    DispatchQueue.main.async {
                        self?.parent.fileURL = tempFileURL
                    }
                } catch {
                    print("Error copying file: \(error.localizedDescription)")
                }
            }
        }
    }
}
