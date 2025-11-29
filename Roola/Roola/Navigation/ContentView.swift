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
    @State private var showMainApp = false
    @State private var isCheckingUser = true
    
    var body: some View {
        Group {
            if isCheckingUser {
                Color.white.ignoresSafeArea()
            } else if showMainApp {
                MainTabView()
                    .transition(.opacity.animation(.easeInOut(duration: 0.5)))
            } else {
                OnboardingFlowView(isOnboardingComplete: $showMainApp)
                    .transition(.opacity)
            }
        }
        .modelContainer(for: [User.self, MeasurementHistory.self])
        .onAppear {
            checkUserStatus()
        }
    }
    
    private func checkUserStatus() {
        if let user = users.first, user.isOnboardingFinished {
            showMainApp = true
        } else {
            showMainApp = false
        }
        isCheckingUser = false
    }
}
