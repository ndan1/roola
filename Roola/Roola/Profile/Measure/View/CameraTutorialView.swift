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
        let height = UIScreen.main.bounds.height

        VStack(alignment: .leading, spacing: 0) {
            RoolaHeader(
                title: "Instructions",
                onBack: { dismiss() },
                isLargeTitle: true
            )
//            Spacer()

            VStack {
                ForEach(tutorialSteps) { step in
                    VStack(spacing: 0) {
                        Text(step.title)
                            .font(.body16Regular)
                        
                        HStack(spacing: width * 0.1) {
                            Image(step.image1)
                                .resizable()
                                .frame(width: 102, height: 123)

                            Image(step.image2)
                                .resizable()
                                .frame(width: 102, height: 123)
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
                .padding(.top)

                Spacer()

                Button {
                    isShowPolicy = true
                } label: {
                    Text("Learn more about data policy")
                        .underline()
                        .font(.footnote)
                        .foregroundStyle(Color(AppColors.primaryPurple))
                }
                .padding(.bottom, 8)
                .padding(.top, 20)

                RoolaButton(buttonTitle: "Continue", buttonColor: AppColors.primaryButton, action: onContinue)
                    .padding(.bottom, 15)
            }

        }
        .padding(.horizontal, 16)
        .padding(.top)
        .sheet(isPresented: $isShowPolicy) {
            CameraTermsView(onContinue: onContinue, isShowPolicy: $isShowPolicy)
                .presentationDetents([.fraction(0.5)])
        }
        .background(FirstGradientBackground().ignoresSafeArea())
    }
}

#Preview {
    CameraTutorialView(onContinue: {})
}
