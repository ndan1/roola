//
//  YourBodyMeasureNavbar.swift
//  Roola
//
//  Created by Georgius Kenny Gunawan on 11/11/25.
//

import SwiftUI

struct RoolaHeader: View {
    var title: String
    var onBack: (() -> Void)?
    var onInfo: (() -> Void)?
    
    var isLargeTitle: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 20) {
                if onBack != nil {
                    Button(action: onBack ?? { }) {
                        Image(systemName: "chevron.left.circle.fill")
                            .resizable()
                            .frame(width: 32, height: 32)
                            .foregroundColor(AppColors.primaryWhite)
                            .background(
                                Circle()
                                    .fill(AppColors.primaryPurple)
                                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                            )
                    }
                }

                Text(title)
                    .font(isLargeTitle ? .heading32Medium : .heading24Medium)
                    .lineLimit(1)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if onInfo != nil {
                    Button(action: onInfo ?? { }) {
                        Image(systemName: "info.circle")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(AppColors.primaryPurple)
                    }
                }else{
                    Spacer()
                }
            }
            .padding()
            .padding(.horizontal, 10)
        }
    }
}

#Preview {
    VStack {
        RoolaHeader(
            title: "Your measurements",
            onBack: { print("Back tapped!") },
            onInfo: { print("Info tapped!") }
        )
        RoolaHeader(
            title: "Instrunstions",
            onBack: { print("Back tapped!") }
        )
        RoolaHeader(
            title: "Your measurements",
            onInfo: { print("Info tapped!") }
        )
        RoolaHeader(
            title: "Your measurements",
            onBack: { print("Back tapped!") },
            onInfo: { print("Info tapped!") },
            isLargeTitle: true
        )
        RoolaHeader(
            title: "Instrunstions",
            onBack: { print("Back tapped!") },
            isLargeTitle: true
        )
        RoolaHeader(
            title: "Your measurements",
            onInfo: { print("Info tapped!") },
            isLargeTitle: true
        )
        Spacer()
    }.background(FirstGradientBackground().ignoresSafeArea())
}
