//
//  OCRErrorModal.swift
//  Roola
//
//  Created by Lin Dan Christiano on 11/11/25.
//

import SwiftUI

struct OCRErrorModal: View {
    let error: OCRError
    let onRetry: () -> Void
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                Text(error.title)
                    .font(.heading24Medium)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                
                Text(error.message)
                    .font(.body16Regular)
                    .foregroundColor(Color(hex: "838383"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                
                RoolaButton(
                    buttonTitle: "Retry",
                    buttonColor: AppColors.primaryPurple,
                    action: {
                        isPresented = false
                        onRetry()
                    }
                )
                .padding(.horizontal, 24)
            }
            .padding(.vertical, 24)
            .frame(maxWidth: UIScreen.main.bounds.width * 0.85)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        Button("Show Not Upperwear Error") {
            // Preview action
        }
        .padding()
    }
    .sheet(isPresented: .constant(true)) {
        OCRErrorModal(
            error: .notUpperwear,
            onRetry: { print("Retry tapped") },
            isPresented: .constant(true)
        )
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
