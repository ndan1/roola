//
//  CarouselGuideView.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 28/11/25.
//

import SwiftUI
import Lottie

struct CarouselGuideView: View {
    // 1. Binding to tell the parent view the user reached the end
    @Binding var isLastPageReached: Bool
    
    @State private var currentStep: GuideCarousel = .audio
    
    // 2. Fixed Enum: Added CaseIterable, Identifiable, and fixed syntax
    enum GuideCarousel: String, CaseIterable, Identifiable {
        case audio = "audio"
        case pose = "body_pose"
        case tight = "tight_clothes"
        case angle = "phone90"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        VStack (spacing: -30){
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
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // 5. Custom Page Control Indicator
            HStack(spacing: 12) {
                ForEach(GuideCarousel.allCases) { step in
                    Circle()
                        .fill(currentStep == step ? AppColors.primaryPurple.opacity(0.6) : AppColors.primaryWhite)
                        .frame(width: 12, height: 12)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: currentStep)
                        .onTapGesture {
                            withAnimation {
                                currentStep = step
                            }
                        }
                }
            }
            .padding(.bottom, 30) // Add spacing from the bottom edge
        }
        .onChange(of: currentStep) { oldValue, newValue in
            if newValue == GuideCarousel.allCases.last {
                isLastPageReached = true
                print("✅ Carousel reached the end")
            }
        }
        .onAppear {
            // Edge case: If there is only 1 item, we are already at the end
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
            .disabled(!canProceed) // Button disabled until carousel finishes
        }
    }
}

#Preview {
    CarouselGuideView_Preview().background(FirstGradientBackground())
}
