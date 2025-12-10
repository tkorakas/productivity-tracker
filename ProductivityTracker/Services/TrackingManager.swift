//
//  TrackingManager.swift
//  ProductivityTracker
//
//  Created on 10 December 2025.
//

import Foundation
import SwiftData
import Combine

/// Manages work session tracking
@Observable
class TrackingManager {
    private let modelContext: ModelContext
    
    // Current state
    var currentSession: WorkSession?
    var isTracking: Bool = false {
        didSet {
            onTrackingStateChanged?(isTracking)
        }
    }
    
    // Callback for state changes
    var onTrackingStateChanged: ((Bool) -> Void)?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        // Check for any active sessions on initialization
        checkForActiveSessions()
    }
    
    // MARK: - Session Management
    
    /// Start a new work session
    func startSession() {
        guard !isTracking else {
            print("Session already in progress")
            return
        }
        
        let session = WorkSession(startTime: Date())
        modelContext.insert(session)
        
        currentSession = session
        isTracking = true
        
        try? modelContext.save()
        
        print("Started session")
    }
    
    /// End the current work session
    /// - Parameter interruptionReason: Optional reason for interruption
    func endSession(interruptionReason: String? = nil) {
        guard let session = currentSession else {
            print("No active session to end")
            return
        }
        
        session.endTime = Date()
        session.interruptionReason = interruptionReason
        
        try? modelContext.save()
        
        print("Ended session. Duration: \(session.durationFormatted)")
        
        // Clear current state
        currentSession = nil
        isTracking = false
    }
    
    /// Toggle session on/off
    func toggleSession() {
        if isTracking {
            endSession()
        } else {
            startSession()
        }
    }
    
    // MARK: - Data Fetching
    
    /// Fetch all work sessions
    func fetchAllSessions() -> [WorkSession] {
        let descriptor = FetchDescriptor<WorkSession>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    /// Fetch today's sessions
    func fetchTodaysSessions() -> [WorkSession] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let descriptor = FetchDescriptor<WorkSession>(
            predicate: #Predicate { session in
                session.startTime >= today
            },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    /// Get today's productivity metrics
    func getTodaysMetrics() -> ProductivityMetrics {
        let sessions = fetchTodaysSessions()
        let settings = AppSettings.getOrCreate(in: modelContext)
        
        return ProductivityCalculator.calculate(
            sessions: sessions,
            penaltyMinutes: settings.penaltyPerInterruptionMinutes
        )
    }
    
    // MARK: - Private Helpers
    
    private func checkForActiveSessions() {
        let descriptor = FetchDescriptor<WorkSession>(
            predicate: #Predicate { session in
                session.endTime == nil
            }
        )
        
        if let activeSession = try? modelContext.fetch(descriptor).first {
            currentSession = activeSession
            isTracking = true
            print("Resumed active session")
        }
    }
}
