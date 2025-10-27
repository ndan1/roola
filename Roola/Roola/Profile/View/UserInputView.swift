//
//  UserInputView.swift
//  Roola
//

import SwiftUI
import SwiftData

struct UserInputView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query private var existingUsers: [User]
    
    @State private var height: Int = 0
    @State private var weight: Int = 0
    @State private var age: Int = 0
    @State private var bust: Int = 0
    @State private var waist: Int = 0
    @State private var hips: Int = 0
    @State private var shoulderWidth: Int = 0
    @State private var torso: Int = 0
    @State private var armsLength: Int = 0
    
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Basic Information")) {
                    HStack {
                        Text("Height (cm)")
                        Spacer()
                        TextField("0", value: $height, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Weight (kg)")
                        Spacer()
                        TextField("0", value: $weight, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Age (years)")
                        Spacer()
                        TextField("0", value: $age, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section(header: Text("Body Measurements (cm)")) {
                    HStack {
                        Text("Bust")
                        Spacer()
                        TextField("0", value: $bust, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Waist")
                        Spacer()
                        TextField("0", value: $waist, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Hips")
                        Spacer()
                        TextField("0", value: $hips, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Shoulder Width")
                        Spacer()
                        TextField("0", value: $shoulderWidth, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Torso Length")
                        Spacer()
                        TextField("0", value: $torso, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Arms Length")
                        Spacer()
                        TextField("0", value: $armsLength, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section {
                    Button("Save Measurements") {
                        saveUserData()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
                    .listRowInsets(EdgeInsets())
                }
            }
            .navigationTitle("Body Measurements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK") {
                    if alertTitle == "Success" {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                loadExistingUserData()
            }
        }
    }
    
    private func loadExistingUserData() {
        if let existingUser = existingUsers.first {
            height = existingUser.height
            weight = existingUser.weight
            age = existingUser.age
            bust = existingUser.bust
            waist = existingUser.waist
            hips = existingUser.hips
            shoulderWidth = existingUser.shoulder_width
            torso = existingUser.torso
            armsLength = existingUser.arms_length
            
            print("📥 Loaded existing user data")
        } else {
            print("📝 No existing user, will create new")
        }
    }
    
    private func saveUserData() {
        guard height > 0,
              weight > 0,
              age > 0,
              bust > 0,
              waist > 0,
              hips > 0,
              shoulderWidth > 0,
              torso > 0,
              armsLength > 0 else {
            
            alertTitle = "Input Error"
            alertMessage = "Please enter valid measurements for all fields (must be greater than 0)"
            showingAlert = true
            return
        }
        
        if let existingUser = existingUsers.first {
            // UPDATE existing user
            existingUser.height = height
            existingUser.weight = weight
            existingUser.age = age
            existingUser.bust = bust
            existingUser.waist = waist
            existingUser.hips = hips
            existingUser.shoulder_width = shoulderWidth
            existingUser.torso = torso
            existingUser.arms_length = armsLength
            
            print("✏️ Updated existing user")
        } else {
            let newUser = User(
                height: height,
                weight: weight,
                age: age,
                bust: bust,
                waist: waist,
                hips: hips,
                shoulder_width: shoulderWidth,
                torso: torso,
                arms_length: armsLength
            )
            
            modelContext.insert(newUser)
            print("Created new user")
        }
        
        do {
            try modelContext.save()
            
            alertTitle = "Success"
            alertMessage = "Your measurements have been saved successfully!"
            showingAlert = true
            
            print("✅ User data saved successfully:")
            print("   Height: \(height) cm")
            print("   Weight: \(weight) kg")
            print("   Age: \(age) years")
            print("   Bust: \(bust) cm")
            print("   Waist: \(waist) cm")
            print("   Hips: \(hips) cm")
            print("   Shoulder Width: \(shoulderWidth) cm")
            print("   Torso Length: \(torso) cm")
            print("   Arms Length: \(armsLength) cm")
            
        } catch {
            alertTitle = "Error"
            alertMessage = "Failed to save data: \(error.localizedDescription)"
            showingAlert = true
            print("❌ Failed to save user data: \(error)")
        }
    }
}

#Preview {
    UserInputView()
        .modelContainer(for: User.self, inMemory: true)
}
