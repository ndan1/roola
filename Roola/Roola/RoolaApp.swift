//
//RoolaApp.swift
//Roola
//
//  Created by Georgius Kenny Gunawan on 17/10/25.

import SwiftUI
import SwiftData

@main
struct RoolaApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Clothes.self, User.self, MeasurementHistory.self])
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
            ContentView()
                .modelContainer(sharedModelContainer)
                .preferredColorScheme(.light)
        }
    }
}
