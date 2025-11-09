//
//  CameraTutorialView.swift
//  Roola
//
//  Created by Lin Dan Christiano on 08/11/25.
//

import SwiftUI

struct CameraTutorialView: View {
    let onContinue: () -> Void
    
    var body: some View {
        ZStack{
            FirstGradientBackground()
            VStack{
                Text("Do's and Don'ts")
                    .font(.largeTitle)
                    .fontWeight(.medium)
                    .padding(.top, UIScreen.main.bounds.height * 0.1)
            
                VStack {
                    Group {
                        HStack{
                            Image("3DTutorial-1")
                                .resizable()
                                .frame(width: 130, height: 146)
                            Image("3DTutorial-2")
                                .resizable()
                                .frame(width: 130, height: 146)
                        }
                        Text("Fit your entire body in the scan lines")
                    }
                    Group {
                        HStack{
                            Image("3DTutorial-3")
                                .resizable()
                                .frame(width: 130, height: 146)
                            Image("3DTutorial-4")
                                .resizable()
                                .frame(width: 130, height: 146)
                        }
                        Text("Place your phone straight on a table")
                    }
                    Group {
                        HStack{
                            Image("3DTutorial-5")
                                .resizable()
                                .frame(width: 130, height: 146)
                            Image("3DTutorial-6")
                                .resizable()
                                .frame(width: 130, height: 146)
                        }
                        Text("Make sure you have good lighting")
                    }
                    HStack{
                        Image(systemName: "speaker.wave.2.fill")
                            .foregroundStyle(Color(AppColors.primaryPurple))
                        Text("Turn your volume on for better experience")
                            .font(.subheadline)
                    }
                    .padding()
                    Spacer()
                    RoolaButton(buttonTitle: "Continue", buttonColor: AppColors.primaryButton, action: onContinue)
                        .padding(.bottom, UIScreen.main.bounds.height * 0.1)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

#Preview {
    CameraTutorialView(onContinue: {})
}
