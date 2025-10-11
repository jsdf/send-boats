//
//  URLDisplayView.swift
//  sendboats
//
//  Created on 3/23/25.
//

import SwiftUI

public struct URLDisplayView: View {
    public let title: String
    public let url: URL
    public let onCopy: () -> Void
    public let onShare: (() -> Void)?

    public init(title: String, url: URL, onCopy: @escaping () -> Void, onShare: (() -> Void)? = nil) {
        self.title = title
        self.url = url
        self.onCopy = onCopy
        self.onShare = onShare
    }

    public var body: some View {
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

                HStack(spacing: 8) {
                    Button(action: onCopy) {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.blue)
                            .font(.system(size: 16))
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    
                    if let onShare = onShare {
                        Button(action: onShare) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
                                .font(.system(size: 16))
                        }
                        .frame(minWidth: 44, minHeight: 44)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                    }
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
        onCopy: {},
        onShare: {}
    )
    .padding()
    .previewLayout(.sizeThatFits)
}
