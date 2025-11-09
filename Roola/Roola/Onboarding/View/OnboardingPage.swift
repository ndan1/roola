//
//  OnboardingPage.swift
//  Roola
//
//  Created by Georgius Kenny Gunawan on 07/11/25.
//

import SwiftUI

struct OnboardingPage: View {
    var body: some View {
        VStack{
            Spacer()
            Text("Let's get your fit right")
                .font(.title)
                .bold(true)
                .padding(.bottom, 2)
            Text("Input your measurements and find your match.")
                .font(.callout)
            
            Spacer()
            
            VStack{
                RoolaButton(buttonTitle: "Measure with AI", buttonColor: AppColors.primaryPurple, action: {})
                    .padding(.bottom, 6)
                RoolaButton(buttonTitle: "Input Manually", buttonColor: .white, action: {})
            }
            .padding(.bottom, 25)
        }
        .padding(.horizontal, 20)
        .background(.red)
    }
}

#Preview {
    OnboardingPage()
}
