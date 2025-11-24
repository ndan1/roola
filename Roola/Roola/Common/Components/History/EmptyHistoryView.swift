//
//  EmptyHistoryView.swift
//  Roola
//
//  Created by Lin Dan Christiano on 19/11/25.
//

import SwiftUI
import Lottie

struct EmptyHistoryView: View {
    @State private var animationTrigger = false

    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 64) {
                Spacer()
                    .frame(height: UIScreen.main.bounds.height * 0.1)
                LottieView {
                    try await DotLottieFile.named("hanger")
                }
                .configure({ lottieAnimationView in
                    lottieAnimationView.contentMode = .scaleAspectFill
                    lottieAnimationView.shouldRasterizeWhenIdle = true
                })
                .playbackMode(.playing(.toProgress(1, loopMode: .playOnce)))
                .id(animationTrigger)
                
                .padding(.top, -92)
            
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text("Start inputing your desire outfit and \nget recommendations")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .padding(.leading, 30)
                    
                    VStack(spacing: 16) {
                        InstructionRow(icon: "sparkles", text: "Fill in your measurements manually or use our AI")
                        InstructionRow(icon: "sparkles", text: "Fill in your product details to get your best match")
                    }
                    .padding(.horizontal, 26)
                    
                    Spacer()
                }
                .padding(.top, -192)
            }
        }
        .onAppear {
            animationTrigger.toggle()
        }
    }
}

#Preview {
    EmptyHistoryView()
}
