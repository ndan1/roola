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
                .padding(.vertical, UIScreen.main.bounds.height * 0.01)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(buttonColor == AppColors.primaryPurple ? .white : .black)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .overlay {
            if buttonColor != AppColors.primaryPurple {
                Capsule()
                    .stroke(Color.gray, lineWidth: 2)
            }
        }
        .tint(buttonColor)
    }

}

#Preview {
    RoolaButton(buttonTitle: "Measure with AI", buttonColor: AppColors.primaryWhite, action: { })
}
