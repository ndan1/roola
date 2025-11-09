//
//  CameraTermsView.swift
//  Roola
//
//  Created by Lin Dan Christiano on 06/11/25.
//

import SwiftUI

struct CameraTermsView: View {
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            SecondGradientBackground()
            
            VStack {
                Text("Before you continue")
                    .font(.title)
                    .fontWeight(.medium)
                    .padding(.bottom, 32)
                    .padding(.top, UIScreen.main.bounds.height * 0.25)
                
                VStack (alignment: .leading, spacing: 24){
                    HStack (alignment: .top, spacing: 16){
                        Image(systemName: "viewfinder")
                            .font(.system(size: 20))
                            .frame(width: 20, height: 20)
                            .padding(12)
                            .background(Color(AppColors.primaryPurple))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .foregroundColor(.white)
                        VStack (alignment: .leading){
                        Text("Data Usage")
                            .font(.title2)
                            .fontWeight(.medium)
                            .padding(.bottom, 4)
                        Text("Information from the 3D AI Scanner is only used to measure the body and recommend the best product size. The data will be deleted immediately after the analysis is complete.")
                            .font(.subheadline)
                        }
                        
                    }
                    
                    HStack (alignment: .top, spacing: 16){
                        Image(systemName: "camera")
                            .font(.system(size: 20))
                            .frame(width: 20, height: 20)
                            .padding(12)
                            .background(Color(AppColors.primaryPurple))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .foregroundColor(.white)
                        VStack (alignment: .leading){
                        Text("Camera Access")
                            .font(.title2)
                            .fontWeight(.medium)
                            .padding(.bottom, 4)
                        Text("To calculate your size recommendations based on your body shape. No images or videos are stored or shared.")
                            .font(.subheadline)
                        }
                    }
                }
                Spacer()
                RoolaButton(buttonTitle: "Continue", buttonColor: AppColors.primaryButton, action: onContinue)
                    .padding(.bottom, UIScreen.main.bounds.height * 0.1)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            
        }
        .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    CameraTermsView(onContinue: {})
}
