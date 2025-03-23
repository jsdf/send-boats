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
            Image(systemName: "sailboat")
                .imageScale(.large)
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            Text("send.boats")
                .font(.largeTitle)
                .fontWeight(.bold)
        }
        .padding(.top, 40)
    }
}

#Preview {
    HeaderView()
}
