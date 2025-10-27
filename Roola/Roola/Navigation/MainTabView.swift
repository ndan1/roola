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
            ProductInputView()
                .tabItem {
                    Label("Find Size", systemImage: "magnifyingglass.circle.fill")
                }
            
            UserProfileView()
                            .tabItem {
                                Label("Profile", systemImage: "person.circle.fill")
                            }
            
            ContentView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            TestView()
                .tabItem {
                    Label("Calcs", systemImage: "house.fill")
                }
        }
    }
}
