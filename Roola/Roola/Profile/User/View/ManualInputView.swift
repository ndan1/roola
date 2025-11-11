//
//  ManualInputView.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 11/11/25.
//

import SwiftUI
import SwiftData

struct ManualInputView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (User) -> Void
    
    @State private var height = ""
    @State private var bust = ""
    @State private var waist = ""
    @State private var torso = ""
    @State private var armsLength = ""
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Enter Your Measurements")
                .font(.title2)
                .bold()
            
            VStack(spacing: 16) {
                LabeledTextField(label: "Height (cm)", text: $height)
                LabeledTextField(label: "Bust (cm)", text: $bust)
                LabeledTextField(label: "Waist (cm)", text: $waist)
                LabeledTextField(label: "Torso Length (cm)", text: $torso)
                LabeledTextField(label: "Arm Length (cm)", text: $armsLength)
            }
            .padding(.horizontal)
            
            RoolaButton(buttonTitle: "Save & Continue", buttonColor: AppColors.primaryPurple) {
                save()
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top)
        .background(SecondGradientBackground().ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
        }
    }
    
    private func save() {
        guard let h = Int(height), h > 0,
              let b = Int(bust), b > 0,
              let w = Int(waist), w > 0,
              let t = Int(torso), t > 0,
              let a = Int(armsLength), a > 0 else {
            // TODO: show error toast
            return
        }
        
        let user = User(height: h, bust: b, waist: w, torso: t, arms_length: a)
        onSave(user)
    }
}

struct LabeledTextField: View {
    let label: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField("", text: $text)
                .keyboardType(.numberPad)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    ManualInputView(onSave: {_ in })
}
