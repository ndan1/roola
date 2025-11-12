//
//  SaveSuccessModal.swift
//  Roola
//
//  Created by Lin Dan Christiano on 12/11/25.
//

import SwiftUI

struct SaveSuccessModal: View {
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            // Success card
            VStack(spacing: 20) {
                // Checkmark icon
                ZStack {
                    Image(systemName: "checkmark.circle.fill")
                        .symbolRenderingMode(.palette)
                        .font(.system(size: 72))
                        .foregroundStyle(Color(AppColors.primaryWhite), Color(AppColors.primaryPurple))
                }
                
                // Success message
                Text("Measurement Saved")
                    .font(.body18Medium)
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
    SaveSuccessModal()
}
