//
//  UserProfileView.swift
//  Roola
//
//  Created by Lin Dan Christiano on 23/10/25.
//

import SwiftUI
import SwiftData

struct UserProfileView: View {
    @Query private var users: [User]
    @State private var showingEditSheet = false
    
    var body: some View {
        NavigationView {
            if let user = users.first {
                Form {
                    Section("Basic Information") {
                        LabeledContent("Height", value: "\(user.height) cm")
                        LabeledContent("Weight", value: "\(user.weight) kg")
                        LabeledContent("Age", value: "\(user.age) years")
                    }
                    
                    Section("Body Measurements") {
                        LabeledContent("Bust", value: "\(user.bust) cm")
                        LabeledContent("Waist", value: "\(user.waist) cm")
                        LabeledContent("Hips", value: "\(user.hips) cm")
                        LabeledContent("Shoulder Width", value: "\(user.shoulder_width) cm")
                        LabeledContent("Torso Length", value: "\(user.torso) cm")
                        LabeledContent("Arms Length", value: "\(user.arms_length) cm")
                    }
                    
                    Section {
                        Button("Edit Measurements") {
                            showingEditSheet = true
                        }
                    }
                }
                .navigationTitle("My Profile")
                .sheet(isPresented: $showingEditSheet) {
                    UserInputView()
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "person.circle")
                        .font(.system(size: 80))
                        .foregroundColor(.gray)
                    
                    Text("No measurements saved yet")
                        .font(.headline)
                    
                    Button("Add Measurements") {
                        showingEditSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .navigationTitle("My Profile")
                .sheet(isPresented: $showingEditSheet) {
                    UserInputView()
                }
            }
        }
    }
}

#Preview {
    UserProfileView()
        .modelContainer(for: User.self, inMemory: true)
}
