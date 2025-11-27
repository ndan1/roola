//
//  MeasureGuideModal.swift
//  Roola
//
//  Created by Georgius Kenny Gunawan on 11/11/25.
//

import SwiftUI

struct MeasureGuideModal: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack{
            Spacer()
            HStack{
                Spacer()
                Text("Details")
                    .font(.heading24Medium)
                Spacer()
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.gray.opacity(0.8), Color.gray.opacity(0.1))
                        .font(.system(size: 32))
                }
                
            }
            .padding(.top, UIScreen.main.bounds.height * 0.03)
            .padding(.horizontal, UIScreen.main.bounds.height * 0.03)
            
            InfoRow(imageName: "Torso 9", title: "Chest", description: "Measure around the widest part of your chest, just under your arms.")
            Divider()
                .frame(height: 1.2)
                .overlay(AppColors.grayScale200)
            InfoRow(imageName: "Torso 9 2", title: "Waist", description: "Around the slimmest part of your upper body, above the belly button.")
            Divider()
                .frame(height: 1.2)
                .overlay(AppColors.grayScale200)
            InfoRow(imageName: "Torso 9 3", title: "Arm length", description: "Measure from shoulder to wrist, along the outside of your arm.")
            Divider()
                .frame(height: 1.2)
                .overlay(AppColors.grayScale200)
            InfoRow(imageName: "Torso 9 4", title: "Torso length", description: "Measure the length of your body from shoulder to hip.")
        }
    }
}

#Preview {
    MeasureGuideModal()
}

struct InfoRow: View {
    var imageName: String
    var title: String
    var description: String
    
    var body: some View {
        HStack {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: UIScreen.main.bounds.width * 0.34)
//                .offset(x: imageName == "Torso 9 3" ? (UIScreen.main.bounds.width * 0.00) : (UIScreen.main.bounds.width * 0.05))
//                .padding(.trailing, 10)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.title2_20Medium)
                
                Text(description)
                    .foregroundStyle(AppColors.grayScale400)
                    .lineSpacing(1.5)
                    .font(.body16Regular)
                    .padding(.trailing)
            }
        }
    }
}
