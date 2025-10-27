//
//  SizeDataReviewView.swift
//  Roola
//
//  Created by Lin Dan Christiano on 23/10/25.
//

import SwiftUI

struct SizeDataReviewView: View {
    let sizeData: [SizeData]
    let onConfirm: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var editableSizes: [EditableSizeData] = []
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Extracted Size Data")) {
                    ForEach($editableSizes) { $size in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(size.sizeName)
                                .font(.headline)
                            
                            HStack {
                                Text("Bust:")
                                Spacer()
                                TextField("0", value: $size.bust, format: .number)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 60)
                                Text("cm")
                            }
                            
                            HStack {
                                Text("Length:")
                                Spacer()
                                TextField("0", value: $size.length, format: .number)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 60)
                                Text("cm")
                            }
                        }
                    }
                }
                
                Section {
                    Button("Confirm & Save") {
                        saveToDatabase()
                        onConfirm()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
                    .listRowInsets(EdgeInsets())
                }
            }
            .navigationTitle("Review Size Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Convert SizeData to EditableSizeData
                editableSizes = sizeData.map { EditableSizeData(from: $0) }
            }
        }
    }
    
    private func saveToDatabase() {
        // TODO: Save to Supabase
        print("💾 Saving sizes to database:")
        for size in editableSizes {
            print("  \(size.sizeName): Bust=\(size.bust ?? 0), Length=\(size.length ?? 0)")
        }
    }
}

struct EditableSizeData: Identifiable {
    let id = UUID()
    var sizeName: String
    var bust: Int?
    var length: Int?
    var waist: Int?
    var hips: Int?
    var inseam: Int?
    
    init(from sizeData: SizeData) {
        self.sizeName = sizeData.sizeName
        self.bust = sizeData.bust
        self.length = sizeData.length
        self.waist = sizeData.waist
        self.hips = sizeData.hips
        self.inseam = sizeData.inseam
    }
}

#Preview {
    SizeDataReviewView(sizeData: [
        SizeData(sizeName: "S", bust: 86, length: 58, waist: nil, hips: nil, inseam: nil),
        SizeData(sizeName: "M", bust: 92, length: 60, waist: nil, hips: nil, inseam: nil),
        SizeData(sizeName: "L", bust: 98, length: 62, waist: nil, hips: nil, inseam: nil)
    ]) {
        print("Confirmed!")
    }
}
