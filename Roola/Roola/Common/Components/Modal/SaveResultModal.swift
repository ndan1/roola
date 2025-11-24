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
    @Binding var brandName: String
    @Binding var productLink: String
    var onSave: () -> Void
    
    @State private var showValidationError: Bool = false
    
    private var isProductNameValid: Bool { !productName.trimmingCharacters(in: .whitespaces).isEmpty }
    private var isBrandNameValid: Bool { !brandName.trimmingCharacters(in: .whitespaces).isEmpty }
    
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
                        placeholder: "Product name",
                        isError: showValidationError && !isProductNameValid
                    )
                    .zIndex(showValidationError && !isProductNameValid ? 2 : 0)
                    
                    MiddleSaveInputRow(
                        label: "Brand Name",
                        value: $brandName,
                        placeholder: "Brand name",
                        isError: showValidationError && !isBrandNameValid
                    )
                    .zIndex(showValidationError && !isBrandNameValid ? 1 : 0)
                    
                    BottomSaveInputRow(
                        label: "Item Link",
                        value: $productLink,
                        placeholder: "Optional"
                    )
                    
                    if showValidationError && (!isProductNameValid || !isBrandNameValid) {
                        Text("Please fill in this field")
                            .font(.caption)
                            .foregroundColor(AppColors.errorRed)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 8)
                            .padding(.leading, 16)
                            .transition(.opacity)
                    }
                }
                
                // Buttons
                HStack(spacing: 12) {
                    Button(action: {
                        // Logic saat tombol ditekan
                        showValidationError = true
                                            
                        if isProductNameValid && isBrandNameValid {
                            onSave()
                        }
                    }) {
                        Text("Save")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppColors.primaryPurple)
                            .cornerRadius(25)
                    }
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
                .frame(width: 120, alignment: .leading)
            
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
    var isError: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .frame(width: 120, alignment: .leading)
            
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
                .stroke(isError ? AppColors.errorRed : Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

struct MiddleSaveInputRow: View {
    let label: String
    @Binding var value: String
    let placeholder: String
    var isError: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .frame(width: 120, alignment: .leading)
            
            Spacer()
            
            TextField(placeholder, text: $value)
                .font(.body)
                .multilineTextAlignment(.trailing)
                .frame(width: 200)
        }
        .padding()
        .background(Color.white)
        .overlay(
            Rectangle()
                .stroke(isError ? AppColors.errorRed : Color.gray.opacity(0.2), lineWidth: 1)
                // Trik: Jika tidak error, mungkin kamu mau border bawah/atas saja atau border tipis.
                // Jika user code sebelumnya tidak pakai border di middle, gunakan:
                // .stroke(isError ? AppColors.errorRed : Color.clear, lineWidth: 1)
                // Tapi agar konsisten kotak, lebih baik dikasih border tipis atau stroke clear.
        )
    }
}


#Preview{
    SaveResultModal(isPresented: .constant(true), productName: .constant("Cotton Blouse"), brandName: .constant("Zara"), productLink: .constant(""), onSave: {})
}
