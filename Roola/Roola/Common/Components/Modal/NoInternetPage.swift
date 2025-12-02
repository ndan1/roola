//
//  NoInternetPage.swift
//  Roola
//
//  Created by Lin Dan Christiano on 13/11/25.
//

import SwiftUI
import Lottie

struct NoInternetPage: View {
    var onRetry: (() -> Void)?
    @State private var animationTrigger = false
    
    var body: some View {
        ZStack {
            FirstGradientBackground()
            
            VStack {
                Spacer()
                LottieView {
                    try await DotLottieFile.named("no-internet")
                }
                .configure({ lottieAnimationView in
                    lottieAnimationView.contentMode = .scaleAspectFill
                    lottieAnimationView.shouldRasterizeWhenIdle = true
                })
                .playbackMode(.playing(.toProgress(1, loopMode: .playOnce)))
                .id(animationTrigger)
                Text("No Internet")
                    .font(.heading28Medium)
                    .foregroundStyle(Color.red)
                Text("You're offline. Please check your connection.")
                    .multilineTextAlignment(.center)
                    .font(.body16Regular)
                Spacer()
                RoolaButton(buttonTitle: "Retry", buttonColor: AppColors.primaryPurple, action: {
                    onRetry?()
                })
                .padding(.bottom, UIScreen.main.bounds.height * 0.05)
            }
            .padding(.horizontal, 32)
        }
    }
}

#Preview {
    NoInternetPage()
}
