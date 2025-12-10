//
//  WorkSession.swift
//  ProductivityTracker
//
//  Created on 10 December 2025.
//

import Foundation
import SwiftData

@Model
final class WorkSession {
    var id: UUID
    var startTime: Date
    var endTime: Date?
    var interruptionReason: String?
    
    init(
        id: UUID = UUID(),
        startTime: Date = Date(),
        endTime: Date? = nil,
        interruptionReason: String? = nil
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.interruptionReason = interruptionReason
    }
    
    // Computed property: Duration in seconds
    var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }
    
    // Computed property: Duration formatted as string
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
    
    // Computed property: Is this session currently active?
    var isActive: Bool {
        return endTime == nil
    }
    
    // Computed property: Was this session interrupted?
    var wasInterrupted: Bool {
        return interruptionReason != nil
    }
}
