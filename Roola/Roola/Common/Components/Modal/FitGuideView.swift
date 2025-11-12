//
//  FitGuideView.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 11/11/25.
//

import SwiftUI

struct FitGuideView: View {
    @Binding var showFitGuide: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Spacer()
            HStack {
                Spacer()
                Text("Fit guide")
                    .font(.title1_22Medium)
                Spacer()
            }
            .overlay(
                Button(action: {
                    showFitGuide = false
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray)
                        .font(.body16Regular)
                }
                .padding(.trailing, 20),
                alignment: .trailing
            )
            .padding(.top, 16)
            .padding(.bottom, 20)
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    GuideStepView(
                        number: "1",
                        title: "Choose your type of clothes"
                    )
                    
                    GuideStepView(
                        number: "2",
                        title: "Choose your fit preference",
                        subtitle: "Standard is how we think is best for you"
                    )
                    
                    VStack(alignment: .leading, spacing: 12) {
                        GuideStepView(
                            number: "3",
                            title: "Upload screenshot of your product's size chart"
                        )
                        
                        HStack(spacing: 12) {
                            Image("screenshot_guide")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                        .padding(.top, 8)
                    }
                    
                    GuideStepView(
                        number: "4",
                        title: "Find the best size for your outfit"
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .font(.title3_16Medium)
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }
}

#Preview {
    FitGuideView(showFitGuide: .constant(true))
}
