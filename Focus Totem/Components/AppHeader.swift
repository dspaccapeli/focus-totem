//
//  AppHeader.swift
//  Focus Totem
//
//  Created by Daniele Spaccapeli on 13/03/25.
//

import SwiftUI

struct AppHeader: View {
    var showTagline: Bool = true
    var showImage: Bool = true
    var tagline: String = "Live more, scroll less" // Your time, your choice | Choose what matters
    
    var body: some View {
        HStack {
            VStack {
                Text("Focus Totem".uppercased())
                    .font(.custom("Impact", size: 28))
                    .foregroundColor(.blue)
                
                if showTagline {
                    Text(tagline)
                        .font(.subheadline)
                        .foregroundColor(Color(.darkGray))
                        .fontWeight(.medium)
                }
            }
            
            if showImage {
                Image("FocusTotemMascot")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 60)
            }
        }
    }
}

struct AppHeader_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Example with both tagline and image
            AppHeader()
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            
            // Example with no tagline
            AppHeader(showTagline: false)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            
            // Example with no image
            AppHeader(showImage: false)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            
            // Example with neither tagline nor image
            AppHeader(showTagline: false, showImage: false)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
        }
        .padding()
    }
}
