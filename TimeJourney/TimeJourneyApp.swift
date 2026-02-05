//
//  TimeJourneyApp.swift
//  TimeJourney
//
//  Created by 张峰 on 2025/12/25.
//

import SwiftUI
import SwiftData

@main
struct TimeJourneyApp: App {
    var sharedModelContainer: ModelContainer = TimeJourneyApp.makeModelContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

private extension TimeJourneyApp {
    static func makeModelContainer() -> ModelContainer {
        let schema = Schema([
            Item.self,
            PlaceItem.self,
            ContentItem.self,
            RouteItem.self,
            RoutePoint.self,
            RouteWaypoint.self,
            GroupItem.self,
            GroupPlaceLink.self,
            GroupRouteLink.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            #if DEBUG
            print("SwiftData store load failed: \(error). Attempting reset.")
            resetStoreFiles(at: modelConfiguration.url)
            if let container = try? ModelContainer(for: schema, configurations: [modelConfiguration]) {
                return container
            }
            let inMemory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return (try? ModelContainer(for: schema, configurations: [inMemory])) ?? {
                fatalError("Could not create ModelContainer after reset: \(error)")
            }()
            #else
            fatalError("Could not create ModelContainer: \(error)")
            #endif
        }
    }

    static func resetStoreFiles(at url: URL) {
        let fileManager = FileManager.default
        let storePath = url.path
        let candidates = [
            url,
            URL(fileURLWithPath: storePath + "-shm"),
            URL(fileURLWithPath: storePath + "-wal")
        ]

        for candidate in candidates {
            if fileManager.fileExists(atPath: candidate.path) {
                try? fileManager.removeItem(at: candidate)
            }
        }
    }
}
