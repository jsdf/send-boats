//
//  URLDisplayView.swift
//  sendboats
//
//  Created on 3/23/25.
//

import SwiftUI

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

#Preview {
    URLDisplayView(
        title: "Example URL:",
        url: URL(string: "https://example.com/file/12345")!,
        onCopy: {}
    )
    .padding()
    .previewLayout(.sizeThatFits)
}
