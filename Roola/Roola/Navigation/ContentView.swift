//
//  ContentView.swift
//  Roola
//
//  Created by Georgius Kenny Gunawan on 17/10/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var isOnboardingComplete = false
    
    var body: some View {
        OnboardingFlowView(isOnboardingComplete: $isOnboardingComplete)
            .modelContainer(for: User.self)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: User.self, inMemory: true)
}
