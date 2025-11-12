//
//  InstructionRow.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 12/11/25.
//

import SwiftUI

struct InstructionRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColors.primaryPurple)
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .foregroundColor(AppColors.primaryWhite)
                    .font(.system(size: 18))
            }
            
            Text(text)
                .font(.body)
                .foregroundColor(AppColors.primaryBlack)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}

#Preview {
    InstructionRow(icon: "sparkle.circle", text: "String")
}
