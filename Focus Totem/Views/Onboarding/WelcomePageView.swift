//
//  WelcomePageView.swift
//  Deliberate
//
//  Created by Daniele Spaccapeli on 14/03/25.
//

import SwiftUI

// Keep the existing page view implementations
struct WelcomePageView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Header
            AppHeader(showImage: false)
            
            Spacer()
            
            // Mascot
            Image("DeliBuddy")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
            
            Spacer()
            
            VStack(spacing: 10) {
                Text("Take control of your digital life")
                    .font(.custom("Impact", size: 22))
                    .foregroundColor(Color(.darkGray))
                    .multilineTextAlignment(.center)

                Text("In a world of endless scrolling and notifications, we spend too much time on our devices. Focus Totem helps you reclaim your attention.")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            /*
            // Center the feature list as a unit
            HStack {
                Spacer()
                VStack(alignment: .leading, spacing: 10) {
                    FeatureRow(icon: "clock.arrow.circlepath", text: "Select distracting apps")
                    FeatureRow(icon: "rectangle.and.hand.point.up.left", text: "Place the sticker far away")
                    FeatureRow(icon: "qrcode.viewfinder", text: "Scan to block/unblock the apps")
                    FeatureRow(icon: "brain.head.profile", text: "Focus on what matters")
                    // FeatureRow(icon: "chart.bar", text: "Track your focused time")
                }
                .fixedSize(horizontal: true, vertical: false)
                Spacer()
            }
            .padding(.bottom, 30)
            
            Spacer()
            */
        }
        .padding(.horizontal, 30)
    }
}
