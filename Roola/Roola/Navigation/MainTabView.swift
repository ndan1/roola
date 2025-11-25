//
//  HomeTab.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 24/10/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 1

    // MainTabView.swift

    init() {
        // 1. Setup TAB BAR (Bagian Bawah)
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(AppColors.primaryWhite)
        tabAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(AppColors.primaryPurple)
        tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(AppColors.primaryPurple)
        ]
        
        tabAppearance.inlineLayoutAppearance = tabAppearance.stackedLayoutAppearance
        tabAppearance.compactInlineLayoutAppearance = tabAppearance.stackedLayoutAppearance
        
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        UITabBar.appearance().tintColor = UIColor(AppColors.primaryPurple)
        
        // 2. Setup NAVIGATION BAR (Bagian Atas - Judul & Tombol)
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground() // Transparan agar gradient background terlihat
        
        // Ganti font ini sesuai dengan font Custom Anda (.heading28Medium dan .body17Semibold)
        // Pastikan nama font ("PlusJakartaSans-Medium" dsb) sesuai dengan Info.plist Anda
        let largeFont = UIFont(name: "HelveticaNeue-Medium", size: 32) ?? UIFont.systemFont(ofSize: 32, weight: .medium)
        let inlineFont = UIFont(name: "HelveticaNeue-Bold", size: 17) ?? UIFont.systemFont(ofSize: 17, weight: .semibold)

        // Styling Title Besar (Saat scroll di atas)
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.black,
            .font: largeFont
        ]
        
        // Styling Title Kecil (Saat scroll ke bawah atau mode inline)
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.black,
            .font: inlineFont
        ]
        
        // Terapkan ke semua kondisi navigasi
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        
        // Warna tombol Toolbar (Info button, Chevron back)
        UINavigationBar.appearance().tintColor = UIColor(AppColors.primaryPurple)
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
            selection: $selectedTab
        ) {
            NavigationStack{
                UserInputView()
            }
            .tabItem {
                VStack {
                    smallSymbol("pencil.and.ruler", size: 14)
                    Text("Measurements")
                }
            }
            .tag(0)
            

            RecommendationView()
                .tabItem {
                    VStack {
                        smallSymbol("sparkles", size: 14)
                        Text("Recommendation")
                    }
                }
                .tag(1)

            HistoryView()
                .tabItem {
                    VStack {
                        smallSymbol("clock.arrow.2.circlepath", size: 14)
                        Text("History")
                    }
                }
                .tag(2)
        }
//        .overlay {
//            <#code#>
//        }
    }
}

#Preview {
    MainTabView()
}
