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
    @State private var showingInterruptionDialog = false
    @State private var showingHistory = false
    @State private var interruptionReason = ""
    
    // Timer to update duration display
    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
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
            
            // Today's Metrics
            metricsSection
            
            Divider()
            
            // Quick Actions
            actionsSection
        }
        .padding()
        .frame(width: 360)
        .sheet(isPresented: $showingInterruptionDialog) {
            InterruptionReasonView(
                interruptionReason: $interruptionReason,
                onSubmit: {
                    trackingManager.startInterruption(reason: interruptionReason.isEmpty ? nil : interruptionReason)
                    showingInterruptionDialog = false
                    interruptionReason = ""
                }
            )
        }
        .sheet(isPresented: $showingHistory) {
            HistoryView(isPresented: $showingHistory)
        }
        .onReceive(timer) { _ in
            currentTime = Date()
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
                        .fill(trackingManager.isInterrupted ? .orange : .green)
                        .frame(width: 12, height: 12)
                    
                    Text(trackingManager.isInterrupted ? "Interrupted" : "Tracking")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Text(trackingManager.isInterrupted ? "Interruption" : "Focus Session")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                if trackingManager.isInterrupted, let interruption = trackingManager.currentInterruption {
                    Text(interruption.durationFormatted)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .id("interruption-\(currentTime)") // Force redraw
                } else if let session = trackingManager.currentSession {
                    Text(session.durationFormatted)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .id("session-\(currentTime)") // Force redraw
                    
                    // Timeline Visualization
                    SessionTimelineView(session: session)
                        .padding(.top, 4)
                        .id("timeline-\(currentTime)") // Force redraw
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
        Group {
            if let metrics = trackingManager.getCurrentSessionMetrics() {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Session Progress")
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
                            value: "\(metrics.interruptionCount) (\(metrics.interruptionDurationFormatted))"
                        )
                        
                        MetricCard(
                            icon: "chart.line.uptrend.xyaxis",
                            label: "Score",
                            value: "\(Int(metrics.productivityPercentage))%"
                        )
                    }
                }
                .id("metrics-\(currentTime)") // Force redraw
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
            
            // Log Interruption / Resume Button
            if trackingManager.isTracking {
                if trackingManager.isInterrupted {
                    Button(action: { trackingManager.endInterruption() }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Resume Focus")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button(action: { showingInterruptionDialog = true }) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                            Text("Log Interruption")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                // History Button (Only when not tracking)
                Button(action: { showingHistory = true }) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("History")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                }
                .buttonStyle(.bordered)
            }
            
            // Keyboard Shortcut Hint
            Text("Press ⌥⌃Space to toggle")
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            Divider()
            
            // Quit Button
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                Text("Quit App")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
    }
    
    private func toggleSession() {
        if trackingManager.isTracking {
            // If we are tracking, we just stop the session.
            // If there is an active interruption, trackingManager.endSession() handles it.
            trackingManager.endSession()
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

struct InterruptionReasonView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var interruptionReason: String
    let onSubmit: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Log Interruption")
                .font(.headline)
            
            Text("What is interrupting you?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            TextField("Reason (optional)", text: $interruptionReason, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...5)
            
            HStack {
                Button("Cancel") {
                    interruptionReason = ""
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Start Interruption") {
                    onSubmit()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 350)
    }
}
