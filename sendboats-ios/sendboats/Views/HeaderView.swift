//
//  HeaderView.swift
//  sendboats
//
//  Created on 3/23/25.
//

import SwiftUI

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

#Preview {
    HeaderView()
}
