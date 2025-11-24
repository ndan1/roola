//
//  FailedState.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 10/11/25.
//

import SwiftUI

struct FailedState: View {
    let label: String
    
    var body: some View {
        VStack(spacing:5){
            Image(systemName: "xmark.circle")
                .font(.system(size: 97))
                .foregroundColor(AppColors.grayScale300)
            
            VStack(spacing: 5) {
                Text("Measurement Failed")
                    .font(.heading28Medium)
                    .foregroundColor(AppColors.grayScale300)
                
                Text(label)
                    .font(.title3_16Medium)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .lineLimit(2)
                    .foregroundColor(AppColors.grayScale300)
            }
        }
    }
}

#Preview {
    FailedState(label: "Oh no! Our system failed to get your measurements")
}
