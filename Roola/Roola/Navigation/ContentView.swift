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
        // CHANGE 2: The .modelContainer(...) modifier was removed from here.
        // It is already provided by RoolaApp. Removing it ensures we use
        // the in-memory container we created in the App file.
        .onAppear {
            checkUserStatus()
        }
    }
    
    private func checkUserStatus() {
        // Since data is wiped on kill, this will always fail on a fresh launch,
        // triggering the Onboarding flow every time.
        if let user = users.first, user.isOnboardingFinished {
            showMainApp = true
        } else {
            showMainApp = false
        }
        isCheckingUser = false
    }
}
