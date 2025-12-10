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
    var currentInterruption: Interruption?
    
    var isTracking: Bool = false {
        didSet {
            onTrackingStateChanged?(isTracking)
        }
    }
    
    var isInterrupted: Bool {
        return currentInterruption != nil
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
    
    /// Start an interruption
    func startInterruption(reason: String? = nil) {
        guard let session = currentSession else { return }
        guard currentInterruption == nil else { return }
        
        let interruption = Interruption(startTime: Date(), reason: reason)
        interruption.session = session
        session.interruptions.append(interruption)
        
        currentInterruption = interruption
        
        try? modelContext.save()
    }
    
    /// End the current interruption
    func endInterruption() {
        guard let interruption = currentInterruption else { return }
        
        interruption.endTime = Date()
        currentInterruption = nil
        
        try? modelContext.save()
    }
    
    /// End the current work session
    func endSession() {
        guard let session = currentSession else {
            print("No active session to end")
            return
        }
        
        // If there's an active interruption, end it first
        if currentInterruption != nil {
            endInterruption()
        }
        
        session.endTime = Date()
        
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
            },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        
        if let activeSession = try? modelContext.fetch(descriptor).first {
            currentSession = activeSession
            isTracking = true
            
            // Check for active interruption
            // Since we can't query relationships directly in #Predicate easily for this case,
            // we'll check the loaded session's interruptions
            if let activeInterruption = activeSession.interruptions.first(where: { $0.endTime == nil }) {
                currentInterruption = activeInterruption
            }
            
            print("Resumed active session")
        }
    }
}
