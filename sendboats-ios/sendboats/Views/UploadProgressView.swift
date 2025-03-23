//
//  UploadProgressView.swift
//  sendboats
//
//  Created on 3/23/25.
//

import SwiftUI

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

#Preview {
    UploadProgressView()
}
