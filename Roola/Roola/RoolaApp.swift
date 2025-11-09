//
//RoolaApp.swift
//Roola
//
//  Created by Georgius Kenny Gunawan on 17/10/25.

import SwiftUI
import SwiftData
import Supabase

let supabase = SupabaseClient(
    supabaseURL: SupabaseConfig.url,
    supabaseKey: SupabaseConfig.anonKey
)

@main
struct RoolaApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Clothes.self, User.self])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            let context = container.mainContext
            
            return container
        } catch {
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
//            #if DEBUG
//            if CommandLine.arguments.contains("-testing-product-input") {
//                UserProfileView()
//                    .modelContainer(sharedModelContainer)
//            } else {
//                MainTabView()
//                    .modelContainer(sharedModelContainer)
//            }
//            #else
//            ContentView()
//                .modelContainer(sharedModelContainer)
//            #endif
            AIMeasurementFlowView()
        }
    }
}
