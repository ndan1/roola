//
//  RoolaButton.swift
//  Roola
//
//  Created by Georgius Kenny Gunawan on 07/11/25.
//

import SwiftUI

struct RoolaButton: View {
    
    var buttonTitle: String
    var buttonColor: Color
    var action: () -> Void
    
    
    var body: some View {
        Button(action: action) {
            Text(buttonTitle)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .font(.button16Bold)
                .foregroundColor(buttonColor == AppColors.primaryPurple ? AppColors.primaryWhite : AppColors.borderButton)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .overlay {
            if buttonColor != AppColors.primaryPurple {
                Capsule()
                    .stroke(AppColors.borderButton, lineWidth: 1)
            }
        }
        .tint(buttonColor)
    }

}

#Preview {
    RoolaButton(buttonTitle: "Measure with AI", buttonColor: AppColors.primaryPurple, action: { })
    RoolaButton(buttonTitle: "Measure with AI", buttonColor: AppColors.primaryWhite, action: { })
}
