//
//  Settings.swift
//  ProductivityTracker
//
//  Created on 10 December 2025.
//

import Foundation
import SwiftData

@Model
final class AppSettings {
    var id: UUID
    var penaltyPerInterruptionMinutes: Int // Default: 15 minutes
    var enableNotifications: Bool
    var showTimeInMenuBar: Bool
    var lastModified: Date
    
    init(
        id: UUID = UUID(),
        penaltyPerInterruptionMinutes: Int = 15,
        enableNotifications: Bool = true,
        showTimeInMenuBar: Bool = true,
        lastModified: Date = Date()
    ) {
        self.id = id
        self.penaltyPerInterruptionMinutes = penaltyPerInterruptionMinutes
        self.enableNotifications = enableNotifications
        self.showTimeInMenuBar = showTimeInMenuBar
        self.lastModified = lastModified
    }
    
    // Singleton accessor - use this to get/create the settings instance
    static func getOrCreate(in context: ModelContext) -> AppSettings {
        let descriptor = FetchDescriptor<AppSettings>()
        
        if let existingSettings = try? context.fetch(descriptor).first {
            return existingSettings
        } else {
            // Create default settings
            let newSettings = AppSettings()
            context.insert(newSettings)
            return newSettings
        }
    }
}
