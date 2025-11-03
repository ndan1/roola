//
//  UserProfileView.swift
//  Roola
//

import SwiftUI
import SwiftData

struct UserProfileView: View {
    @Query private var users: [User]
    @State private var showingEditSheet = false
    @State private var showingPoseCapture = false // BARU
    @State private var capturedImage: UIImage? // BARU
    
    var body: some View {
        NavigationView {
            if let user = users.first {
                Form {
                    if let image = capturedImage {
                        Section("Captured Pose") {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 300)
                        }
                    }
                    
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
                        Button("Scan Body with Camera") {
                            showingPoseCapture = true
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(8)
                        .listRowInsets(EdgeInsets())
                        
                        Button("Edit Measurements Manually") {
                            showingEditSheet = true
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .navigationTitle("My Profile")
                .sheet(isPresented: $showingEditSheet) {
                    UserInputView()
                }
                .fullScreenCover(isPresented: $showingPoseCapture) {
                    BodyPoseCaptureView { image, measurements in
                        capturedImage = image
                        print("Captured! Arm span: \(measurements.armSpan)")
                        showingPoseCapture = false
                    }
                    .edgesIgnoringSafeArea(.all)
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "person.circle")
                        .font(.system(size: 80))
                        .foregroundColor(.gray)
                    
                    Text("No measurements saved yet")
                        .font(.headline)
                    
                    // BARU
                    Button("Scan Body with Camera") {
                        showingPoseCapture = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    
                    Button("Add Measurements Manually") {
                        showingEditSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .navigationTitle("My Profile")
                .sheet(isPresented: $showingEditSheet) {
                    UserInputView()
                }
                .fullScreenCover(isPresented: $showingPoseCapture) {
                    BodyPoseCaptureView { image, measurements in
                        capturedImage = image
                        showingPoseCapture = false
                    }
                    .edgesIgnoringSafeArea(.all)
                }
            }
        }
    }
}

#Preview {
    UserProfileView()
        .modelContainer(for: User.self, inMemory: true)
}
