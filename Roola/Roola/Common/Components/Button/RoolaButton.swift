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
                    .padding(.vertical, 12)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(buttonColor == AppColors.primaryPurple ? .white : .black)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(buttonColor)
        }
}

#Preview {
    RoolaButton(buttonTitle: "Measure with AI", buttonColor: AppColors.primaryPurple, action: { })
}
