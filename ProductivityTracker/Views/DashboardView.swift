//
//  DashboardView.swift
//  ProductivityTracker
//
//  Created on 10 December 2025.
//

import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var trackingManager: TrackingManager
    @State private var selectedTab = 0
    
    @Query(sort: \WorkSession.startTime, order: .reverse) private var allSessions: [WorkSession]
    
    init(trackingManager: TrackingManager) {
        _trackingManager = State(initialValue: trackingManager)
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            OverviewTab(trackingManager: trackingManager)
                .tabItem {
                    Label("Overview", systemImage: "chart.bar.fill")
                }
                .tag(0)
            
            HistoryTab(sessions: allSessions)
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .tag(1)
        }
        .frame(minWidth: 900, minHeight: 600)
    }
}

// MARK: - Overview Tab

struct OverviewTab: View {
    @State var trackingManager: TrackingManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Today's Summary
                todaySummarySection
                
                // Weekly Chart
                weeklyChartSection
                
                // Current Session
                if trackingManager.isTracking {
                    currentSessionSection
                }
            }
            .padding()
        }
    }
    
    private var todaySummarySection: some View {
        let metrics = trackingManager.getTodaysMetrics()
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("Today's Performance")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: 16) {
                SummaryCard(
                    icon: "clock.fill",
                    label: "Focused Time",
                    value: metrics.focusedTimeFormatted,
                    color: .blue
                )
                
                SummaryCard(
                    icon: "exclamationmark.triangle.fill",
                    label: "Interruptions",
                    value: "\(metrics.interruptionCount)",
                    color: .orange
                )
                
                SummaryCard(
                    icon: "chart.line.uptrend.xyaxis",
                    label: "Productivity",
                    value: "\(Int(metrics.productivityPercentage))%",
                    color: .green
                )
                
                SummaryCard(
                    icon: "medal.fill",
                    label: "Grade",
                    value: metrics.grade,
                    color: .purple
                )
            }
        }
    }
    
    private var weeklyChartSection: some View {
        let weekData = getWeeklyData()
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("Last 7 Days")
                .font(.title2)
                .fontWeight(.bold)
            
            Chart(weekData) { item in
                BarMark(
                    x: .value("Day", item.day),
                    y: .value("Productivity", item.productivity)
                )
                .foregroundStyle(.blue.gradient)
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let intValue = value.as(Double.self) {
                            Text("\(Int(intValue))%")
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var currentSessionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Session")
                .font(.title2)
                .fontWeight(.bold)
            
            if let session = trackingManager.currentSession {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Focus Session")
                            .font(.headline)
                        
                        Text("Duration: \(session.durationFormatted)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Circle()
                        .fill(.green)
                        .frame(width: 16, height: 16)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private func getWeeklyData() -> [DayProductivity] {
        let calendar = Calendar.current
        let today = Date()
        let sessions = trackingManager.fetchAllSessions()
        
        var weekData: [DayProductivity] = []
        
        for dayOffset in (0..<7).reversed() {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                let daySessions = sessions.filter { session in
                    calendar.isDate(session.startTime, inSameDayAs: date)
                }
                
                let metrics = ProductivityCalculator.calculate(sessions: daySessions)
                let dayName = calendar.shortWeekdaySymbols[calendar.component(.weekday, from: date) - 1]
                
                weekData.append(DayProductivity(
                    day: dayName,
                    productivity: metrics.productivityPercentage
                ))
            }
        }
        
        return weekData
    }
}

struct DayProductivity: Identifiable {
    let id = UUID()
    let day: String
    let productivity: Double
}

struct SummaryCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - History Tab

struct HistoryTab: View {
    let sessions: [WorkSession]
    
    var body: some View {
        List {
            ForEach(groupedSessions.keys.sorted(by: >), id: \.self) { date in
                Section(dateFormatter.string(from: date)) {
                    ForEach(groupedSessions[date] ?? []) { session in
                        SessionRowView(session: session)
                    }
                }
            }
        }
    }
    
    private var groupedSessions: [Date: [WorkSession]] {
        let calendar = Calendar.current
        return Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.startTime)
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}

struct SessionRowView: View {
    let session: WorkSession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Focus Session")
                    .font(.headline)
                
                Text(timeFormatter.string(from: session.startTime))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(session.durationFormatted)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                if session.wasInterrupted {
                    Label("Interrupted", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
    }
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}
