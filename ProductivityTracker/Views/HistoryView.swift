//
//  HistoryView.swift
//  ProductivityTracker
//
//  Created on 10 December 2025.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    @State private var selectedDate = Date()
    @State private var sessionToDelete: WorkSession?
    @State private var showDeleteConfirmation = false
    @State private var refreshID = UUID()
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with Back button and Date Picker
            headerSection
            
            Divider()
            
            // Sessions List
            sessionsList
        }
        .padding()
        .frame(width: 360, height: 500)
        .alert("Delete Session?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let session = sessionToDelete {
                    deleteSession(session)
                }
            }
            Button("Cancel", role: .cancel) {
                sessionToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this session? This action cannot be undone.")
        }
    }
    
    private var headerSection: some View {
        HStack {
            Button(action: { isPresented = false }) {
                Image(systemName: "chevron.left")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: { moveDate(by: -1) }) {
                    Image(systemName: "chevron.left.circle")
                }
                .buttonStyle(.plain)
                
                DatePicker(
                    "",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .labelsHidden()
                .fixedSize()
                
                Button(action: { moveDate(by: 1) }) {
                    Image(systemName: "chevron.right.circle")
                }
                .buttonStyle(.plain)
                .disabled(Calendar.current.isDateInToday(selectedDate))
            }
            
            Spacer()
            
            // Invisible spacer to balance the back button
            Image(systemName: "chevron.left")
                .font(.title3)
                .opacity(0)
        }
    }
    
    private var sessionsList: some View {
        let sessions = getSessions(for: selectedDate)
        
        return Group {
            if sessions.isEmpty {
                ContentUnavailableView(
                    "No Sessions",
                    systemImage: "clock.badge.xmark",
                    description: Text("No work sessions recorded for this date.")
                )
            } else {
                List {
                    ForEach(sessions) { session in
                        SessionHistoryRow(session: session, onDelete: {
                            sessionToDelete = session
                            showDeleteConfirmation = true
                        })
                    }
                }
                .listStyle(.plain)
                .id(refreshID) // Force refresh when ID changes
            }
        }
    }
    
    private func deleteSession(_ session: WorkSession) {
        modelContext.delete(session)
        try? modelContext.save()
        refreshID = UUID() // Trigger refresh
        sessionToDelete = nil
    }
    
    private func moveDate(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    private func getSessions(for date: Date) -> [WorkSession] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let descriptor = FetchDescriptor<WorkSession>(
            predicate: #Predicate { session in
                session.startTime >= startOfDay && session.startTime < endOfDay
            },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        
        return (try? modelContext.fetch(descriptor)) ?? []
    }
}

struct SessionHistoryRow: View {
    let session: WorkSession
    let onDelete: () -> Void
    @State private var isExpanded = false
    
    private var metrics: (rawFocus: TimeInterval, adjustedFocus: TimeInterval, actualInterruption: TimeInterval, totalInterruption: TimeInterval, percentage: Double) {
        let totalDuration = session.duration
        let interruptionDuration = session.interruptions.reduce(0) { $0 + $1.duration }
        let rawFocusedTime = totalDuration - interruptionDuration
        
        // Recovery time penalty per interruption
        let penaltySeconds = Double(session.interruptions.count) * Double(ProductivityCalculator.recoveryTimeMinutes) * 60
        let adjustedFocus = max(0, rawFocusedTime - penaltySeconds)
        
        let percentage = rawFocusedTime > 0 ? adjustedFocus / rawFocusedTime : 0
        
        return (rawFocusedTime, adjustedFocus, interruptionDuration, interruptionDuration + penaltySeconds, percentage)
    }
    
    private var status: (title: String, color: Color) {
        let p = metrics.percentage
        if p > 0.8 {
            return ("Focused", .green)
        } else if p > 0.5 {
            return ("Moderately Focused", .orange)
        } else {
            return ("Highly Interrupted", .red)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                // Left Side: Time and Status
                VStack(alignment: .leading, spacing: 4) {
                    Text(timeString(from: session.startTime))
                        .font(.headline)
                    
                    Text(session.durationFormatted)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text(status.title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(status.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(status.color.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Spacer()
                
                // Right Side: Metrics
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Focused: \(formatDuration(metrics.rawFocus))")
                        .font(.caption)
                        .foregroundStyle(.green)
                    
                    Text("Interruption: \(formatDuration(metrics.actualInterruption))")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                
                // Expand Button
                HStack(spacing: 4) {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { withAnimation { isExpanded.toggle() } }) {
                        Image(systemName: "chevron.right")
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.leading, 8)
            }
            
            if isExpanded {
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Timeline")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    
                    SessionTimelineView(session: session)
                    
                    HStack {
                        HistoryMetricItem(label: "Interruptions", value: "\(session.interruptions.count)")
                        Spacer()
                        HistoryMetricItem(label: "Context Loss", value: "\(session.interruptions.count * ProductivityCalculator.recoveryTimeMinutes)m")
                        Spacer()
                        HistoryMetricItem(label: "Score", value: "\(Int(metrics.percentage * 100))%")
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        return "\(minutes)m"
    }
}

struct HistoryMetricItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
}
