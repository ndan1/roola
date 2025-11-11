//
//  YourBodyMeasureNavbar.swift
//  Roola
//
//  Created by Georgius Kenny Gunawan on 11/11/25.
//

import SwiftUI

struct YourBodyMeasureNavbar: View {
    var title: String
        var backAction: () -> Void
        var infoAction: () -> Void
        
        var body: some View {
            ZStack {
                // LAYER 1: The title (centered by default)
                Text(title)
                    .font(.title)
                    .fontWeight(.medium)
                
                // LAYER 2: The buttons
                HStack {
                    // Back Button
                    Button(action: backAction) {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .foregroundColor(AppColors.primaryPurple)
                            .padding(14)
                            .background(.regularMaterial) // Frosted glass effect
                            .clipShape(Circle())
                    }
                    
                    Spacer() // Pushes buttons to the edges
                    
                    // Info Button
                    Button(action: infoAction) {
                        Image(systemName: "info.circle")
                            .font(.title)
                            // Using .purple, but you can use AppColors.primaryPurple
                            .foregroundColor(AppColors.primaryPurple)
                    }
                }
            }
            .padding(.horizontal) // Padding for the whole bar
            .frame(height: 60) // Gives the bar a consistent height
        }
}

#Preview {
    // This lets you preview your component
    ZStack {
        // A gradient to see the frosted effect
        LinearGradient(
            colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        
        VStack {
            YourBodyMeasureNavbar(
                title: "Your measurements",
                backAction: { print("Back tapped!") },
                infoAction: { print("Info tapped!") }
            )
            Spacer()
        }
    }
}
