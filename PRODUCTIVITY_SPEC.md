# 📘 Productivity Tracking App — Specification

## 🧩 Overview
A macOS menu-bar application that tracks real vs. planned productivity, based on the model described in **“The Math of Why You Can’t Focus at Work”**.  
The app allows users to:

- Plan their day  
- Track focused work sessions  
- Log interruptions  
- Automatically compute productivity using a mathematical model  
- Use a global shortcut to start and stop focus sessions  
- Review daily and historical metrics  

Built using **SwiftUI**, **SwiftData**, and **KeyboardShortcuts**.

---

# 🛠️ Tech Stack

- **Language:** Swift  
- **Framework:** SwiftUI  
- **Persistence:** SwiftData (or CoreData fallback)  
- **Shortcuts:** KeyboardShortcuts library  
- **UI:** Menu Bar app + optional full window  
- **Platform:** macOS 13+  
- **Distribution:**  
  - Unsigned ZIP (free)  
  - Signed + notarized build (Apple Developer Program)  
  - Optional Mac App Store version  

---

# 🎯 Goals

### Primary Goals
- Track focused work sessions precisely  
- Measure productivity using interruption penalties  
- Simplify user actions (one button + global shortcut)  
- Provide insights, not raw data  

### Secondary Goals
- Minimal, clean UI  
- Sync data via iCloud (future)  
- Optional CSV export  

---

# 📂 Core Features

## 1. Menu Bar Application
The app primarily exists in the macOS menu bar.

**Features:**
- Toggle work session (Start/Stop)
- Show current task or “Idle”
- Quick add ad-hoc task
- Open main dashboard window

---

## 2. Task Management

Two types of tasks:

### **Planned Tasks**
Created at the beginning of the day.

- Title  
- Estimated importance (optional)  
- Associated sessions  

### **Ad-hoc Tasks**
Created automatically when a session starts without a planned task.

**Common Properties**
```swift
Task {
    id: UUID
    title: String
    createdAt: Date
    planned: Bool
}
```

---

## 3. Work Session Tracking

A session records continuous focus time.

**Session Model**
```swift
WorkSession {
    id: UUID
    taskId: UUID?   // null for ad-hoc sessions
    start: Date
    end: Date?
    interruptionReason: String?
}
```

### Behavior
- Clicking **Start** or pressing the shortcut creates a new session.  
- Clicking **Stop** ends the session and optionally prompts for reason.  
- If no task is selected, user can choose or create ad-hoc task.  

---

## 4. Global Shortcut

Uses **KeyboardShortcuts**:

### Actions:
- If idle → **Start session**
- If active → **End session + ask reason**

### Default shortcut:
`⌥ Ctrl Space` (customizable)

---

## 5. Productivity Formula

Based directly on the model in the referenced article.

### Definitions:

```
FocusedTime = sum(all session durations)
Interruptions = number of sessions that ended early / with a reason
PenaltyPerInterruption = 15 minutes
Penalty = Interruptions * PenaltyPerInterruption

Productivity = FocusedTime / (FocusedTime + Penalty)
```

### Metrics computed:

- Focused time (minutes/hours)
- Number of interruptions
- Productivity score (0 → 1)
- Productivity percentage (0% → 100%)
- Daily score
- Weekly average
- Monthly trend

---

## 6. Dashboard

Full-size window (optional), containing:

### Daily Overview
- Total focused time  
- Number of interruptions  
- Productivity percentage  
- Planned tasks completed  
- Timeline visualization  

### Historical Metrics
- Weekly summary chart  
- Monthly trends  
- Best day / worst day  
- Most interrupted task  

### Task Panel
- Planned tasks  
- Completed tasks  
- Ad-hoc tasks  
- Add/edit/delete  

---

## 7. Storage

### SwiftData model:
- `Task`
- `WorkSession`
- `Settings` (shortcut, preferences)
- `DayPlan` (optional grouping for daily summaries)

Data stored locally in app container.

---

## 8. App Distribution

### Free Distribution (Unsigned)
- Users must use “Right-click → Open”
- No developer license required

### Signed + Notarized (Recommended)
- Developer ID certificate required
- No warnings for users

### Mac App Store Version (Optional)
- Requires Apple Developer Program
- Uses Sandbox
- Minor entitlement adjustments required

---

# 📦 App Structure

```
/Sources
  /Models
  /ViewModels
  /Views
    MenuBarView.swift
    DashboardView.swift
    TaskListView.swift
  /Services
    TrackingManager.swift
    ProductivityCalculator.swift
    ShortcutManager.swift
  /Persistence
    SwiftDataSchema.swift
  /App
    FocusApp.swift
```

---

# 🪜 Development Steps

1. **Project setup**  
2. **Models**  
3. **TrackingManager**  
4. **Global Shortcut**  
5. **Menu bar UI**  
6. **Dashboard**  
7. **Charts**  
8. **Persistence**  
9. **Distribution setup**  

---

# 🚀 Future Enhancements

- Pomodoro mode  
- Calendar integration  
- Notifications  
- iCloud sync  
- Time-boxing planning  
- AI task summaries  
