//
//  MenuBarView.swift
//  ProductivityTracker
//
//  Created on 10 December 2025.
//

import SwiftUI
import SwiftData

struct MenuBarView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var trackingManager: TrackingManager
    @State private var showingTaskPicker = false
    @State private var showingInterruptionDialog = false
    @State private var interruptionReason = ""
    
    @Query(sort: \Task.createdAt, order: .reverse) private var tasks: [Task]
    
    init(trackingManager: TrackingManager) {
        _trackingManager = State(initialValue: trackingManager)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            headerSection
            
            Divider()
            
            // Current Status
            statusSection
            
            Divider()
            
            // Today's Metrics
            metricsSection
            
            Divider()
            
            // Quick Actions
            actionsSection
        }
        .padding()
        .frame(width: 360)
        .sheet(isPresented: $showingTaskPicker) {
            TaskPickerView(trackingManager: trackingManager)
        }
        .sheet(isPresented: $showingInterruptionDialog) {
            InterruptionReasonView(
                interruptionReason: $interruptionReason,
                onSubmit: {
                    trackingManager.endSession(interruptionReason: interruptionReason.isEmpty ? nil : interruptionReason)
                    showingInterruptionDialog = false
                    interruptionReason = ""
                }
            )
        }
    }
    
    private var headerSection: some View {
        HStack {
            Image(systemName: "clock.fill")
                .font(.title2)
                .foregroundStyle(.blue)
            
            Text("Productivity Tracker")
                .font(.headline)
            
            Spacer()
            
            Button(action: openDashboard) {
                Image(systemName: "chart.bar.fill")
                    .font(.title3)
            }
            .buttonStyle(.plain)
        }
    }
    
    private var statusSection: some View {
        VStack(spacing: 8) {
            if trackingManager.isTracking {
                HStack {
                    Circle()
                        .fill(.green)
                        .frame(width: 12, height: 12)
                    
                    Text("Tracking")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                if let task = trackingManager.currentTask {
                    Text(task.title)
                        .font(.title3)
                        .fontWeight(.semibold)
                } else {
                    Text("Ad-hoc Session")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                
                if let session = trackingManager.currentSession {
                    Text(session.durationFormatted)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                HStack {
                    Circle()
                        .fill(.gray)
                        .frame(width: 12, height: 12)
                    
                    Text("Idle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    private var metricsSection: some View {
        let metrics = trackingManager.getTodaysMetrics()
        
        return VStack(alignment: .leading, spacing: 8) {
            Text("Today's Progress")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            HStack {
                MetricCard(
                    icon: "clock.fill",
                    label: "Focused",
                    value: metrics.focusedTimeFormatted
                )
                
                MetricCard(
                    icon: "exclamationmark.triangle.fill",
                    label: "Interruptions",
                    value: "\(metrics.interruptionCount)"
                )
                
                MetricCard(
                    icon: "chart.line.uptrend.xyaxis",
                    label: "Score",
                    value: "\(Int(metrics.productivityPercentage))%"
                )
            }
        }
    }
    
    private var actionsSection: some View {
        VStack(spacing: 8) {
            // Start/Stop Button
            Button(action: toggleSession) {
                HStack {
                    Image(systemName: trackingManager.isTracking ? "stop.fill" : "play.fill")
                    Text(trackingManager.isTracking ? "Stop Session" : "Start Session")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(trackingManager.isTracking ? .red : .green)
            
            // Quick Task Button
            if !trackingManager.isTracking {
                Button(action: { showingTaskPicker = true }) {
                    HStack {
                        Image(systemName: "list.bullet")
                        Text("Select Task")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
            }
            
            // Keyboard Shortcut Hint
            Text("Press ⌥⌃Space to toggle")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
    
    private func toggleSession() {
        if trackingManager.isTracking {
            showingInterruptionDialog = true
        } else {
            trackingManager.startSession()
        }
    }
    
    private func openDashboard() {
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.showDashboard()
        }
    }
}

// MARK: - Supporting Views

struct MetricCard: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
            
            Text(value)
                .font(.headline)
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct TaskPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Task.createdAt, order: .reverse) private var tasks: [Task]
    
    let trackingManager: TrackingManager
    @State private var newTaskTitle = ""
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Select or Create Task")
                .font(.headline)
            
            // New Task Input
            HStack {
                TextField("New task...", text: $newTaskTitle)
                    .textFieldStyle(.roundedBorder)
                
                Button("Create") {
                    let task = trackingManager.createAdHocTask(title: newTaskTitle)
                    trackingManager.startSession(for: task)
                    dismiss()
                }
                .disabled(newTaskTitle.isEmpty)
            }
            
            Divider()
            
            // Existing Tasks
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(todaysTasks) { task in
                        Button(action: {
                            trackingManager.startSession(for: task)
                            dismiss()
                        }) {
                            HStack {
                                Text(task.title)
                                Spacer()
                                if task.isPlanned {
                                    Image(systemName: "calendar")
                                        .foregroundStyle(.blue)
                                }
                            }
                            .padding()
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(width: 400, height: 500)
    }
    
    private var todaysTasks: [Task] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return tasks.filter { $0.createdAt >= today && !$0.isCompleted }
    }
}

struct InterruptionReasonView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var interruptionReason: String
    let onSubmit: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("End Session")
                .font(.headline)
            
            Text("Was this session interrupted?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            TextField("Reason (optional)", text: $interruptionReason, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...5)
            
            HStack {
                Button("No Interruption") {
                    interruptionReason = ""
                    onSubmit()
                }
                .buttonStyle(.bordered)
                
                Button("End Session") {
                    onSubmit()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 350)
    }
}
