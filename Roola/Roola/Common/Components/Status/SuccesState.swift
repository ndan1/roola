//
//  SuccesState.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 10/11/25.
//

import SwiftUI

struct SuccesState: View {
    let label: String
    
    var body: some View {
        Image(systemName: "checkmark.circle.fill")
            .resizable()
            .frame(width: 100, height: 100)
            .foregroundStyle(AppColors.primaryPurple)
        Text(label)
            .font(.title1_22Medium)
            .padding(.top, 10)
            .lineLimit(2)
            .multilineTextAlignment(.center)
    }
}

#Preview {
    SuccesState(label: "Your measurement result is ready")
}
