//
//  TrackingManager.swift
//  ProductivityTracker
//
//  Created on 10 December 2025.
//

import Foundation
import SwiftData
import Combine

/// Manages work session tracking and task management
@Observable
class TrackingManager {
    private let modelContext: ModelContext
    
    // Current state
    var currentSession: WorkSession?
    var currentTask: Task?
    var isTracking: Bool = false
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        // Check for any active sessions on initialization
        checkForActiveSessions()
    }
    
    // MARK: - Session Management
    
    /// Start a new work session
    /// - Parameter task: Optional task to associate with the session
    func startSession(for task: Task? = nil) {
        guard !isTracking else {
            print("Session already in progress")
            return
        }
        
        let session = WorkSession(startTime: Date(), task: task)
        modelContext.insert(session)
        
        currentSession = session
        currentTask = task
        isTracking = true
        
        try? modelContext.save()
        
        print("Started session for task: \(task?.title ?? "Ad-hoc")")
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
        
        // Mark task as completed if no interruption
        if interruptionReason == nil, let task = currentTask {
            task.isCompleted = true
            task.completedAt = Date()
        }
        
        try? modelContext.save()
        
        print("Ended session. Duration: \(session.durationFormatted)")
        
        // Clear current state
        currentSession = nil
        currentTask = nil
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
    
    // MARK: - Task Management
    
    /// Create a new planned task
    func createPlannedTask(title: String, importance: Int? = nil) -> Task {
        let task = Task(
            title: title,
            isPlanned: true,
            estimatedImportance: importance
        )
        
        modelContext.insert(task)
        
        // Associate with today's day plan
        let dayPlan = DayPlan.getOrCreate(for: Date(), in: modelContext)
        task.dayPlan = dayPlan
        
        try? modelContext.save()
        
        return task
    }
    
    /// Create an ad-hoc task
    func createAdHocTask(title: String) -> Task {
        let task = Task(
            title: title,
            isPlanned: false
        )
        
        modelContext.insert(task)
        try? modelContext.save()
        
        return task
    }
    
    /// Delete a task
    func deleteTask(_ task: Task) {
        modelContext.delete(task)
        try? modelContext.save()
    }
    
    // MARK: - Data Fetching
    
    /// Fetch all tasks
    func fetchAllTasks() -> [Task] {
        let descriptor = FetchDescriptor<Task>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    /// Fetch today's tasks
    func fetchTodaysTasks() -> [Task] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate { task in
                task.createdAt >= today
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
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
            currentTask = activeSession.task
            isTracking = true
            print("Resumed active session")
        }
    }
}
