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
        // Move modifiers OUTSIDE NavigationView to apply to entire view hierarchy
        .sheet(isPresented: $viewModel.showingEditSheet) {
            UserInputView()
        }
        .fullScreenCover(item: $viewModel.cameraFlowStep) { step in
            buildView(for: step, user: users.first)
        }
    }
    
    @ViewBuilder
        private func buildView(for step: CameraFlowStep, user: User?) -> some View {
            switch step {
            case .terms:
                CameraTermsView(onContinue: {
                    viewModel.didFinishTerms()
                })
                
            case .tutorial:
                CameraTutorialView(onContinue: {
                    viewModel.didFinishTutorial()
                })
                
            case .capture:
                BodyPoseCaptureView { videoURL, measurements in
                    viewModel.didFinishCapture(videoURL: videoURL, measurements: measurements)
                    // Jika Anda perlu menyimpan 'measurements' ke 'user', lakukan di sini
                    // atau idealnya, buat fungsi di ViewModel:
                    // viewModel.saveMeasurementsToUser(user, measurements: measurements)
                }
                .edgesIgnoringSafeArea(.all)
                
            case .permissionDenied:
                CameraPermissionDeniedView(
                    onCancel: { viewModel.didCancelPermissionView() },
                    onOpenSettings: { viewModel.openSettings() }
                )
            }
        }
}

#Preview {
    UserProfileView()
        .modelContainer(for: User.self, inMemory: true)
}
