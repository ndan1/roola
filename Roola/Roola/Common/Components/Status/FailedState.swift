//
//  FailedState.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 10/11/25.
//

import SwiftUI
import Lottie

struct FailedState: View {
    let label: String
    @State private var animationTrigger = false
    
    var body: some View {
        ZStack {
            FirstGradientBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                ZStack {
                    LottieView {
                        try await DotLottieFile.named("measurement-failed")
                    }
                    .configure({ lottieAnimationView in
                        lottieAnimationView.contentMode = .scaleAspectFill
                        lottieAnimationView.shouldRasterizeWhenIdle = true
                    })
                    .playbackMode(.playing(.toProgress(1, loopMode: .playOnce)))
                    .id(animationTrigger)
                }
                .frame(width: UIScreen.main.scale * 125, height: UIScreen.main.scale * 100)
                .padding(.bottom, 8)
            }
            .padding(.bottom, UIScreen.main.bounds.height * 0.2)
            VStack(spacing: 5) {
                Text("Measurement Failed")
                    .font(.heading28Medium)
                    .foregroundColor(AppColors.grayScale300)
                
                Text(label)
                    .font(.title3_16Medium)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .lineLimit(2)
                    .foregroundColor(AppColors.grayScale300)
            }
            .padding(.top, 72)
        }
    }
}

#Preview {
    FailedState(label: "Oh no! Our system failed to get your measurements")
}
