//
//  CameraTermsView.swift
//  Roola
//
//  Created by Lin Dan Christiano on 06/11/25.
//

import SwiftUI

struct CameraTermsView: View {
    let onContinue: () -> Void
    @Binding var isShowPolicy: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Spacer()
                    Text("Data Policy")
                        .font(.title)
                        .fontWeight(.medium)
                        .padding(.leading, UIScreen.main.bounds.width * 0.15)
                    Spacer()
                    Button (action: {
                        dismiss()
                    }){
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.gray.opacity(0.8), Color.gray.opacity(0.1))
                            .font(.system(size: 32))
                            .padding(.trailing, UIScreen.main.bounds.width * 0.05)
                    }
                }
                .padding(.bottom, 24)
                
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
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            
        }
        .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    CameraTermsView(onContinue: {}, isShowPolicy: .constant(true))
}
