//
//  HomeTab.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 24/10/25.
//

import SwiftUI

// MARK: - Main Tab View untuk Development
struct MainTabView: View {
    
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.white
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView {
//            UserProfileView()
//                .tabItem {
//                    Label("Profile", systemImage: "person.circle.fill")
//                }
            UserProfileView()
                .tabItem {
                    VStack {
                        Image(systemName: "pencil.and.ruler")
                            .font(.system(size: 14))
                        Text("Measurements")
                    }
                }
            
            RecommendationView()
                .tabItem {
                    VStack {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                        Text("Recommendation")
                    }
                }
            
            HistoryView()
                .tabItem {
                    VStack {
                        Image(systemName: "clock.arrow.2.circlepath")
                            .font(.system(size: 14))
                        Text("History")
                    }
                }
        }
        
    }
}

#Preview {
    MainTabView()
}
