//
//  ProductivityTrackerApp.swift
//  ProductivityTracker
//
//  Created on 10 December 2025.
//

import SwiftUI
import SwiftData

@main
struct ProductivityTrackerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // Shared ModelContainer for access in AppDelegate
    static let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            WorkSession.self,
            AppSettings.self,
            DayPlan.self,
            Interruption.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        // Empty Settings scene - menu bar app doesn't need a main window scene
        Settings {
            EmptyView()
        }
        .modelContainer(Self.sharedModelContainer)
    }
}
