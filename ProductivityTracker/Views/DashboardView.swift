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
    @Query(sort: \Task.createdAt, order: .reverse) private var allTasks: [Task]
    
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
            
            TasksTab(trackingManager: trackingManager)
                .tabItem {
                    Label("Tasks", systemImage: "list.bullet")
                }
                .tag(1)
            
            HistoryTab(sessions: allSessions)
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .tag(2)
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
                        if let task = trackingManager.currentTask {
                            Text(task.title)
                                .font(.headline)
                        } else {
                            Text("Ad-hoc Session")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                        
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

// MARK: - Tasks Tab

struct TasksTab: View {
    @State var trackingManager: TrackingManager
    @State private var showingNewTaskSheet = false
    @Query(sort: \Task.createdAt, order: .reverse) private var tasks: [Task]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Tasks")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: { showingNewTaskSheet = true }) {
                    Label("New Task", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            List {
                Section("Today") {
                    ForEach(todaysTasks) { task in
                        TaskRowView(task: task, trackingManager: trackingManager)
                    }
                }
                
                Section("Earlier") {
                    ForEach(olderTasks) { task in
                        TaskRowView(task: task, trackingManager: trackingManager)
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewTaskSheet) {
            NewTaskSheet(trackingManager: trackingManager)
        }
    }
    
    private var todaysTasks: [Task] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return tasks.filter { $0.createdAt >= today }
    }
    
    private var olderTasks: [Task] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return tasks.filter { $0.createdAt < today }
    }
}

struct TaskRowView: View {
    let task: Task
    let trackingManager: TrackingManager
    
    var body: some View {
        HStack {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(task.isCompleted ? .green : .secondary)
            
            VStack(alignment: .leading) {
                Text(task.title)
                    .font(.headline)
                
                HStack {
                    if task.isPlanned {
                        Label("Planned", systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                    
                    if task.totalFocusedTime > 0 {
                        Label("\(Int(task.totalFocusedTime / 60))m", systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if !task.isCompleted {
                Button(action: { trackingManager.startSession(for: task) }) {
                    Image(systemName: "play.fill")
                }
                .buttonStyle(.borderless)
            }
        }
    }
}

struct NewTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    let trackingManager: TrackingManager
    
    @State private var title = ""
    @State private var isPlanned = true
    @State private var importance: Int?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("New Task")
                .font(.headline)
            
            TextField("Task title", text: $title)
                .textFieldStyle(.roundedBorder)
            
            Toggle("Planned Task", isOn: $isPlanned)
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Create") {
                    if isPlanned {
                        _ = trackingManager.createPlannedTask(title: title, importance: importance)
                    } else {
                        _ = trackingManager.createAdHocTask(title: title)
                    }
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
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
                if let task = session.task {
                    Text(task.title)
                        .font(.headline)
                } else {
                    Text("Ad-hoc Session")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                
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
