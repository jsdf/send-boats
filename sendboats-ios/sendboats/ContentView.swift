//
//  ContentView.swift
//  sendboats
//
//  Created by James Friend on 3/22/25.
//

import SwiftUI
import PhotosUI
import Foundation

// UI flow states
enum UIFlowState {
    case fileSelection
    case previewAndUpload
    case uploading
    case success
}

// MARK: - Header View
struct HeaderView: View {
    var body: some View {
        VStack {
            Image(systemName: "paperplane.fill")
                .imageScale(.large)
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            Text("Send Boats")
                .font(.largeTitle)
                .fontWeight(.bold)
        }
        .padding(.top, 40)
    }
}

// MARK: - File Selection View
struct FileSelectionView: View {
    @ObservedObject var viewModel: UploadViewModel
    @Binding var uiState: UIFlowState
    @Binding var showingDocumentPicker: Bool
    @Binding var showingPhotoPicker: Bool
    
    var body: some View {
        VStack(spacing: 15) {
            // File selection buttons
            HStack(spacing: 10) {
                Button(action: {
                    showingDocumentPicker = true
                }) {
                    HStack {
                        Image(systemName: "doc.fill")
                        Text("Files")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    showingPhotoPicker = true
                }) {
                    HStack {
                        Image(systemName: "photo.fill")
                        Text("Photos")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            
            // Selected file display
            if !viewModel.selectedFileName.isEmpty {
                HStack {
                    Image(systemName: "doc.fill")
                        .foregroundColor(.blue)
                    Text(viewModel.selectedFileName)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.reset()
                        uiState = .fileSelection
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Configuration Warning View
struct ConfigurationWarningView: View {
    let isConfigured: Bool
    
    var body: some View {
        if !isConfigured {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("API credentials not configured. Tap the gear icon to set up.")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            .padding(.horizontal)
            .padding(.bottom, 5)
        }
    }
}

// MARK: - Video Preview View
struct VideoPreviewView: View {
    @ObservedObject var viewModel: UploadViewModel
    
    var body: some View {
        VStack(spacing: 10) {
            if case .generatingPreviews = viewModel.uploadState {
                VStack(spacing: 5) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Text("Generating video previews...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else if !viewModel.videoThumbnails.isEmpty {
                Text("Select a preview image:")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(0..<viewModel.videoThumbnails.count, id: \.self) { index in
                            VStack {
                                Image(uiImage: viewModel.videoThumbnails[index].image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 160, height: 90)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(index == viewModel.selectedThumbnailIndex ? Color.blue : Color.clear, lineWidth: 3)
                                    )
                                    .onTapGesture {
                                        viewModel.selectedThumbnailIndex = index
                                    }
                                
                                Text(VideoThumbnailGenerator.formatTimestamp(viewModel.videoThumbnails[index].timestamp))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.bottom, 10)
    }
}

// MARK: - Upload Button View
struct UploadButtonView: View {
    @ObservedObject var viewModel: UploadViewModel
    @Binding var uiState: UIFlowState
    
    var body: some View {
        Button(action: {
            Task {
                viewModel.setupAPIClient()
                uiState = .uploading
                await viewModel.uploadFile()
                if case .success = viewModel.uploadState {
                    uiState = .success
                } else if case .error = viewModel.uploadState {
                    uiState = .previewAndUpload
                }
            }
        }) {
            HStack {
                Image(systemName: "arrow.up.circle.fill")
                Text("Upload")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.username.isEmpty || viewModel.password.isEmpty ? Color.gray : Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(viewModel.uploadState == .generatingPreviews ||
                  viewModel.username.isEmpty ||
                  viewModel.password.isEmpty)
        .padding(.horizontal)
    }
}

// MARK: - Upload Progress View
struct UploadProgressView: View {
    var body: some View {
        VStack(spacing: 15) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
                .padding()
            
            Text("Uploading...")
                .foregroundColor(.blue)
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

// MARK: - URL Display View
struct URLDisplayView: View {
    let title: String
    let url: URL
    let onCopy: () -> Void
    
    var body: some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.caption)
            
            HStack {
                Text(url.absoluteString)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                Spacer()
                
                Button(action: onCopy) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
}

// MARK: - Success View
struct SuccessView: View {
    @ObservedObject var viewModel: UploadViewModel
    @Binding var uiState: UIFlowState
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Upload Successful!")
                .foregroundColor(.green)
                .fontWeight(.bold)
                .font(.headline)
            
            // View URL
            if let viewURL = viewModel.viewURL {
                URLDisplayView(
                    title: "View URL:",
                    url: viewURL,
                    onCopy: { viewModel.copyURLToClipboard(viewURL) }
                )
            }
            
            // Full View URL
            if let fullViewURL = viewModel.fullViewURL {
                URLDisplayView(
                    title: "Full View URL:",
                    url: fullViewURL,
                    onCopy: { viewModel.copyURLToClipboard(fullViewURL) }
                )
            }
            
            // New upload button
            Button(action: {
                viewModel.reset()
                uiState = .fileSelection
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("New Upload")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.top, 10)
        }
        .padding()
    }
}

// MARK: - Error View
struct ErrorView: View {
    let errorMessage: String
    
    var body: some View {
        Text("Error: \(errorMessage)")
            .foregroundColor(.red)
            .multilineTextAlignment(.center)
            .padding()
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @StateObject private var viewModel = UploadViewModel()
    @State private var showingDocumentPicker = false
    @State private var showingPhotoPicker = false
    @State private var showingSettings = false
    @State private var uiState: UIFlowState = .fileSelection
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                HeaderView()
                
                Spacer()
                
                // File selection
                FileSelectionView(
                    viewModel: viewModel,
                    uiState: $uiState,
                    showingDocumentPicker: $showingDocumentPicker,
                    showingPhotoPicker: $showingPhotoPicker
                )
                
                // Configuration warning
                ConfigurationWarningView(
                    isConfigured: !(viewModel.username.isEmpty || viewModel.password.isEmpty)
                )
                
                // Content based on UI state
                if !viewModel.selectedFileName.isEmpty {
                    switch uiState {
                    case .fileSelection:
                        EmptyView()
                        
                    case .previewAndUpload:
                        VStack {
                            // Video preview
                            if viewModel.isVideo {
                                VideoPreviewView(viewModel: viewModel)
                            }
                            
                            // Upload button
                            UploadButtonView(viewModel: viewModel, uiState: $uiState)
                        }
                        
                    case .uploading:
                        UploadProgressView()
                        
                    case .success:
                        if case .success = viewModel.uploadState {
                            SuccessView(viewModel: viewModel, uiState: $uiState)
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
                    fileURL: $viewModel.selectedFileURL,
                    fileName: $viewModel.selectedFileName,
                    onFileSelected: {
                        viewModel.checkFileTypeAndGenerateThumbnails()
                        uiState = .previewAndUpload
                    }
                )
            }
            .sheet(isPresented: $showingPhotoPicker) {
                PhotoPicker(
                    fileURL: $viewModel.selectedFileURL,
                    fileName: $viewModel.selectedFileName,
                    onFileSelected: {
                        viewModel.checkFileTypeAndGenerateThumbnails()
                        uiState = .previewAndUpload
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
            .onReceive(viewModel.$uploadState) { newState in
                // Update UI state based on upload state changes
                switch newState {
                case .uploading:
                    uiState = .uploading
                case .success:
                    uiState = .success
                case .error:
                    // Keep current UI state on error
                    break
                default:
                    break
                }
            }
            .onReceive(viewModel.$selectedFileURL) { fileURL in
                // When a file is selected, move to preview and upload state
                if fileURL != nil && uiState == .fileSelection {
                    uiState = .previewAndUpload
                }
            }
        }
    }
}

// MARK: - Server Settings View
struct ServerSettingsView: View {
    @ObservedObject var viewModel: UploadViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Server Configuration")) {
                    TextField("Server URL", text: $viewModel.serverURL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.URL)
                    
                    TextField("Username (required)", text: $viewModel.username)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    SecureField("Password (required)", text: $viewModel.password)
                }
                
                Section(header: Text("Information"), footer: Text("Username and password are required to upload files.")) {
                    Text("Configure your API credentials to upload files to the server.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section {
                    Button("Save") {
                        viewModel.saveConfiguration()
                        dismiss()
                    }
                }
            }
            .navigationTitle("Server Settings")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
