//
//  sendboatsApp.swift
//  sendboats
//
//  Created by James Friend on 3/22/25.
//

import SwiftUI

@main
struct sendboatsApp: App {
    @StateObject private var viewModel = UploadViewModel()
    @State private var showingShareNotification = false
    
    init() {
        print("DEBUG: sendboatsApp - App is launching")
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(viewModel)
                
                // Overlay notification when a file is shared
                if showingShareNotification {
                    VStack {
                        Spacer()
                        
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            
                            Text("File received from Share Extension")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Button(action: {
                                showingShareNotification = false
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground).opacity(0.9))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .padding()
                    }
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut, value: showingShareNotification)
                    .zIndex(1)
                }
            }
            .onOpenURL { url in
                print("DEBUG: sendboatsApp - App opened with URL: \(url.absoluteString)")
                
                // Handle URL scheme from Share Extension
                if url.scheme == "sendboats" {
                    print("DEBUG: sendboatsApp - URL scheme 'sendboats' detected")
                    
                    // The URL scheme is triggered, check for shared files
                    print("DEBUG: sendboatsApp - Calling checkForSharedFiles")
                    viewModel.checkForSharedFiles()
                    
                    // Show notification
                    print("DEBUG: sendboatsApp - Showing share notification")
                    showingShareNotification = true
                    
                    // Hide notification after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        print("DEBUG: sendboatsApp - Hiding share notification")
                        showingShareNotification = false
                    }
                } else {
                    print("DEBUG: sendboatsApp - URL scheme '\(url.scheme ?? "nil")' not recognized")
                }
            }
        }
    }
}
