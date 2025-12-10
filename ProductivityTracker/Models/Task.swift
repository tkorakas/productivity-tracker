//
//  Task.swift
//  ProductivityTracker
//
//  Created on 10 December 2025.
//

import Foundation
import SwiftData

@Model
final class Task {
    var id: UUID
    var title: String
    var createdAt: Date
    var isPlanned: Bool
    var estimatedImportance: Int? // Optional importance rating (1-5)
    var isCompleted: Bool
    var completedAt: Date?
    
    // Relationship: A task can have many work sessions
    @Relationship(deleteRule: .cascade, inverse: \WorkSession.task)
    var sessions: [WorkSession]?
    
    // Relationship: A task can belong to a day plan
    var dayPlan: DayPlan?
    
    init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date = Date(),
        isPlanned: Bool = false,
        estimatedImportance: Int? = nil,
        isCompleted: Bool = false,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.isPlanned = isPlanned
        self.estimatedImportance = estimatedImportance
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }
    
    // Computed property: Total focused time for this task
    var totalFocusedTime: TimeInterval {
        guard let sessions = sessions else { return 0 }
        return sessions.reduce(0) { total, session in
            total + session.duration
        }
    }
    
    // Computed property: Number of interruptions
    var interruptionCount: Int {
        guard let sessions = sessions else { return 0 }
        return sessions.filter { $0.interruptionReason != nil }.count
    }
}
