//
//  SwiftDataSchema.swift
//  ProductivityTracker
//
//  Created on 10 December 2025.
//

import Foundation
import SwiftData

/// Extension to provide convenient access to the SwiftData schema
extension Schema {
    /// The main schema for the ProductivityTracker app
    static var productivityTrackerSchema: Schema {
        Schema([
            Task.self,
            WorkSession.self,
            AppSettings.self,
            DayPlan.self
        ])
    }
}

/// Extension to provide convenient ModelContainer setup
extension ModelContainer {
    /// Create a ModelContainer for ProductivityTracker
    /// - Parameter inMemory: Whether to store data in memory only (useful for testing)
    /// - Returns: A configured ModelContainer
    static func productivityTracker(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema.productivityTrackerSchema
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )
        
        return try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }
}
