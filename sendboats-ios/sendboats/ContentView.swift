//
//  ContentView.swift
//  sendboats
//
//  Created by James Friend on 3/22/25.
//

import SwiftUI
import PhotosUI
import Foundation

struct ContentView: View {
    @StateObject private var viewModel = UploadViewModel()
    @State private var showingDocumentPicker = false
    @State private var showingPhotoPicker = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Logo and title
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
                
                Spacer()
                
                // File selection
                VStack(spacing: 15) {
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
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    
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
                }
                .padding(.horizontal)
                
                // Configuration status
                if viewModel.username.isEmpty || viewModel.password.isEmpty {
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
                
                // Video preview section
                if viewModel.isVideo {
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
                
                // Upload button
                Button(action: {
                    Task {
                        viewModel.setupAPIClient()
                        await viewModel.uploadFile()
                    }
                }) {
                    HStack {
                        if case .uploading = viewModel.uploadState {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.trailing, 5)
                        } else {
                            Image(systemName: "arrow.up.circle.fill")
                        }
                        Text("Upload")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.selectedFileURL == nil || viewModel.username.isEmpty || viewModel.password.isEmpty ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(viewModel.selectedFileURL == nil || 
                          viewModel.uploadState == .uploading ||
                          viewModel.uploadState == .generatingPreviews ||
                          viewModel.username.isEmpty ||
                          viewModel.password.isEmpty)
                .padding(.horizontal)
                
                // Status and result
                Group {
                    switch viewModel.uploadState {
                    case .idle:
                        EmptyView()
                    case .generatingPreviews:
                        // We already show this in the video preview section
                        EmptyView()
                    case .uploading:
                        Text("Uploading...")
                            .foregroundColor(.blue)
                    case .success(let url):
                        VStack(spacing: 10) {
                            Text("Upload Successful!")
                                .foregroundColor(.green)
                                .fontWeight(.bold)
                            
                            // View URL
                            if let viewURL = viewModel.viewURL {
                                VStack(spacing: 5) {
                                    Text("View URL:")
                                        .font(.caption)
                                    
                                    HStack {
                                        Text(viewURL.absoluteString)
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            viewModel.copyURLToClipboard(viewURL)
                                        }) {
                                            Image(systemName: "doc.on.doc")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                            }
                            
                            // Full View URL
                            if let fullViewURL = viewModel.fullViewURL {
                                VStack(spacing: 5) {
                                    Text("Full View URL:")
                                        .font(.caption)
                                    
                                    HStack {
                                        Text(fullViewURL.absoluteString)
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            viewModel.copyURLToClipboard(fullViewURL)
                                        }) {
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
                    case .error(let message):
                        Text("Error: \(message)")
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                }
                .padding()
                
                Spacer()
            }
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPicker(
                    fileURL: $viewModel.selectedFileURL,
                    fileName: $viewModel.selectedFileName,
                    onFileSelected: {
                        viewModel.checkFileTypeAndGenerateThumbnails()
                    }
                )
            }
            .sheet(isPresented: $showingPhotoPicker) {
                PhotoPicker(
                    fileURL: $viewModel.selectedFileURL,
                    fileName: $viewModel.selectedFileName,
                    onFileSelected: {
                        viewModel.checkFileTypeAndGenerateThumbnails()
                    }
                )
            }
            .sheet(isPresented: $showingSettings) {
                ServerSettingsView(viewModel: viewModel)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

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

#Preview {
    ContentView()
}
