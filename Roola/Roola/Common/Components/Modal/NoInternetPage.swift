//
//  NoInternetPage.swift
//  Roola
//
//  Created by Lin Dan Christiano on 12/11/25.
//

import SwiftUI

struct NoInternetPage: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 96))
                .foregroundStyle(AppColors.primaryPurple)
            Text("No Internet")
                .font(.heading32Medium)
                .foregroundStyle(Color.red)
            Text("You’re offline. Please check your connection.")
                .multilineTextAlignment(.center)
                .font(.body16Regular)
            Spacer()
            RoolaButton(buttonTitle: "Retry", buttonColor: AppColors.primaryPurple, action: {
            })
        }
        .padding(.horizontal, 32)
    }
}

#Preview {
    NoInternetPage()
}
