//
//  FilterSheet.swift
//  Roola
//
//  Created by Lin Dan Christiano on 25/11/25.
//

import SwiftUI

struct FilterSheet: View {
    @Environment(\.dismiss) var dismiss
    
    // Data yang dilempar dari HistoryView (State Asli)
    @Binding var activeTimeRange: String
    @Binding var activeClothesTypes: Set<String>
    
    // State Lokal (Sementara) untuk edit di dalam sheet
    // Filter baru akan tersimpan ke 'active' hanya jika tombol Apply ditekan
    @State private var tempTimeRange: String
    @State private var tempClothesTypes: Set<String>
    
    // Opsi Data
    let clothesOptions: [(id: String, label: String)] = [
        ("t_shirt", "T-Shirt"),
        ("blouse", "Blouse"),
        ("short_sleeved_shirt", "Short Sleeve"),
        ("long_sleeved_shirt", "Long Sleeve")
    ]
    
    let timeOptions = ["Last 7 days", "Last 30 days", "Last 90 days", "This month"]
    
    // Init untuk mengisi state lokal dengan data yang sedang aktif
    init(activeTimeRange: Binding<String>, activeClothesTypes: Binding<Set<String>>) {
        self._activeTimeRange = activeTimeRange
        self._activeClothesTypes = activeClothesTypes
        
        // Isi nilai awal state sementara
        self._tempTimeRange = State(initialValue: activeTimeRange.wrappedValue)
        self._tempClothesTypes = State(initialValue: activeClothesTypes.wrappedValue)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            // MARK: - Header (Clear - Title - Apply)
            HStack {
                Button(action: {
                    // Logic Clear: Kosongkan semua pilihan
                    tempTimeRange = "All Time" // Atau default lain
                    tempClothesTypes.removeAll()
                }) {
                    Text("Clear")
                        .font(.body)
                        .foregroundColor(AppColors.primaryPurple)
                }
                
                Spacer()
                
                Text("Filters")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    // Logic Apply: Simpan perubahan ke State Asli (Parent)
                    activeTimeRange = tempTimeRange
                    activeClothesTypes = tempClothesTypes
                    dismiss()
                }) {
                    Text("Apply")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.primaryPurple)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // MARK: - Clothes Type Section (Multi Select)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Clothes type")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        VStack(spacing: 0) {
                            ForEach(clothesOptions.indices, id: \.self) { index in
                                let item = clothesOptions[index]
                                let isSelected = tempClothesTypes.contains(item.id)
                                
                                FilterRow(title: item.label, isSelected: isSelected) {
                                    if isSelected {
                                        tempClothesTypes.remove(item.id)
                                    } else {
                                        tempClothesTypes.insert(item.id)
                                    }
                                }
                                
                                // Divider kecuali item terakhir
                                if index < clothesOptions.count - 1 {
                                    Divider()
//                                        .padding(.leading, 16)
                                }
                            }
                        }
                        .background(Color.white) // 1. Pastikan background putih
                        .cornerRadius(12)        // 2. Potong konten agar mengikuti lengkungan
                        .overlay(                // 3. Gambar border DI ATAS konten
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                    
                    // MARK: - Time Range Section (Single Select)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Time range")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        VStack(spacing: 0) {
                            ForEach(timeOptions.indices, id: \.self) { index in
                                let option = timeOptions[index]
                                let isSelected = tempTimeRange == option
                                
                                FilterRow(title: option, isSelected: isSelected) {
                                    // Single select logic
                                    if isSelected {
                                        // Jika diklik lagi, mungkin mau unselect? Atau biarkan saja
                                         tempTimeRange = "All Time" // Uncomment jika ingin bisa unselect
                                    } else {
                                        tempTimeRange = option
                                    }
                                }
                                
                                if index < timeOptions.count - 1 {
                                    Divider()
//                                        .padding(.leading, 16)
                                }
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Reusable Filter Row Component
struct FilterRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Icon Logic: Ungu Checkmark jika selected, Bulat kosong jika tidak
                ZStack {
                    Circle()
                        .stroke(isSelected ? AppColors.primaryPurple : Color.gray.opacity(0.5), lineWidth: 1.5)
                        .frame(width: 16, height: 16)
                    
                    if isSelected {
                        Circle()
                            .fill(AppColors.primaryPurple)
                            .frame(width: 16, height: 16)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview Logic
#Preview {
    FilterSheet(
        activeTimeRange: .constant("Last 7 days"),
        activeClothesTypes: .constant(["t_shirt", "blouse"])
    )
}
