//
//  ShareDemoView.swift
//  sendboats
//
//  Created on 12/16/24.
//

import SwiftUI

struct ShareDemoView: View {
    let sampleViewURL = URL(string: "https://send-boats.example.com/view/abc123")!
    let sampleFullURL = URL(string: "https://send-boats.example.com/file/abc123")!
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Upload Successful!")
                    .font(.title)
                    .fontWeight(.bold)
                
                // Show the updated URLDisplayView with share functionality
                URLDisplayView(title: "View URL:", url: sampleViewURL, onShare: {
                    print("Share button tapped for view URL")
                    ShareService.shareURL(sampleViewURL)
                })
                
                URLDisplayView(title: "Full URL:", url: sampleFullURL, onShare: {
                    print("Share button tapped for full URL")
                    ShareService.shareURL(sampleFullURL)
                })
                
                Button("Upload Another File") {
                    print("Upload another file tapped")
                }
                .padding()
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .cornerRadius(15)
        .shadow(radius: 5)
        .padding()
    }
}

#Preview {
    ShareDemoView()
        .previewDisplayName("Share Sheet Demo")
}