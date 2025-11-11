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
            ContentView()
                .modelContainer(sharedModelContainer)
                .preferredColorScheme(.light)
//            #endif

//            MeasurementResultView(
//                data: MeasurementData(  // Pass dummy for preview
//                    armsLength: 49.21,
//                    chestCircumference: 92,
//                    height: 169,
//                    torsoLength: 54,
//                    waistCircumference: 82
//                ),
//                onDone: {
//                    print("Done tapped")
//                },
//                onBack: {
//                    print("Test")
//                },
//                onInfo: {
//                    print("Modal")
//                }
//            )
        }
    }
}
