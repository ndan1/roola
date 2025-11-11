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
    @State private var isShowingMeasurement = false
    
    var body: some View {
        RoolaButton(
            buttonTitle: "Measure with AI",
            buttonColor: AppColors.primaryPurple,
            action: {
                isShowingMeasurement = true
                print("Measurement Flow")
            }
        )
        .fullScreenCover(isPresented: $isShowingMeasurement) {
            MeasurementFlowView()
        }
    }
}

#Preview {
    ContentView()
}
