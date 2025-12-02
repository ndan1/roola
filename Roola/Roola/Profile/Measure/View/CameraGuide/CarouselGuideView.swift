//
//  CarouselGuideView.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 28/11/25.
//

import SwiftUI
import Lottie
import UIKit

struct CarouselGuideView: View {
    // 1. Binding to tell the parent view the user reached the end
    @Binding var isLastPageReached: Bool
    
    @State private var currentStep: GuideCarousel = .pose
    
    // 2. Fixed Enum: Added CaseIterable, Identifiable, and fixed syntax
    enum GuideCarousel: String, CaseIterable, Identifiable {
        case pose = "body_pose"
        case angle = "phone90"
        case tight = "tight_clothes"
        case audio = "audio"

        var id: String { self.rawValue }
    }
    
    var body: some View {
        VStack (spacing: 0){
            // 3. TabView with .page style creates the Carousel
            TabView(selection: $currentStep) {
                ForEach(GuideCarousel.allCases) { step in
                    VStack(spacing: 20) {
                        // Lottie Animation
                        LottieView {
                            try await DotLottieFile.named(step.rawValue)
                        }
                        .configure({ lottieAnimationView in
                            lottieAnimationView.contentMode = .scaleAspectFit
                            lottieAnimationView.shouldRasterizeWhenIdle = true
                        })
                        .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
                    }
                    .tag(step)
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 3)
                    .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .never))
        }
        .onChange(of: currentStep) { oldValue, newValue in
            if newValue == GuideCarousel.allCases.last {
                isLastPageReached = true
                print("✅ Carousel reached the end")
            }
        }
        .onAppear {
            // Active Dot Color
            UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(AppColors.primaryPurple.opacity(0.5))
            // Inactive Dot Color
            UIPageControl.appearance().pageIndicatorTintColor = UIColor(AppColors.primaryWhite)
            
            if currentStep == GuideCarousel.allCases.last {
                isLastPageReached = true
            }
        }
    }
}

// Preview Helper to show how Parent uses it
struct CarouselGuideView_Preview: View {
    @State private var canProceed = false
    
    var body: some View {
        VStack {
            CarouselGuideView(isLastPageReached: $canProceed)
                .frame(height: 600)
            
            Button("Proceed") {
                print("Proceeding...")
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canProceed)
        }
    }
}

#Preview {
    CarouselGuideView_Preview().background(FirstGradientBackground())
}
