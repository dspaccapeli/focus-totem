//
//  ExplanationPageView.swift
//  Focus Totem
//
//  Created on 02/04/25.
//

import SwiftUI

struct ExplanationPageView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Header
            Text("HOW IT WORKS")
                .font(.custom("Impact", size: 22))
                .foregroundColor(Color(.darkGray))
                .fontWeight(.bold)
            
            // Main illustration
            
            HStack (spacing: 10){
                Image("TeapotTotem")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100)
                    .rotationEffect(Angle(degrees: -10))
                
                Image("DoorhandleTotem")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 90)
                    .rotationEffect(Angle(degrees: 10))
            }
            .padding(.vertical, 10)
            
            // Explanation text
            VStack(spacing: 16) {
                Text("A 'totem' is a real world object that blocks apps")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)

                Text("The best totems are objects you use daily, but don't carry with you, for example, a teapot or a door handle.")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 10)
            
            Spacer()
            
            // Step-by-step explanation
            VStack(alignment: .leading, spacing: 15) {
                StepRow(number: "1", title: "Register Your Totem", description: "Take photos of your chosen object from different angles")
                
                StepRow(number: "2", title: "Block Distractions", description: "Scan your totem, away from your workspace, to activate blocking")
                
                StepRow(number: "3", title: "Focus on What Matters", description: "Your apps are blocked until you scan your totem again")
                
                StepRow(number: "4", title: "Unblock When Needed", description: "You will have only a limited number of emergency unblocks")
            }
            .padding(.bottom, 10)
            
            Spacer()
        }
        .padding(.horizontal, 30)
    }
}

struct StepRow: View {
    let number: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            // Step number in circle
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 30, height: 30)
                
                Text(number)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.callout)
                    .bold()
                    .foregroundColor(Color(.darkGray))

                Text(description)
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct ExplanationPageView_Previews: PreviewProvider {
    static var previews: some View {
        ExplanationPageView()
    }
}
