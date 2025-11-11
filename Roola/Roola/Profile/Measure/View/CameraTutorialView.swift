//
//  CameraTutorialView.swift
//  Roola
//
//  Created by Lin Dan Christiano on 08/11/25.
//

import SwiftUI

struct CameraTutorialView: View {
    let onContinue: () -> Void
    @State var isShowPolicy: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GeometryReader { geometry in
            ZStack{
                FirstGradientBackground()
                VStack (alignment: .leading){
                    HStack (spacing: 12){
                        Button (action: {
                            dismiss()
                        }) {
                            Image(systemName: "chevron.backward.circle.fill")
                                .symbolRenderingMode(.palette)
                                .font(.system(size: 38))
                                .foregroundStyle(Color(AppColors.primaryPurple), Color(AppColors.primaryWhite).opacity(0.5))
                        }
                        Text("Instructions")
                            .font(.largeTitle)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, geometry.size.width * 0.01)
                    .padding(.bottom, geometry.size.height * 0.02)
                    
                    VStack {
                        
                        Group {
                            Text("Place your phone straight on a table")
                            HStack (spacing: geometry.size.width * 0.1){
                                Image("3DTutorial-3")
                                    .resizable()
                                    .frame(width: geometry.size.width * 0.25, height: geometry.size.width * 0.33)
                                Image("3DTutorial-4")
                                    .resizable()
                                    .frame(width: geometry.size.width * 0.25, height: geometry.size.width * 0.33)
                            }
                        }
                        
                        Group {
                            Text("Fit your entire body in the scan lines")
                                .padding(.top)
                            HStack (spacing: geometry.size.width * 0.1){
                                Image("3DTutorial-1")
                                    .resizable()
                                    .frame(width: geometry.size.width * 0.25, height: geometry.size.width * 0.33)
                                Image("3DTutorial-2")
                                    .resizable()
                                    .frame(width: geometry.size.width * 0.25, height: geometry.size.width * 0.33)
                            }
                        }
                        
                        Group {
                            Text("Make sure you have good lighting")
                            HStack (spacing: geometry.size.width * 0.1){
                                Image("3DTutorial-5")
                                    .resizable()
                                    .frame(width: geometry.size.width * 0.25, height: geometry.size.width * 0.33)
                                Image("3DTutorial-6")
                                    .resizable()
                                    .frame(width: geometry.size.width * 0.25, height: geometry.size.width * 0.33)
                            }
                        }
                        HStack{
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundStyle(Color(AppColors.primaryPurple))
                            Text("Turn your volume on for better experience")
                                .font(.subheadline)
                        }
                        .padding(.top)
                        Spacer()
                        Button{
                            isShowPolicy = true
                        } label: {
                            Text("Learn more about data policy")
                                .underline()
                                .font(.footnote)
                                .foregroundStyle(Color(AppColors.primaryPurple))
                        }
                        .padding(.bottom, 8)
                        RoolaButton(buttonTitle: "Continue", buttonColor: AppColors.primaryButton, action: onContinue)
                            .padding(.bottom, UIScreen.main.bounds.height * 0.1)
                    }
                    .padding(.bottom, 16)
                }
                .padding(.horizontal, 16)
//                .padding(.top, geometry.size.height * 0.08)
                .sheet(isPresented: $isShowPolicy) {
                    CameraTermsView(onContinue: onContinue, isShowPolicy: $isShowPolicy)
                        .presentationDetents([.fraction(0.5), .fraction(0.51)], selection: .constant(.medium))
                }
            }
        }
    }
}

#Preview {
    CameraTutorialView(onContinue: {})
}
