//
//  HomeTab.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 24/10/25.
//

import SwiftUI

struct MainTabView: View {
//    @State private var selectedTab = 1

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppColors.primaryWhite)
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(AppColors.primaryPurple)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(AppColors.primaryPurple)
        ]
        
        appearance.inlineLayoutAppearance = appearance.stackedLayoutAppearance
        appearance.compactInlineLayoutAppearance = appearance.stackedLayoutAppearance
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().tintColor = UIColor(AppColors.primaryPurple)
    }

    // helper to create a smaller SF symbol as UIImage -> Image
    func smallSymbol(_ name: String, size: CGFloat, weight: UIImage.SymbolWeight = .regular) -> Image {
        let cfg = UIImage.SymbolConfiguration(pointSize: size, weight: weight)
        if let ui = UIImage(systemName: name, withConfiguration: cfg) {
            return Image(uiImage: ui)
        }
        return Image(systemName: name)
    }

    var body: some View {
        TabView(
//            selection: $selectedTab
        ) {
            UserInputView()
                .tabItem {
                    VStack {
                        smallSymbol("pencil.and.ruler", size: 14)
                        Text("Measurements")
                    }
                }
//                .tag(0)

            RecommendationView()
                .tabItem {
                    VStack {
                        smallSymbol("sparkles", size: 14)
                        Text("Recommendation")
                    }
                }
//                .tag(1)

            HistoryView()
                .tabItem {
                    VStack {
                        smallSymbol("clock.arrow.2.circlepath", size: 14)
                        Text("History")
                    }
                }
//                .tag(2)
        }
    }
}

#Preview {
    MainTabView()
}
