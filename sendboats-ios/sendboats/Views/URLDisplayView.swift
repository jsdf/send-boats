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

    public init(title: String, url: URL, onCopy: @escaping () -> Void) {
        self.title = title
        self.url = url
        self.onCopy = onCopy
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
