//
//  GradientCircularLoadingComponent.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 10/11/25.
//

import SwiftUI

struct GradientCircularLoader: View {
    @State private var isAnimating = false
    
    var lineWidth: CGFloat = 10
    var size: CGFloat = 80
    
    var body: some View {
        Circle()
            .stroke(
                AngularGradient(
                    gradient: Gradient(colors: [
                        AppColors.primaryPurple.opacity(0.8),
                        AppColors.primaryPurple.opacity(0.4),
                        AppColors.primaryPurple.opacity(0.2)
                    ]),
                    center: .center
                ),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            // Rotate to start from top center
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .frame(width: size, height: size)
            .opacity(0.9)
            .animation(.linear(duration: 1.2).repeatForever(autoreverses: false), value: isAnimating)
            .onAppear { isAnimating = true }
    }
}
