//
//  DayPlan.swift
//  ProductivityTracker
//
//  Created on 10 December 2025.
//

import Foundation
import SwiftData

@Model
final class DayPlan {
    var id: UUID
    var date: Date
    var notes: String?
    
    // Relationship: A day plan contains multiple planned tasks
    @Relationship(deleteRule: .nullify, inverse: \Task.dayPlan)
    var plannedTasks: [Task]?
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        notes: String? = nil
    ) {
        self.id = id
        self.date = date
        self.notes = notes
    }
    
    // Computed property: Get all sessions for tasks in this day plan
    var allSessions: [WorkSession] {
        guard let tasks = plannedTasks else { return [] }
        return tasks.flatMap { $0.sessions ?? [] }
    }
    
    // Computed property: Total focused time for the day
    var totalFocusedTime: TimeInterval {
        return allSessions.reduce(0) { $0 + $1.duration }
    }
    
    // Computed property: Number of interruptions for the day
    var interruptionCount: Int {
        return allSessions.filter { $0.wasInterrupted }.count
    }
    
    // Computed property: Number of completed tasks
    var completedTasksCount: Int {
        guard let tasks = plannedTasks else { return 0 }
        return tasks.filter { $0.isCompleted }.count
    }
    
    // Static helper: Get or create a day plan for a specific date
    static func getOrCreate(for date: Date, in context: ModelContext) -> DayPlan {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let descriptor = FetchDescriptor<DayPlan>(
            predicate: #Predicate { plan in
                plan.date >= startOfDay && plan.date < endOfDay
            }
        )
        
        if let existingPlan = try? context.fetch(descriptor).first {
            return existingPlan
        } else {
            let newPlan = DayPlan(date: startOfDay)
            context.insert(newPlan)
            return newPlan
        }
    }
}
