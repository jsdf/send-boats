//
//  ContentView.swift
//  sendboats
//
//  Created by James Friend on 3/22/25.
//

import SwiftUI
import PhotosUI
import Foundation

// Import ViewModel
import class sendboats.UploadViewModel

// MARK: - Main Content View
struct ContentView: View {
    @StateObject private var viewModel = UploadViewModel()
    @State private var showingDocumentPicker = false
    @State private var showingPhotoPicker = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                HeaderView()
                
                Spacer()
                
                // File selection
                FileSelectionView(
                    viewModel: viewModel,
                    showingDocumentPicker: $showingDocumentPicker,
                    showingPhotoPicker: $showingPhotoPicker
                )
                
                // Configuration warning
                ConfigurationWarningView(
                    isConfigured: !(viewModel.username.isEmpty || viewModel.password.isEmpty)
                )
                
                // Content based on UI state
                if !viewModel.selectedFileName.isEmpty {
                    switch viewModel.uiFlowState {
                    case .fileSelection:
                        EmptyView()
                        
                    case .previewAndUpload:
                        VStack {
                            // Video preview
                            if viewModel.isVideo {
                                VideoPreviewView(viewModel: viewModel)
                            }
                            
                            // Upload button
                            UploadButtonView(viewModel: viewModel)
                        }
                        
                    case .uploading:
                        UploadProgressView(viewModel: viewModel)
                        
                    case .success:
                        if case .success = viewModel.uploadState {
                            SuccessView(viewModel: viewModel)
                        }
                    }
                }
                
                // Error message
                if case .error(let message) = viewModel.uploadState {
                    ErrorView(errorMessage: message)
                }
                
                Spacer()
            }
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPicker(
                    onFilePicked: { fileURL, fileName in
                        viewModel.handleFileSelection(fileURL: fileURL, fileName: fileName)
                    }
                )
            }
            .sheet(isPresented: $showingPhotoPicker) {
                PhotoPicker(
                    onFilePicked: { fileURL, fileName in
                        viewModel.handleFileSelection(fileURL: fileURL, fileName: fileName)
                    }
                )
            }
            .sheet(isPresented: $showingSettings) {
                ServerSettingsView(viewModel: viewModel)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: 
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "gear")
                }
            )
        }
    }
}


// MARK: - Preview
#Preview {
    ContentView()
}
