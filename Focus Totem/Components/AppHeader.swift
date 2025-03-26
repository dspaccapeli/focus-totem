//
//  AppHeader.swift
//  Deliberate
//
//  Created by Daniele Spaccapeli on 13/03/25.
//

import SwiftUICore


struct AppHeader: View {
    var showTagline: Bool = true
    var tagline: String = "Live more, scroll less" // Your time, your choice | Choose what matters
    
    var body: some View {
        VStack {
            Text("deliberate")
                .font(.custom("IowanOldStyle-Bold", size: 30))
                .foregroundColor(.blue)
            
            if showTagline {
                Text(tagline)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}
