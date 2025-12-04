//
//  RoolaApp.swift
//  Roola
//
//  Created by Georgius Kenny Gunawan on 17/10/25.
//

import SwiftUI
import SwiftData

@main
struct RoolaApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Clothes.self,
            User.self,
            MeasurementHistory.self
        ])
        
        // CHANGE 1: Set this to true so data is not saved to disk
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            return container
        } catch {
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                // This injects the in-memory container into the whole app
                .modelContainer(sharedModelContainer)
                .preferredColorScheme(.light)
        }
    }
}
