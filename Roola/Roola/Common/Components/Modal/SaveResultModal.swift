//
//  SaveResultModal.swift
//  Roola
//
//  Created by System on 11/11/25.
//

import SwiftUI

struct SaveResultModal: View {
    @Binding var isPresented: Bool
    @Binding var productName: String
    @Binding var shopName: String
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
                        Text("Product Detail")
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
                    
                    Text("Fill in product detail below to save to history")
                        .font(.body16Regular)
                        .foregroundColor(Color(hex: "#838383"))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)
                
                // Form fields
                VStack(spacing: 0) {
                    TopSaveInputRow(
                        label: "Product Name",
                        value: $productName,
                        placeholder: "Product name"
                    )
                    
                    BottomSaveInputRow(
                        label: "Shop Name",
                        value: $shopName,
                        placeholder: "Shop name"
                    )
                }
                
                // Buttons
                HStack(spacing: 12) {
//                    Button(action: {
//                        isPresented = false
//                    }) {
//                        Text("Cancel")
//                            .fontWeight(.semibold)
//                            .foregroundColor(AppColors.primaryPurple)
//                            .frame(maxWidth: .infinity)
//                            .padding(.vertical, 14)
//                            .background(Color.white)
//                            .cornerRadius(25)
//                            .overlay(
//                                RoundedRectangle(cornerRadius: 25)
//                                    .stroke(AppColors.primaryPurple, lineWidth: 1.5)
//                            )
//                    }
                    
                    Button(action: {
                        if !productName.trimmingCharacters(in: .whitespaces).isEmpty &&
                           !shopName.trimmingCharacters(in: .whitespaces).isEmpty {
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
                                (!productName.trimmingCharacters(in: .whitespaces).isEmpty &&
                                 !shopName.trimmingCharacters(in: .whitespaces).isEmpty) ?
                                AppColors.primaryPurple : Color.gray
                            )
                            .cornerRadius(25)
                    }
                    .disabled(productName.trimmingCharacters(in: .whitespaces).isEmpty ||
                              shopName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.top, 8)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
        }
    }
}

// Custom TextField Component for String input (no conflict with MeasurementRow.swift)
struct BottomSaveInputRow: View {
    let label: String
    @Binding var value: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.body)
            
            Spacer()
            
            TextField(placeholder, text: $value)
                .font(.body)
                .multilineTextAlignment(.trailing)
                .frame(width: 200)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
        .overlay(
            RoundedCorner(radius: 12, corners: [.bottomLeft, .bottomRight])
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

struct TopSaveInputRow: View {
    let label: String
    @Binding var value: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .frame(width: 120)
            
            Spacer()
            
            TextField(placeholder, text: $value)
                .font(.body)
                .multilineTextAlignment(.trailing)
                .frame(width: 200)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12, corners: [.topLeft, .topRight])
        .overlay(
            RoundedCorner(radius: 12, corners: [.topLeft, .topRight])
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview{
    SaveResultModal(isPresented: .constant(true), productName: .constant("Cotton Blouse"), shopName: .constant("Zara"), onSave: {})
}
