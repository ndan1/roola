//
//  NoInternetPage.swift
//  Roola
//
//  Created by Lin Dan Christiano on 13/11/25.
//

import SwiftUI

struct NoInternetPage: View {
    var onRetry: (() -> Void)?
    var body: some View {
        ZStack {
            FirstGradientBackground()
            
            VStack {
                Spacer()
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 96))
                    .foregroundStyle(AppColors.primaryPurple)
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
