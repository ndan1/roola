//
//  OnboardingPage.swift
//  Roola
//
//  Created by Georgius Kenny Gunawan on 07/11/25.
//

import SwiftUI

struct OnboardingPage: View {
    var onAI: (() -> Void)
    var onInput: (() -> Void)
    
    var body: some View {
        VStack(alignment: .leading){
            Text("Let's get your fit right")
                .font(.heading28Medium)
                .padding(.top, UIScreen.main.bounds.height * 0.065)
            Text("Input your measurements and find your match.")
                .font(.body15Regular)
                .multilineTextAlignment(.leading)
                .lineLimit(1)

            ZStack{
                Image("GradientStar")
                    .resizable()
                    .scaledToFit()
                    .padding(.bottom, UIScreen.main.bounds.height * 0.05)
                VStack(){
                    HStack{
                        BodyPartCard(bodyParts: "Chest", bodyPartsImg: "Torso 9")
                        BodyPartCard(bodyParts: "Waist", bodyPartsImg: "Torso 9 2")
                    }
                    HStack{
                        BodyPartCard(bodyParts: "Arm Length", bodyPartsImg: "Torso 9 3")
                        BodyPartCard(bodyParts: "Torso Length", bodyPartsImg: "Torso 9 4")
                    }
                }
            }
            .background(AppColors.primaryWhite.opacity(0.5))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.grayScale100, lineWidth: 1)
            )
            .padding(.vertical, UIScreen.main.bounds.height * 0.02)

            
            VStack{
                RoolaButton(
                    buttonTitle: "Measure with AI",
                    buttonColor: AppColors.primaryPurple,
                    action: {
                        onAI()
                })
                    .padding(.bottom, 6)
                RoolaButton(
                    buttonTitle: "Input Manually",
                    buttonColor: AppColors.primaryWhite,
                    action: {
                        onInput()
                })
            }
            .padding(.bottom, UIScreen.main.bounds.height * 0.088)
            
        }
        .padding(.horizontal, 31)
        .background(SecondGradientBackground().ignoresSafeArea())
    }
}

#Preview {
    OnboardingPage(onAI: {print("AI")}, onInput: {print("Manual")})
}
