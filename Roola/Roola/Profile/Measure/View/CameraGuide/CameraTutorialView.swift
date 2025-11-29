//
//  CameraTutorialView.swift
//  Roola
//
//  Created by Lin Dan Christiano on 08/11/25.
//

import SwiftUI

struct CameraTutorialView: View {
    let onContinue: () -> Void
    @Binding var showBodySizeModal: Bool
    @State private var canProceed = false
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
            if showBodySizeModal {
                HStack(spacing: 20) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 32)
                            .foregroundColor(AppColors.primaryWhite)
                            .background(
                                Circle()
                                    .fill(AppColors.primaryPurple)
                                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                                    .overlay(
                                        Circle()
                                            .stroke(AppColors.primaryPurple, lineWidth: 1)
                                    )
                            )
                            .padding(.leading, 6)
                    }
                    Text("Instructions")
                        .font(.heading28Medium)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: true, vertical: false)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 5)
            }
            VStack (alignment: .center, spacing: width * 0.01) {
                ScrollView {
                    CarouselGuideView(isLastPageReached: $canProceed)
                        .frame(height: 600)
                    
                    Button {
                        isShowPolicy = true
                    } label: {
                        Text("Learn more about data policy")
                            .underline()
                            .font(.body16Regular)
                            .foregroundStyle(Color(AppColors.primaryPurple))
                    }
                    .padding(.bottom, 8)
                    
                    VStack{
                        if canProceed{
                            RoolaButton(buttonTitle: "Continue",
                                        buttonColor: AppColors.primaryButton,
                                        action: onContinue)
                            .frame(width: UIScreen.main.bounds.width * 0.8)
                            .padding(.bottom, 15)
                        }
                    }
                }
            }
            .padding(.top, 5)
        }
        .sheet(isPresented: $isShowPolicy) {
            CameraTermsView(onContinue: onContinue, isShowPolicy: $isShowPolicy)
                .presentationDetents([.fraction(0.5)])
                .presentationDragIndicator(.visible)
        }
        .background(FirstGradientBackground().ignoresSafeArea())
                
        // MARK: - SETUP NAVIGATION BAR
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                // 2. Gabungkan Tombol Back & Judul dalam HStack
                HStack(spacing: 12) {
                    
                    // Tombol Back (Chevron)
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 32)
                            .foregroundColor(AppColors.primaryWhite)
                            .background(
                                Circle()
                                    .fill(AppColors.primaryPurple)
                                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                                    .overlay(
                                        Circle()
                                            .stroke(AppColors.primaryPurple, lineWidth: 1)
                                    )
                            )
                            .padding(.leading, 6)
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
    CameraTutorialView(onContinue: {}, showBodySizeModal: .constant(false))
}
