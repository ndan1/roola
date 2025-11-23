//
//  ContentView.swift
//  Roola
//
//  Created by Georgius Kenny Gunawan on 17/10/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var users: [User]
    @State private var isOnboardingComplete = false
    
    var body: some View {
        Group {
            // Cek User Pertama DAN Cek apakah measurement intinya sudah ada
            if let user = users.first, user.isOnboardingFinished {
                MainTabView()
                    .transition(.opacity)
            } else {
                // Jika user kosong ATAU user ada tapi cuma punya height/weight (belum bust/waist)
                // Tetap stay di OnboardingFlow
                OnboardingFlowView(isOnboardingComplete: $isOnboardingComplete)
            }
        }
        .modelContainer(for: [User.self, MeasurementHistory.self])
    }
}
