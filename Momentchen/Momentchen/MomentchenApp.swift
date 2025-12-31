//
//  MomentchenApp.swift
//  Momentchen
//
//  Created by Ruben Vitt on 22.10.25.
//

import SwiftUI
import SwiftData
import AppIntents

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

            // Get the default store URL and delete ALL related files
            let storeURL = modelConfiguration.url
            let storeDirectory = storeURL.deletingLastPathComponent()
            let storeName = storeURL.deletingPathExtension().lastPathComponent

            // Delete all files related to this database
            if let files = try? FileManager.default.contentsOfDirectory(at: storeDirectory, includingPropertiesForKeys: nil) {
                for file in files {
                    if file.lastPathComponent.hasPrefix(storeName) {
                        try? FileManager.default.removeItem(at: file)
                        print("🗑️ Deleted: \(file.lastPathComponent)")
                    }
                }
            }

            print("🗑️ Deleted old database files at: \(storeURL.path)")

            // Create completely fresh configuration with new URL to avoid any caching
            let freshConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )

            // Create fresh container with new schema
            do {
                let freshContainer = try ModelContainer(for: schema, configurations: [freshConfig])
                print("✅ Successfully created fresh ModelContainer")
                return freshContainer
            } catch {
                // If it still fails, print detailed error and crash
                print("❌ FATAL: Could not create ModelContainer even after cleanup")
                print("Error details: \(error)")
                if let swiftDataError = error as? SwiftDataError {
                    print("SwiftData error: \(swiftDataError)")
                }
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
