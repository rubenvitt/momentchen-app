//
//  MomentchenApp.swift
//  Momentchen
//
//  Created by Ruben Vitt on 22.10.25.
//

import SwiftUI
import SwiftData

@main
struct MomentchenApp: App {
    var sharedModelContainer: ModelContainer = {
        // Configure SwiftData with local data models
        // MomentTypeCache: Caches Notion MomentType options (24h TTL)
        // ProjectCache: Caches Notion Project data (24h TTL)
        // LifeAreaCache: Caches Notion LifeArea data (24h TTL)
        // AppConfiguration: Stores Notion credentials and database IDs
        // All other data (Moments) lives in Notion
        let schema = Schema([
            AppConfiguration.self,
            MomentTypeCache.self,
            ProjectCache.self,
            LifeAreaCache.self,
            Item.self,
            ReviewSettings.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Schema mismatch detected - delete old store and create fresh container
            print("⚠️ ModelContainer creation failed, recreating with fresh schema: \(error)")

            // Get the default store URL and delete the old database files
            let storeURL = modelConfiguration.url
            try? FileManager.default.removeItem(at: storeURL)
            try? FileManager.default.removeItem(at: storeURL.deletingPathExtension().appendingPathExtension("sqlite-shm"))
            try? FileManager.default.removeItem(at: storeURL.deletingPathExtension().appendingPathExtension("sqlite-wal"))
            print("🗑️ Deleted old database files at: \(storeURL.path)")

            // Create fresh container with new schema
            do {
                let freshContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
                print("✅ Successfully created fresh ModelContainer")
                return freshContainer
            } catch {
                fatalError("Could not create ModelContainer even after cleanup: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
