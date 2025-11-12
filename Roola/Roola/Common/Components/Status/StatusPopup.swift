//
//  StatusPopup.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 11/11/25.
//

import SwiftUI

struct SuccessPopupView: View {
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(AppColors.primaryPurple)
            
            Text("Measurements saved")
                .font(.title3_16Medium)
                .foregroundColor(.primary)
        }
        .padding(24)
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(width: 300, height: 200)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppColors.primaryWhite)
                .shadow(radius: 12)
        )
        .onTapGesture { onDismiss() }
        .transition(.opacity)
    }
}

#Preview {
    SuccessPopupView(onDismiss: { })
}
