//
//  NoInternetModal.swift
//  Roola
//
//  Created by Lin Dan Christiano on 12/11/25.
//

import SwiftUI

struct NoInternetModal: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            VStack {
                HStack {
                    Spacer()
                    Button (action: {
                        dismiss()
                    }){
                        Image(systemName: "x.circle.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.white, Color.gray.opacity(0.4))
                            .font(.system(size: 32))
                            .padding(.vertical, 8)
                    }
                }
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 82))
                    .foregroundStyle(AppColors.primaryPurple)
                Text("Oops, you're offline!")
                    .font(.heading24Medium)
                    .foregroundStyle(Color.red)
                    .padding(.top, 8)
                Text("Reconnect to the internet so we can dive back in.")
                    .multilineTextAlignment(.center)
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.grayScale300)
                    .padding(.vertical, 4)
                
                RoolaButton(buttonTitle: "Retry", buttonColor: AppColors.primaryPurple, action: {
                })
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 40)
        }
//            .padding(.vertical, 16)
    }
}

#Preview {
    NoInternetModal()
}
