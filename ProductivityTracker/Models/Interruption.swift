//
//  Interruption.swift
//  ProductivityTracker
//
//  Created on 10 December 2025.
//

import Foundation
import SwiftData

@Model
final class Interruption {
    var id: UUID
    var startTime: Date
    var endTime: Date?
    var reason: String?
    
    @Relationship(inverse: \WorkSession.interruptions)
    var session: WorkSession?
    
    init(
        id: UUID = UUID(),
        startTime: Date = Date(),
        endTime: Date? = nil,
        reason: String? = nil
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.reason = reason
    }
    
    var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }
    
    var durationFormatted: String {
        let minutes = Int(duration / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
