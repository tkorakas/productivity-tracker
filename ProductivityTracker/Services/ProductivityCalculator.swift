//
//  ProductivityCalculator.swift
//  ProductivityTracker
//
//  Created on 10 December 2025.
//

import Foundation

/// Calculates productivity metrics based on the formula from "The Math of Why You Can't Focus at Work"
/// 
/// Formula:
/// Productivity = FocusedTime / (FocusedTime + Penalty)
/// where Penalty = Interruptions × PenaltyPerInterruption (default: 11 minutes)
struct ProductivityCalculator {
    
    /// The standard recovery time in minutes after an interruption
    static let recoveryTimeMinutes = 5
    
    /// Calculate productivity score for a set of work sessions
    /// - Parameters:
    ///   - sessions: Array of work sessions to analyze
    ///   - penaltyMinutes: Penalty in minutes per interruption (default: 11)
    /// - Returns: ProductivityMetrics containing all calculated values
    static func calculate(
        sessions: [WorkSession],
        penaltyMinutes: Int = ProductivityCalculator.recoveryTimeMinutes
    ) -> ProductivityMetrics {
        
        // Calculate total focused time in minutes
        let totalFocusedSeconds = sessions.reduce(0.0) { total, session in
            total + session.focusedDuration
        }
        let focusedMinutes = totalFocusedSeconds / 60.0
        
        // Count interruptions
        let interruptionCount = sessions.reduce(0) { total, session in
            total + session.interruptions.count
        }
        
        // Calculate total interruption duration
        let totalInterruptionSeconds = sessions.reduce(0.0) { total, session in
            let sessionInterruptionDuration = session.interruptions.reduce(0.0) { $0 + $1.duration }
            return total + sessionInterruptionDuration
        }
        let interruptionDurationMinutes = totalInterruptionSeconds / 60.0
        
        // Calculate penalty
        let penaltyTime = Double(interruptionCount * penaltyMinutes)
        
        // Calculate productivity score (0.0 to 1.0)
        let productivityScore: Double
        if focusedMinutes + penaltyTime > 0 {
            productivityScore = focusedMinutes / (focusedMinutes + penaltyTime)
        } else {
            productivityScore = 0.0
        }
        
        return ProductivityMetrics(
            focusedMinutes: focusedMinutes,
            interruptionCount: interruptionCount,
            interruptionDurationMinutes: interruptionDurationMinutes,
            penaltyMinutes: penaltyTime,
            productivityScore: productivityScore,
            sessionCount: sessions.count
        )
    }
    
    /// Calculate productivity for a specific date
    static func calculateForDate(
        _ date: Date,
        sessions: [WorkSession],
        penaltyMinutes: Int = 15
    ) -> ProductivityMetrics {
        let calendar = Calendar.current
        let filteredSessions = sessions.filter { session in
            calendar.isDate(session.startTime, inSameDayAs: date)
        }
        
        return calculate(sessions: filteredSessions, penaltyMinutes: penaltyMinutes)
    }
    
    /// Calculate weekly average productivity
    static func calculateWeeklyAverage(
        sessions: [WorkSession],
        penaltyMinutes: Int = 15
    ) -> Double {
        let calendar = Calendar.current
        let today = Date()
        
        // Get sessions from the last 7 days
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!
        let weekSessions = sessions.filter { $0.startTime >= weekAgo }
        
        // Group by day
        var dailyScores: [Double] = []
        for dayOffset in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                let daySessions = weekSessions.filter { session in
                    calendar.isDate(session.startTime, inSameDayAs: date)
                }
                if !daySessions.isEmpty {
                    let metrics = calculate(sessions: daySessions, penaltyMinutes: penaltyMinutes)
                    dailyScores.append(metrics.productivityScore)
                }
            }
        }
        
        // Return average or 0 if no data
        return dailyScores.isEmpty ? 0.0 : dailyScores.reduce(0, +) / Double(dailyScores.count)
    }
}

/// Container for calculated productivity metrics
struct ProductivityMetrics {
    let focusedMinutes: Double
    let interruptionCount: Int
    let interruptionDurationMinutes: Double
    let penaltyMinutes: Double
    let productivityScore: Double // 0.0 to 1.0
    let sessionCount: Int
    
    /// Productivity as a percentage (0% to 100%)
    var productivityPercentage: Double {
        return productivityScore * 100.0
    }
    
    /// Formatted focused time (e.g., "2h 30m")
    var focusedTimeFormatted: String {
        formatDuration(minutes: focusedMinutes)
    }
    
    /// Formatted interruption duration (e.g., "15m")
    var interruptionDurationFormatted: String {
        formatDuration(minutes: interruptionDurationMinutes)
    }
    
    private func formatDuration(minutes: Double) -> String {
        let hours = Int(minutes) / 60
        let mins = Int(minutes) % 60
        
        if hours > 0 {
            return "\(hours)h \(mins)m"
        } else {
            return "\(mins)m"
        }
    }
    
    /// Grade letter based on productivity percentage
    var grade: String {
        switch productivityPercentage {
        case 90...100: return "A+"
        case 80..<90: return "A"
        case 70..<80: return "B"
        case 60..<70: return "C"
        case 50..<60: return "D"
        default: return "F"
        }
    }
}
