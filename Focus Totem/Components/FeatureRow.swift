//
//  FeatureRow.swift
//  Deliberate
//
//  Created by Daniele Spaccapeli on 13/03/25.
//

import SwiftUI

struct FeatureRow: View {
    var icon: String
    var text: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 30)
            
            Text(text)
                .font(.title3)
                .foregroundColor(.primary)
        }
    }
}
