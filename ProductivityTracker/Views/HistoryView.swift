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
                        SessionHistoryRow(session: session)
                    }
                }
                .listStyle(.plain)
            }
        }
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(timeString(from: session.startTime))
                    .font(.headline)
                
                Spacer()
                
                Text(session.durationFormatted)
                    .fontWeight(.semibold)
            }
            
            HStack {
                if session.wasInterrupted {
                    Label("Interrupted", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                } else {
                    Label("Focused", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
                
                Spacer()
                
                // "Sum minutes of interaction" (Penalty)
                // Assuming 15 mins penalty per interruption as per ProductivityCalculator
                let penalty = session.wasInterrupted ? 15 : 0
                Text("\(penalty)m penalty")
                    .foregroundStyle(.secondary)
            }
            .font(.caption)
        }
        .padding(.vertical, 4)
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
