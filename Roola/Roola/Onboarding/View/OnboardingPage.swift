//
//  OnboardingPage.swift
//  Roola
//
//  Created by Georgius Kenny Gunawan on 07/11/25.
//

import SwiftUI

struct OnboardingPage: View {
    var body: some View {
        ZStack{
            SecondGradientBackground()
            Image("GradientStar")
                .resizable()
                .scaledToFit()
                .padding(.bottom, UIScreen.main.bounds.height * 0.05)
            
            VStack(){
                Text("Let's get your fit right")
                    .font(.title)
                    .fontWeight(.medium)
                    .padding(.top, UIScreen.main.bounds.height * 0.09)
                Text("Input your measurements and find your match.")
                    .font(.callout)

                VStack(){
                    HStack{
                        BodyPartCard(bodyParts: "Chest", bodyPartsImg: "Torso 9")
                        BodyPartCard(bodyParts: "Waist", bodyPartsImg: "Torso 9 2")
                    }
//                    .padding(.bottom , UIScreen.main.bounds.height * 0.03)
                    HStack{
                        BodyPartCard(bodyParts: "Arm Length", bodyPartsImg: "Torso 9 3")
                        BodyPartCard(bodyParts: "Torso Length", bodyPartsImg: "Torso 9 4")
                    }
                }
                
                .background(AppColors.primaryWhite.opacity(0.5))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.grayScale100, lineWidth: 1) 
                )
                .padding(.vertical, UIScreen.main.bounds.height * 0.05)
  
                
                VStack{
                    RoolaButton(buttonTitle: "Measure with AI", buttonColor: AppColors.primaryPurple, action: {})
                        .padding(.bottom, 6)
                    RoolaButton(buttonTitle: "Input Manually", buttonColor: .white, action: {})
                }
                .padding(.bottom, UIScreen.main.bounds.height * 0.088)
                
            }
            .padding(.horizontal, 31)
           
            
        }
    }
}

#Preview {
    OnboardingPage()
}
