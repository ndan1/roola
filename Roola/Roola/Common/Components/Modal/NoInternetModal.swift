//
//  NoInternetModal.swift
//  Roola
//
//  Created by Lin Dan Christiano on 13/11/25.
//

import SwiftUI
import Lottie

struct NoInternetModal: View {
    @Binding var isPresented: Bool
    var onRetry: (() -> Void)?
    @State private var animationTrigger = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack (spacing: 4){
                HStack {
                    Spacer()
                    Button (action: {
                        isPresented = false
                    }){
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.white, Color.gray.opacity(0.4))
                            .font(.system(size: 32))
                    }
                }
                LottieView {
                    try await DotLottieFile.named("no-internet")
                }
                .configure({ lottieAnimationView in
                    lottieAnimationView.contentMode = .scaleAspectFill
                    lottieAnimationView.shouldRasterizeWhenIdle = true
                })
                .playbackMode(.playing(.toProgress(1, loopMode: .playOnce)))
                .id(animationTrigger)
                Text("Oops, you're offline!")
                    .font(.heading24Medium)
                    .foregroundStyle(Color.red)
                    .padding(.top, 8)
                Text("Reconnect to the internet so we can dive back in.")
                    .multilineTextAlignment(.center)
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.grayScale300)
                    .padding(.vertical, 4)
                
                RoolaButton(buttonTitle: "Retry", buttonColor: AppColors.primaryPurple, action: {
                    isPresented = false
                    onRetry?()
                })
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 40)
        }
    }
}

#Preview {
    NoInternetModal(isPresented: .constant(true))
}
