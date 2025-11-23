//
//  SaveBodySizeModal.swift
//  Roola
//
//  Created by Lin Dan Christiano on 23/11/25.
//

import SwiftUI

struct SaveBodySizeModal: View {
    @Binding var isPresented: Bool
    @Binding var height: Int?
    @Binding var weight: Int?
    var onSave: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // Modal content
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    HStack {
                        Spacer()
                        Text("Body Detail")
                            .font(.heading24Medium)
                            .foregroundColor(.black)
                            .padding(.leading, UIScreen.main.bounds.width * 0.15)
                        Spacer()
                        Button (action: {
                            isPresented = false
                        }){
                            Image(systemName: "x.circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(Color.gray.opacity(0.8), Color.gray.opacity(0.1))
                                .font(.system(size: 32))
                                .padding(.trailing, UIScreen.main.bounds.width * 0.05)
                        }
                    }
                    
                    Text("Fill out your body size detail")
                        .font(.body16Regular)
                        .foregroundColor(Color(hex: "#838383"))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)
                
                // Form fields
                VStack(spacing: 0) {
                    
                    TopMeasurementRow(label: "Height", unit:"cm" ,value: $height)
                    BottomMeasurementRow(label: "Weight", unit:"kg" ,value: $weight)

                }
                
                // Buttons
                HStack(spacing: 12) {
                    Button(action: {
                        if height != nil && weight != nil {
                            onSave()
                            isPresented = false
                        }
                    }) {
                        Text("Save")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                (height != nil && weight != nil) ?
                                AppColors.primaryPurple : Color.gray
                            )
                            .cornerRadius(25)
                    }
                    .disabled(height == nil || weight == nil)
                }
                .padding(.top, 8)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 16)
        }
    }
}

#Preview {
    SaveBodySizeModal(
        isPresented: .constant(true),
        height: .constant(170),
        weight: .constant(65),
        onSave: {}
    )
}
