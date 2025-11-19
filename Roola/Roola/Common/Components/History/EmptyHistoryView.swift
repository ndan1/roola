//
//  EmptyHistoryView.swift
//  Roola
//
//  Created by Lin Dan Christiano on 19/11/25.
//

import SwiftUI

struct EmptyHistoryView: View {
    var body: some View {
        VStack {
            Spacer()
                .frame(height: UIScreen.main.bounds.height * 0.15)
            VStack(spacing: 64) {
                Spacer()
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 65))
                    .foregroundColor(AppColors.primaryPurple)
                    .background(
                        Circle()
                            .fill(Color.purple.opacity(0.1))
                            .frame(width: 120, height: 120)
                    )
                
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text("Start inputing your desire outfit and \nget recommendations")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .padding(.leading, 30)
                    
                    VStack(spacing: 16) {
                        InstructionRow(icon: "sparkles", text: "Fill in your measurements manually or use our AI")
                        InstructionRow(icon: "sparkles", text: "Fill in your product details to get your best match")
                    }
                    .padding(.horizontal, 26)
                    
                    Spacer()
                }
            }
        }
    }
}
