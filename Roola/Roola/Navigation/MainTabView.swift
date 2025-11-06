//
//  HomeTab.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 24/10/25.
//

import SwiftUI

// MARK: - Main Tab View untuk Development
struct MainTabView: View {
    var body: some View {
        TabView {
            UserProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
            RecommendationView()
                .tabItem {
                    Label("ocr/cal", systemImage: "house.fill")
                }
        }
    }
}
