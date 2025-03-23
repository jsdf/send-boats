//
//  ContentView.swift
//  sendboats
//
//  Created by James Friend on 3/22/25.
//

import SwiftUI
import PhotosUI

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
                    .background(viewModel.selectedFileURL == nil ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(viewModel.selectedFileURL == nil || 
                          viewModel.uploadState == .uploading)
                .padding(.horizontal)
                
                // Status and result
                Group {
                    switch viewModel.uploadState {
                    case .idle:
                        EmptyView()
                    case .uploading:
                        Text("Uploading...")
                            .foregroundColor(.blue)
                    case .success(let url):
                        VStack(spacing: 10) {
                            Text("Upload Successful!")
                                .foregroundColor(.green)
                                .fontWeight(.bold)
                            
                            Text("Full View URL:")
                                .font(.caption)
                            
                            Text(url.absoluteString)
                                .font(.caption)
                                .foregroundColor(.blue)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .multilineTextAlignment(.center)
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
                DocumentPicker(fileURL: $viewModel.selectedFileURL, fileName: $viewModel.selectedFileName)
            }
            .sheet(isPresented: $showingPhotoPicker) {
                PhotoPicker(fileURL: $viewModel.selectedFileURL, fileName: $viewModel.selectedFileName)
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
                    
                    TextField("Username", text: $viewModel.username)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    SecureField("Password", text: $viewModel.password)
                }
                
                Section {
                    Button("Save") {
                        viewModel.setupAPIClient()
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
