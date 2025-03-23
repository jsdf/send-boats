//
//  DocumentPicker.swift
//  sendboats
//
//  Created on 3/23/25.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var fileURL: URL?
    @Binding var fileName: String
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // Create a document picker that can select any type of file
        let supportedTypes: [UTType] = [.content]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // Nothing to update
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            // Start accessing the security-scoped resource
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            
            // Set the file URL and name
            parent.fileURL = url
            parent.fileName = url.lastPathComponent
            
            // Stop accessing the security-scoped resource if needed
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
    }
}
