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
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        notes: String? = nil
    ) {
        self.id = id
        self.date = date
        self.notes = notes
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
