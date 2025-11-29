//
//  RecommendationReadyView.swift
//  Roola
//
//  Created by Lin Dan Christiano on 29/11/25.
//

import SwiftUI
import Lottie

struct RecommendationReadyView: View {
    @State private var animationTrigger = false
    var body: some View {
        ZStack {
            FirstGradientBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                ZStack {
                    LottieView {
                        try await DotLottieFile.named("result-ready")
                    }
                    .configure({ lottieAnimationView in
                        lottieAnimationView.contentMode = .scaleAspectFill
                        lottieAnimationView.shouldRasterizeWhenIdle = true
                    })
                    .playbackMode(.playing(.toProgress(1, loopMode: .playOnce)))
                    .id(animationTrigger)
                }
                .frame(width: UIScreen.main.scale * 200, height: UIScreen.main.scale * 180)
                .padding(.bottom, 8)
            }
            .padding(.bottom, UIScreen.main.bounds.height * 0.2)
            Text("Your size result is ready!")
                .font(.heading22Medium)
                .multilineTextAlignment(.center)
                .foregroundColor(.black)
                .padding(.horizontal, 40)
                .padding(.top, UIScreen.main.bounds.height * 0.15)
        }
    }
}

#Preview {
    RecommendationReadyView()
}
