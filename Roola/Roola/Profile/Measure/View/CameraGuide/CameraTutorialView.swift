//
//  CameraTutorialView.swift
//  Roola
//
//  Created by Lin Dan Christiano on 08/11/25.
//

import SwiftUI

struct CameraTutorialView: View {
    let onContinue: () -> Void
    @State var isShowPolicy: Bool = false
    @Environment(\.dismiss) private var dismiss

    // 1. Create a data model for the tutorial steps
    private struct TutorialStep: Identifiable {
        let id = UUID()
        let title: String
        let image1: String
        let image2: String
    }

    // 2. Create the data source for the loop
    private let tutorialSteps: [TutorialStep] = [
        .init(title: "Place your phone straight on a table", image1: "3DTutorial-3", image2: "3DTutorial-4"),
        .init(title: "Fit your entire body in the scan lines", image1: "3DTutorial-1", image2: "3DTutorial-2"),
        .init(title: "Make sure you have good lighting", image1: "3DTutorial-5", image2: "3DTutorial-6")
    ]

    var body: some View {
        let width = UIScreen.main.bounds.width

        VStack(alignment: .center, spacing: 0) {
            
                VStack (alignment: .center, spacing: width * 0.01) {
                    ScrollView {
                    ForEach(tutorialSteps) { step in
                        VStack(alignment:.leading, spacing: 5) {
                            Text(step.title)
                                .font(.body16Regular)
                            
                            HStack(spacing: width * 0.125) {
                                Image(step.image1)
                                    .resizable()
                                    .frame(width: 112, height: 133)
                                
                                Image(step.image2)
                                    .resizable()
                                    .frame(width: 112, height: 133)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    
                    HStack {
                        Image(systemName: "speaker.wave.2.fill")
                            .foregroundStyle(Color(AppColors.primaryPurple))
                        Text("Turn your volume on for better experience")
                            .font(.subheadline)
                    }
                    
                    Spacer(minLength: 30)
                    
                    Button {
                        isShowPolicy = true
                    } label: {
                        Text("Learn more about data policy")
                            .underline()
                            .font(.footnote)
                            .foregroundStyle(Color(AppColors.primaryPurple))
                    }
                    .padding(.bottom, 8)
                    
                    VStack{
                        RoolaButton(buttonTitle: "Continue",
                                    buttonColor: AppColors.primaryButton,
                                    action: onContinue)
                        .frame(width: UIScreen.main.bounds.width * 0.8)
                        .padding(.bottom, 15)
                    }
                }
            }
                .padding(.top, 10)
        }
        .sheet(isPresented: $isShowPolicy) {
            CameraTermsView(onContinue: onContinue, isShowPolicy: $isShowPolicy)
                .presentationDetents([.fraction(0.5)])
                .presentationDragIndicator(.visible)
        }
        .background(FirstGradientBackground().ignoresSafeArea())
                
        // MARK: - SETUP NAVIGATION BAR
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline) // Agar font besar seperti RoolaHeader
        .navigationBarBackButtonHidden(true)   // Sembunyikan back button biru default
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                // 2. Gabungkan Tombol Back & Judul dalam HStack
                HStack(spacing: 12) {
                    
                    // Tombol Back (Chevron)
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 24)
                            .foregroundColor(AppColors.primaryWhite)
                            .background(
                                Circle()
                                    .fill(AppColors.primaryPurple)
                                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                            )
                    }
                    
                    // Teks Judul (Disamping Chevron)
                    Text("Instructions")
                        .font(.heading28Medium) // Font custom permintaanmu
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: true, vertical: false) // Agar teks tidak terpotong
                }
                // Tambahkan padding negatif sedikit di kiri jika terasa terlalu menjorok ke dalam (opsional)
                // .padding(.leading, -8)
            }
        }
    }
}

#Preview {
    CameraTutorialView(onContinue: {})
}
