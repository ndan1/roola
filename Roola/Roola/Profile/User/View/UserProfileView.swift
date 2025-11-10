//
//  UserProfileView.swift
//  Roola
//

import SwiftUI
import SwiftData
import AVKit

struct UserProfileView: View {
    @Query private var users: [User]
    @StateObject private var viewModel = UserProfileViewModel()
//    @State private var showingEditSheet = false
//    @State private var showingPoseCapture = false // BARU
//    @State private var capturedVideoURL: URL?
    
    var body: some View {
        NavigationView {
            if let user = users.first {
                Form {
                    if let videoURL = viewModel.capturedVideoURL {
                        Section("Captured Pose") {
                            VideoPlayer(player: AVPlayer(url: videoURL))
                                .frame(height: 300)
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
                            viewModel.startCameraFlow()
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(8)
                        .listRowInsets(EdgeInsets())
                        
                        Button("Edit Measurements Manually") {
                            viewModel.showingEditSheet = true
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .navigationTitle("My Profile")
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "person.circle")
                        .font(.system(size: 80))
                        .foregroundColor(.gray)
                    
                    Text("No measurements saved yet")
                        .font(.headline)
                    
                    Button("Scan Body with Camera") {
                        viewModel.startCameraFlow()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    
                    Button("Add Measurements Manually") {
                        viewModel.showingEditSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .navigationTitle("My Profile")
            }
        }
        .sheet(isPresented: $viewModel.showingEditSheet) {
            UserInputView()
        }
        .fullScreenCover(isPresented: $viewModel.showingCameraFlow) {
            CameraFlowContainerView { videoURL, measurements in
                viewModel.handleCaptureComplete(videoURL: videoURL, measurements: measurements)
            }
        }
    }
}

#Preview {
    UserProfileView()
        .modelContainer(for: User.self, inMemory: true)
}
