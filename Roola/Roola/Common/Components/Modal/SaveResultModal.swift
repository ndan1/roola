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
    
    // 1. Batas Karakter
    private let charLimit = 15
        
    // 2. Logic Validasi Terpisah
    // Cek Kosong
    private var isProductEmpty: Bool { productName.trimmingCharacters(in: .whitespaces).isEmpty }
    private var isBrandEmpty: Bool { brandName.trimmingCharacters(in: .whitespaces).isEmpty }
        
    // Cek Kepanjangan
    private var isProductTooLong: Bool { productName.count > charLimit }
    private var isBrandTooLong: Bool { brandName.count > charLimit }
    
    private func isValidUrl(_ url: String) -> Bool {
        let regex = "^(https?://)?(?:www\\.)?([-a-zA-Z0-9@:%._\\+~#=]{1,256}\\.[a-zA-Z0-9()]{1,6})\\b([-a-zA-Z0-9()@:%_\\+.~#?&//=]*)$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return predicate.evaluate(with: url)
    }
    
    private var isLinkInvalid: Bool {
        let trimmedLink = productLink.trimmingCharacters(in: .whitespaces)
        if trimmedLink.isEmpty { return false }
        return !isValidUrl(trimmedLink)
    }
        
    // Validasi Gabungan (Untuk tombol Save)
    private var isFormValid: Bool {
        !isProductEmpty && !isBrandEmpty && !isProductTooLong && !isBrandTooLong && !isLinkInvalid
    }
        
    // 3. Logic Error Message Dinamis
    private var errorMessage: String {
        if isProductTooLong {
            return "Product name max \(charLimit) characters"
        } else if isBrandTooLong {
            return "Brand name max \(charLimit) characters"
        } else {
            return "Please fill out this field"
        }
    }
    
    private var linkErrorMessage: String {
        if isLinkInvalid {
           return "Please enter a valid link"
        } else {
            return ""
        }
    }
        
    // Helper untuk menentukan kapan error ditampilkan
    // Muncul jika: (Tombol save ditekan DAN ada yang kosong) ATAU (Ada yang kepanjangan)
    private var shouldShowError: Bool {
        (showValidationError && (isProductEmpty || isBrandEmpty)) || (isProductTooLong || isBrandTooLong)
    }
    
    private var shouldShowLinkInvalidError: Bool {
        showValidationError && isLinkInvalid
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // Modal content
            VStack(spacing: 16) {
                // Header
                VStack (spacing: 2) {
                    HStack {
//                        Spacer()
                        Text("Product detail")
                            .font(.heading24Medium)
                            .foregroundColor(.black)
                            .padding(.leading, UIScreen.main.bounds.width * 0.23)
                        Spacer()
                        Button (action: {
                            isPresented = false
                        }){
                            Image(systemName: "xmark.circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(Color.gray.opacity(0.8), Color.gray.opacity(0.1))
                                .font(.system(size: 32))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    
                    Text("Fill in product detail below to save to history")
                        .font(.body14Regular)
                        .foregroundColor(Color(hex: "#838383"))
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
                
                // Form fields
                VStack(spacing: 0) {
                    TopSaveInputRow(
                        label: "Product Name",
                        value: $productName,
                        placeholder: "Product name",
                        isError: (showValidationError && isProductEmpty) || isProductTooLong
                    )
                    .zIndex((showValidationError && isProductEmpty) || isProductTooLong ? 1 : 0)
                    
                    MiddleSaveInputRow(
                        label: "Brand Name",
                        value: $brandName,
                        placeholder: "Brand name",
                        isError: (showValidationError && isBrandEmpty) || isBrandTooLong
                    )
                    .zIndex((showValidationError && isBrandEmpty) || isBrandTooLong ? 1 : 0)
                    
                    BottomSaveInputRow(
                        label: "Item Link",
                        value: $productLink,
                        placeholder: "Optional",
                        isError: (showValidationError && isLinkInvalid)
                    )
                    
                    validationError
                    
                }
                
                // Buttons
                RoolaButton(
                    buttonTitle: "Done",
                    buttonColor: AppColors.primaryPurple,
                    action: {
                        showValidationError = true
                                            
                        if isFormValid {
                            onSave()
                        }
                    }
                )
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.85)
            .padding(16)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
            .padding(.horizontal)
        }
    }
}

// Custom TextField Component for String input (no conflict with MeasurementRow.swift)
struct BottomSaveInputRow: View {
    let label: String
    @Binding var value: String
    let placeholder: String
    var isError: Bool = false
    
    var body: some View {
        HStack {
            HStack (spacing: 4){
                Text(label)
                    .font(.body)
                if isError {
                    Image(systemName: "exclamationmark.circle")
                        .font(.body16Regular)
                        .foregroundColor(AppColors.errorRed)
                }
            }
            .frame(width: 140, alignment: .leading)
            
            Spacer()
            
            TextField(placeholder, text: $value)
                .font(.body)
                .multilineTextAlignment(.trailing)
                .frame(width: 160)
        }
        .frame(maxWidth: UIScreen.main.bounds.width * 0.75)
        .padding()
        .background(Color.white)
        .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
        .overlay(
            RoundedCorner(radius: 12, corners: [.bottomLeft, .bottomRight])
                .stroke(isError ? AppColors.errorRed : Color.gray.opacity(0.2), lineWidth: 1)
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
            HStack (spacing: 4){
                Text(label)
                    .font(.body)
                if isError {
                    Image(systemName: "exclamationmark.circle")
                        .font(.body16Regular)
                        .foregroundColor(AppColors.errorRed)
                }
            }
            .frame(width: 140, alignment: .leading)
            
            Spacer()
            
            TextField(placeholder, text: $value)
                .font(.body)
                .multilineTextAlignment(.trailing)
                .frame(width: 160)
        }
        .frame(maxWidth: UIScreen.main.bounds.width * 0.75)
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
            HStack (spacing: 4){
                Text(label)
                    .font(.body)
                if isError {
                    Image(systemName: "exclamationmark.circle")
                        .font(.body16Regular)
                        .foregroundColor(AppColors.errorRed)
                }
            }
            .frame(width: 140, alignment: .leading)
            
            Spacer()
            
            TextField(placeholder, text: $value)
                .font(.body)
                .multilineTextAlignment(.trailing)
                .frame(width: 160)
        }
        .frame(maxWidth: UIScreen.main.bounds.width * 0.75)
        .padding()
        .background(Color.white)
        .overlay(
            Rectangle()
                .stroke(isError ? AppColors.errorRed : Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

private extension SaveResultModal {
    var validationError: some View {
        VStack (alignment: .leading, spacing: 0) {
            if shouldShowError {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(AppColors.errorRed)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
                    .transition(.opacity)
            }
            
            if shouldShowLinkInvalidError {
                Text(linkErrorMessage)
                    .font(.caption)
                    .foregroundColor(AppColors.errorRed)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 32, alignment: .top)
    }
}


#Preview{
    SaveResultModal(isPresented: .constant(true), productName: .constant("Cotton Blouse"), brandName: .constant("Zara"), productLink: .constant(""), onSave: {})
}
