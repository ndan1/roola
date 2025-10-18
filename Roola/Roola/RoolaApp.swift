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
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // 2. Add the .modelContainer modifier
        .modelContainer(for: [Clothes.self, User.self], isAutosaveEnabled: true) { result in
            switch result {
            case .success(let container):
                // 3. This is where the seeding happens
                let context = container.mainContext
                DataSeeder.seed(context: context)
            case .failure(let error):
                fatalError("Failed to create model container: \(error.localizedDescription)")
            }
        }
    }
}
