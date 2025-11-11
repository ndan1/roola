//
//  CameraPermissionDeniedView.swift
//  Roola
//
//  Created by Lin Dan Christiano on 08/11/25.
//

import SwiftUI

struct CameraPermissionDeniedView: View {
    let onCancel: () -> Void
    let onOpenSettings: () -> Void
    
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                
                Text("Roola needs access to your camera")
                    .multilineTextAlignment(.center)
                    .font(.title)
                    .fontWeight(.medium)
                
                Text("This feature requires camera access. In iPhone settings, tap Roola and turn on Camera access.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                VStack(spacing: 12) {
                    RoolaButton(buttonTitle: "Open Settings", buttonColor: AppColors.primaryButton, action: onOpenSettings)
                    
                    RoolaButton(buttonTitle: "Cancel", buttonColor: AppColors.primaryWhite, action: onCancel)
                }
                .padding(.bottom, UIScreen.main.bounds.height * 0.1)
            }
            .padding(.top, UIScreen.main.bounds.height * 0.3)
            .padding(.horizontal, 16)
        }.background(SecondGradientBackground().ignoresSafeArea())
    }
}

#Preview {
    CameraPermissionDeniedView(onCancel: {}, onOpenSettings: {})
}
