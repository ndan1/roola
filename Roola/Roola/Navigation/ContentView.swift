//
//  ContentView.swift
//  Roola
//
//  Created by Georgius Kenny Gunawan on 17/10/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    // 1. Add a @State variable to track presentation
//    @State private var isShowingMeasurement = false
    
//    var body: some View {
//        ZStack {
//            // A gradient to see the frosted effect
//            FirstGradientBackground()
//            VStack {
//                RoolaHeader(
//                    title: "Your measurements",
//                    onBack: { print("Back tapped!") },
//                    onInfo: { print("Info tapped!") }
//                )
//            }
//            
//            RoolaButton(
//                buttonTitle: "Measure with AI",
//                buttonColor: AppColors.primaryPurple,
//                action: {
//                    isShowingMeasurement = true
//                    print("Measurement Flow")
//                }
//            )
//            .fullScreenCover(isPresented: $isShowingMeasurement) {
//                MeasurementFlowView()
//            }
//        }
//    }
    var body: some View {
        CameraFlowContainerView()
    }
}

#Preview {
    ContentView()
}
